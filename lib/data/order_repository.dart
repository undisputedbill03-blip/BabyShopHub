import 'package:sqflite/sqflite.dart';

import '../core/db_utils.dart';
import '../core/pricing.dart';
import '../core/statuses.dart';
import '../models/models.dart';
import 'database_helper.dart';

/// What came back from an attempt to place an order.
class PlaceOrderResult {
  final Order? order;
  final String? error;

  const PlaceOrderResult.success(Order this.order) : error = null;
  const PlaceOrderResult.failure(String this.error) : order = null;

  bool get ok => order != null;
}

/// Orders: placing them, listing them, tracking them, cancelling them and
/// moving them along from the admin panel.
class OrderRepository {
  OrderRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  /// Order numbers are the row id plus this offset, so the very first order
  /// a customer places reads BSH-100244 rather than BSH-1. It also keeps
  /// the generated codes in step with the three seeded demo orders.
  static const int _orderCodeBase = 100240;

  static const String _selectOrders = '''
    SELECT o.*, u.name AS customer_name,
           (SELECT COALESCE(SUM(oi.quantity), 0) FROM order_items oi
            WHERE oi.order_id = o.id) AS item_count
    FROM orders o
    JOIN users u ON u.id = o.user_id
  ''';

  // ------------------------------------------------------------ placing

  /// Turns the basket into an order.
  ///
  /// Everything happens in one transaction: stock is re-checked, the order
  /// and its lines are written, stock is decremented, the first tracking
  /// event is recorded and the basket is emptied. If any step fails the
  /// whole thing rolls back, so there is no state where a customer has been
  /// charged for stock that was never reserved.
  ///
  /// The shipping address, the payment label and each product's name, brand,
  /// image and price are COPIED onto the order. Editing a product tomorrow
  /// must not rewrite a receipt from today.
  Future<PlaceOrderResult> placeOrder({
    required int userId,
    required Address address,
    required String paymentLabel,
  }) async {
    final Database db = await _db;

    final Object result = await db.transaction<Object>((Transaction txn) async {
      final List<Map<String, Object?>> lines = await txn.rawQuery('''
        SELECT ci.id AS cart_id, ci.quantity AS quantity,
               p.id AS pid, p.name AS pname, p.brand AS pbrand,
               p.image_path AS pimage, p.price AS pprice,
               p.stock AS pstock, p.is_active AS pactive
        FROM cart_items ci
        JOIN products p ON p.id = ci.product_id
        WHERE ci.user_id = ?
        ORDER BY ci.id ASC
      ''', <Object?>[userId]);

      if (lines.isEmpty) {
        return 'Your basket is empty.';
      }

      // Re-check availability before taking any money. Stock can have moved
      // since the basket screen was drawn.
      for (final Map<String, Object?> line in lines) {
        final String name = asString(line['pname']);
        if (!asBool(line['pactive'])) {
          return '$name is no longer available. Please remove it from your '
              'basket.';
        }
        final int stock = asInt(line['pstock']);
        final int quantity = asInt(line['quantity']);
        if (quantity > stock) {
          return stock == 0
              ? '$name has gone out of stock.'
              : 'Only $stock of $name are left. Please reduce the quantity.';
        }
      }

      final List<double> lineTotals = <double>[];
      for (final Map<String, Object?> line in lines) {
        lineTotals.add(
          Pricing.roundMoney(asDouble(line['pprice']) * asInt(line['quantity'])),
        );
      }
      final double subtotal = Pricing.subtotalOf(lineTotals);
      final double shipping = Pricing.shippingFor(subtotal);
      final double tax = Pricing.taxFor(subtotal);
      final double total = Pricing.totalFor(subtotal);

      final String timestamp = nowIso();

      // The code is derived from the row id, which is only known after the
      // insert, so the row goes in with a provisional code and is corrected
      // immediately. Both statements are inside the transaction, so no
      // reader ever sees the provisional value.
      final int orderId = await txn.insert('orders', <String, Object?>{
        'order_code': 'PENDING-$timestamp',
        'user_id': userId,
        'ship_full_name': address.fullName,
        'ship_phone': address.phone,
        'ship_line1': address.line1,
        'ship_line2': address.line2,
        'ship_city': address.city,
        'ship_state': address.state,
        'ship_postal_code': address.postalCode,
        'payment_label': paymentLabel,
        'subtotal': subtotal,
        'shipping_fee': shipping,
        'tax': tax,
        'total': total,
        'status': OrderStatus.pending,
        'placed_at': timestamp,
        'updated_at': timestamp,
      });

      await txn.update(
        'orders',
        <String, Object?>{'order_code': 'BSH-${_orderCodeBase + orderId}'},
        where: 'id = ?',
        whereArgs: <Object?>[orderId],
      );

      final Batch batch = txn.batch();
      for (int i = 0; i < lines.length; i++) {
        final Map<String, Object?> line = lines[i];
        final int productId = asInt(line['pid']);
        final int quantity = asInt(line['quantity']);

        batch.insert('order_items', <String, Object?>{
          'order_id': orderId,
          'product_id': productId,
          'product_name': asString(line['pname']),
          'brand': asString(line['pbrand']),
          'image_path': asString(line['pimage']),
          'unit_price': asDouble(line['pprice']),
          'quantity': quantity,
          'line_total': lineTotals[i],
        });

        batch.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          <Object?>[quantity, productId],
        );
      }

      batch.insert('order_events', <String, Object?>{
        'order_id': orderId,
        'status': OrderStatus.pending,
        'note': OrderStatus.note(OrderStatus.pending),
        'created_at': timestamp,
      });

      batch.delete('cart_items', where: 'user_id = ?', whereArgs: <Object?>[userId]);

      await batch.commit(noResult: true);
      return orderId;
    });

    if (result is String) {
      return PlaceOrderResult.failure(result);
    }

    final Order? placed = await byId(result as int);
    if (placed == null) {
      return const PlaceOrderResult.failure(
          'The order was saved but could not be read back.');
    }
    return PlaceOrderResult.success(placed);
  }

  // ------------------------------------------------------------ reading

  /// A customer's order history, newest first.
  Future<List<Order>> listForUser(int userId, {String status = ''}) async {
    final Database db = await _db;
    final List<Object?> args = <Object?>[userId];
    String filter = 'WHERE o.user_id = ?';
    if (status.isNotEmpty) {
      filter = '$filter AND o.status = ?';
      args.add(status);
    }
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_selectOrders $filter ORDER BY o.id DESC',
      args,
    );
    return rows.map(Order.fromMap).toList();
  }

  /// Every order in the shop, for the admin order screen.
  Future<List<Order>> listAll({String status = '', String query = ''}) async {
    final Database db = await _db;
    final List<String> where = <String>[];
    final List<Object?> args = <Object?>[];

    if (status.isNotEmpty) {
      where.add('o.status = ?');
      args.add(status);
    }
    final String term = query.trim();
    if (term.isNotEmpty) {
      where.add('(o.order_code LIKE ? OR u.name LIKE ? OR u.email LIKE ?)');
      final String pattern = '%$term%';
      args..add(pattern)..add(pattern)..add(pattern);
    }

    final String filter = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_selectOrders $filter ORDER BY o.id DESC',
      args,
    );
    return rows.map(Order.fromMap).toList();
  }

  /// One order with its lines and its full tracking history attached.
  Future<Order?> byId(int orderId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_selectOrders WHERE o.id = ?',
      <Object?>[orderId],
    );
    if (rows.isEmpty) return null;

    final List<Map<String, Object?>> itemRows = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: <Object?>[orderId],
      orderBy: 'id ASC',
    );
    final List<Map<String, Object?>> eventRows = await db.query(
      'order_events',
      where: 'order_id = ?',
      whereArgs: <Object?>[orderId],
      orderBy: 'id ASC',
    );

    return Order.fromMap(rows.first).copyWith(
      items: itemRows.map(OrderItem.fromMap).toList(),
      events: eventRows.map(OrderEvent.fromMap).toList(),
    );
  }

  /// Order lines only — used by the history list to show thumbnails without
  /// loading the tracking history for every row.
  Future<List<OrderItem>> itemsFor(int orderId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: <Object?>[orderId],
      orderBy: 'id ASC',
    );
    return rows.map(OrderItem.fromMap).toList();
  }

  /// True when this customer has a delivered order containing the product,
  /// which is the condition for being allowed to review it.
  Future<bool> hasPurchased({
    required int userId,
    required int productId,
  }) async {
    final Database db = await _db;
    final int count = firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          WHERE o.user_id = ? AND oi.product_id = ? AND o.status = ?
        ''', <Object?>[userId, productId, OrderStatus.delivered])) ??
        0;
    return count > 0;
  }

  /// The sellers a customer has actually bought from, so seller ratings are
  /// limited to people who have dealt with them.
  Future<bool> hasPurchasedFromSeller({
    required int userId,
    required int sellerId,
  }) async {
    final Database db = await _db;
    final int count = firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
          JOIN products p ON p.id = oi.product_id
          WHERE o.user_id = ? AND p.seller_id = ? AND o.status = ?
        ''', <Object?>[userId, sellerId, OrderStatus.delivered])) ??
        0;
    return count > 0;
  }

  // ------------------------------------------------------------ writing

  /// Moves an order to its next status and writes a tracking event.
  ///
  /// [OrderStatus.nextOptions] decides what is allowed, so the rule lives in
  /// exactly one place and the admin screen and this method cannot disagree.
  Future<String?> advanceStatus({
    required int orderId,
    required String newStatus,
    String note = '',
  }) async {
    final Database db = await _db;
    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'orders',
        columns: <String>['status'],
        where: 'id = ?',
        whereArgs: <Object?>[orderId],
        limit: 1,
      );
      if (rows.isEmpty) return 'That order no longer exists.';

      final String current = asString(rows.first['status']);
      if (!OrderStatus.nextOptions(current).contains(newStatus)) {
        return 'An order that is $current cannot be moved to $newStatus.';
      }

      if (newStatus == OrderStatus.cancelled) {
        await _returnStockToShelf(txn, orderId);
      }

      final String timestamp = nowIso();
      await txn.update(
        'orders',
        <String, Object?>{'status': newStatus, 'updated_at': timestamp},
        where: 'id = ?',
        whereArgs: <Object?>[orderId],
      );
      await txn.insert('order_events', <String, Object?>{
        'order_id': orderId,
        'status': newStatus,
        'note': note.trim().isEmpty ? OrderStatus.note(newStatus) : note.trim(),
        'created_at': timestamp,
      });
      return null;
    });
  }

  /// A customer cancelling their own order.
  ///
  /// The user id is checked here, not by the caller, so a stale order id
  /// from a previous session cannot cancel somebody else's parcel.
  Future<String?> cancelForCustomer({
    required int userId,
    required int orderId,
  }) async {
    final Database db = await _db;
    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'orders',
        columns: <String>['status'],
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[orderId, userId],
        limit: 1,
      );
      if (rows.isEmpty) return 'That order was not found.';

      final String current = asString(rows.first['status']);
      if (!OrderStatus.nextOptions(current).contains(OrderStatus.cancelled)) {
        return current == OrderStatus.cancelled
            ? 'That order is already cancelled.'
            : 'This order has already been $current and can no longer be '
                'cancelled. Please contact support.';
      }

      await _returnStockToShelf(txn, orderId);

      final String timestamp = nowIso();
      await txn.update(
        'orders',
        <String, Object?>{
          'status': OrderStatus.cancelled,
          'updated_at': timestamp,
        },
        where: 'id = ?',
        whereArgs: <Object?>[orderId],
      );
      await txn.insert('order_events', <String, Object?>{
        'order_id': orderId,
        'status': OrderStatus.cancelled,
        'note': 'Cancelled by the customer. Stock returned.',
        'created_at': timestamp,
      });
      return null;
    });
  }

  /// Puts a cancelled order's items back on the shelf.
  ///
  /// The join is against `products`, and a product an admin has deleted
  /// simply matches nothing — `order_items` deliberately carries no foreign
  /// key to products, so order history survives a deleted listing.
  static Future<void> _returnStockToShelf(
      Transaction txn, int orderId) async {
    await txn.rawUpdate('''
      UPDATE products SET stock = stock + COALESCE((
        SELECT SUM(oi.quantity) FROM order_items oi
        WHERE oi.order_id = ? AND oi.product_id = products.id
      ), 0)
      WHERE id IN (SELECT oi.product_id FROM order_items oi
                   WHERE oi.order_id = ?)
    ''', <Object?>[orderId, orderId]);
  }
}
