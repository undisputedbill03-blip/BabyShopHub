import 'package:sqflite/sqflite.dart';

import '../core/db_utils.dart';
import '../models/models.dart';
import 'database_helper.dart';

/// The shopping basket.
///
/// Write methods return `null` on success and a message to show the shopper
/// when the write was refused — the same convention the form validators in
/// `core/validators.dart` use, so screens handle both the same way.
class CartRepository {
  CartRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  /// The cart's own row id is aliased to `cart_id`.
  ///
  /// `p.*` puts a `id` key in the result that belongs to the PRODUCT, so
  /// `CartItem.fromMap` reads `cart_id` for the line's own id. Change one
  /// of these two and quantity updates start editing the wrong row.
  static const String _selectCart = '''
    SELECT ci.id AS cart_id, ci.user_id, ci.product_id, ci.quantity,
           ci.added_at, p.*, c.name AS category_name, s.name AS seller_name
    FROM cart_items ci
    JOIN products p ON p.id = ci.product_id
    JOIN categories c ON c.id = p.category_id
    JOIN sellers s ON s.id = p.seller_id
  ''';

  /// Every line in the shopper's basket, oldest first.
  Future<List<CartItem>> itemsFor(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_selectCart WHERE ci.user_id = ? ORDER BY ci.id ASC',
      <Object?>[userId],
    );
    return rows.map(CartItem.fromMap).toList();
  }

  /// Total number of units in the basket, for the badge on the cart icon.
  Future<int> unitCount(int userId) async {
    final Database db = await _db;
    return firstIntValue(await db.rawQuery(
          'SELECT COALESCE(SUM(quantity), 0) FROM cart_items WHERE user_id = ?',
          <Object?>[userId],
        )) ??
        0;
  }

  Future<int> quantityOf({required int userId, required int productId}) async {
    final Database db = await _db;
    return firstIntValue(await db.rawQuery(
          'SELECT COALESCE(SUM(quantity), 0) FROM cart_items '
          'WHERE user_id = ? AND product_id = ?',
          <Object?>[userId, productId],
        )) ??
        0;
  }

  /// Adds to the basket, or increases the line that is already there.
  ///
  /// The whole thing runs in one transaction because it reads the stock
  /// level and the existing quantity before deciding what to write.
  Future<String?> add({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    if (quantity < 1) return 'Choose at least one item.';
    final Database db = await _db;

    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> productRows = await txn.query(
        'products',
        columns: <String>['stock', 'is_active', 'name'],
        where: 'id = ?',
        whereArgs: <Object?>[productId],
        limit: 1,
      );
      if (productRows.isEmpty) {
        return 'That product is no longer available.';
      }
      final int stock = asInt(productRows.first['stock']);
      final bool active = asBool(productRows.first['is_active']);
      if (!active) return 'That product is no longer available.';
      if (stock <= 0) return 'That product is out of stock.';

      final List<Map<String, Object?>> existing = await txn.query(
        'cart_items',
        columns: <String>['id', 'quantity'],
        where: 'user_id = ? AND product_id = ?',
        whereArgs: <Object?>[userId, productId],
        limit: 1,
      );

      final int current = existing.isEmpty ? 0 : asInt(existing.first['quantity']);
      final int wanted = current + quantity;
      if (wanted > stock) {
        return current == 0
            ? 'Only $stock left in stock.'
            : 'You already have $current in your basket and only '
                '$stock are in stock.';
      }

      if (existing.isEmpty) {
        await txn.insert('cart_items', <String, Object?>{
          'user_id': userId,
          'product_id': productId,
          'quantity': wanted,
          'added_at': nowIso(),
        });
      } else {
        await txn.update(
          'cart_items',
          <String, Object?>{'quantity': wanted},
          where: 'id = ?',
          whereArgs: <Object?>[asInt(existing.first['id'])],
        );
      }
      return null;
    });
  }

  /// Sets an exact quantity. Passing zero removes the line, which is what
  /// tapping the minus button on a single unit should do.
  Future<String?> setQuantity({
    required int userId,
    required int cartItemId,
    required int quantity,
  }) async {
    final Database db = await _db;

    if (quantity <= 0) {
      await remove(userId: userId, cartItemId: cartItemId);
      return null;
    }

    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.rawQuery('''
        SELECT p.stock AS stock, p.is_active AS is_active
        FROM cart_items ci
        JOIN products p ON p.id = ci.product_id
        WHERE ci.id = ? AND ci.user_id = ?
      ''', <Object?>[cartItemId, userId]);
      if (rows.isEmpty) return 'That basket line no longer exists.';

      if (!asBool(rows.first['is_active'])) {
        return 'That product is no longer available.';
      }
      final int stock = asInt(rows.first['stock']);
      if (quantity > stock) return 'Only $stock left in stock.';

      await txn.update(
        'cart_items',
        <String, Object?>{'quantity': quantity},
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[cartItemId, userId],
      );
      return null;
    });
  }

  /// Deletes one line. The user id is part of the WHERE clause so a stale
  /// id from another account can never delete someone else's basket line.
  Future<void> remove({
    required int userId,
    required int cartItemId,
  }) async {
    final Database db = await _db;
    await db.delete(
      'cart_items',
      where: 'id = ? AND user_id = ?',
      whereArgs: <Object?>[cartItemId, userId],
    );
  }

  Future<void> clear(int userId) async {
    final Database db = await _db;
    await db.delete(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
    );
  }

  /// Trims any line that has drifted above its product's stock level, which
  /// happens when an admin reduces stock while a basket is sitting idle.
  ///
  /// Returns the names of the products that were adjusted, so checkout can
  /// tell the shopper what changed instead of silently altering the total.
  Future<List<String>> reconcileWithStock(int userId) async {
    final Database db = await _db;
    return db.transaction<List<String>>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.rawQuery('''
        SELECT ci.id AS cart_id, ci.quantity AS quantity,
               p.stock AS stock, p.name AS name, p.is_active AS is_active
        FROM cart_items ci
        JOIN products p ON p.id = ci.product_id
        WHERE ci.user_id = ?
      ''', <Object?>[userId]);

      final List<String> adjusted = <String>[];
      for (final Map<String, Object?> row in rows) {
        final int cartId = asInt(row['cart_id']);
        final int quantity = asInt(row['quantity']);
        final int stock = asInt(row['stock']);
        final bool active = asBool(row['is_active']);
        final String name = asString(row['name']);

        if (!active || stock <= 0) {
          await txn.delete('cart_items', where: 'id = ?', whereArgs: <Object?>[cartId]);
          adjusted.add('$name is no longer available and was removed.');
        } else if (quantity > stock) {
          await txn.update(
            'cart_items',
            <String, Object?>{'quantity': stock},
            where: 'id = ?',
            whereArgs: <Object?>[cartId],
          );
          adjusted.add('$name was reduced to $stock, the stock now available.');
        }
      }
      return adjusted;
    });
  }
}
