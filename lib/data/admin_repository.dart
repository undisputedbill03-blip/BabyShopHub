import 'package:sqflite/sqflite.dart';

import '../core/db_utils.dart';
import '../core/statuses.dart';
import '../models/models.dart';
import 'database_helper.dart';

/// A snapshot of the shop for the admin dashboard.
///
/// One object gathered in a single pass, so the dashboard makes one call and
/// draws every tile from the result instead of firing a query per number.
class AdminStats {
  final int productCount;
  final int activeProductCount;
  final int outOfStockCount;
  final int lowStockCount;
  final int customerCount;
  final int orderCount;
  final int pendingOrderCount;
  final int openTicketCount;

  /// Money taken across orders that were not cancelled.
  final double totalRevenue;

  /// Orders placed today, for the "today" tile.
  final int ordersToday;

  const AdminStats({
    this.productCount = 0,
    this.activeProductCount = 0,
    this.outOfStockCount = 0,
    this.lowStockCount = 0,
    this.customerCount = 0,
    this.orderCount = 0,
    this.pendingOrderCount = 0,
    this.openTicketCount = 0,
    this.totalRevenue = 0,
    this.ordersToday = 0,
  });
}

/// A row on the admin "sales by status" panel.
class StatusCount {
  final String status;
  final int count;

  const StatusCount(this.status, this.count);
}

/// All the shop's write operations that belong to an administrator:
/// managing the catalogue, the categories, the sellers and the user list.
///
/// Reads that a customer also needs live in [CatalogRepository]. The split is
/// by who is allowed to call it, so an accidental write can only come from a
/// screen that deliberately reached for the admin repository.
class AdminRepository {
  AdminRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  // -------------------------------------------------------- dashboard

  Future<AdminStats> stats() async {
    final Database db = await _db;

    final int productCount =
        firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products')) ?? 0;
    final int activeProductCount = firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM products WHERE is_active = 1')) ??
        0;
    final int outOfStock = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM products WHERE is_active = 1 AND stock = 0',
        )) ??
        0;
    final int lowStock = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM products '
          'WHERE is_active = 1 AND stock > 0 AND stock <= 5',
        )) ??
        0;
    final int customerCount = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM users WHERE role = ?',
          <Object?>[UserRole.customer],
        )) ??
        0;
    final int orderCount =
        firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM orders')) ?? 0;
    final int pendingOrders = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM orders WHERE status = ?',
          <Object?>[OrderStatus.pending],
        )) ??
        0;
    final int openTickets = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM support_tickets WHERE status IN (?, ?)',
          <Object?>[TicketStatus.open, TicketStatus.inProgress],
        )) ??
        0;

    final List<Map<String, Object?>> revenueRows = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) AS revenue FROM orders WHERE status != ?',
      <Object?>[OrderStatus.cancelled],
    );
    final double revenue =
        revenueRows.isEmpty ? 0 : asDouble(revenueRows.first['revenue']);

    // "Today" is compared on the date portion of the ISO timestamp, which is
    // lexicographically sortable, so a LIKE on the yyyy-MM-dd prefix is exact.
    final String today = nowIso().substring(0, 10);
    final int ordersToday = firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM orders WHERE placed_at LIKE ?",
          <Object?>['$today%'],
        )) ??
        0;

    return AdminStats(
      productCount: productCount,
      activeProductCount: activeProductCount,
      outOfStockCount: outOfStock,
      lowStockCount: lowStock,
      customerCount: customerCount,
      orderCount: orderCount,
      pendingOrderCount: pendingOrders,
      openTicketCount: openTickets,
      totalRevenue: revenue,
      ordersToday: ordersToday,
    );
  }

  /// How many orders sit in each status, for the dashboard breakdown.
  Future<List<StatusCount>> ordersByStatus() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS n FROM orders GROUP BY status',
    );
    final Map<String, int> found = <String, int>{
      for (final Map<String, Object?> r in rows)
        asString(r['status']): asInt(r['n']),
    };
    // Returned in the canonical order so the panel always lists the statuses
    // the same way, including the ones that currently have no orders.
    return <StatusCount>[
      for (final String s in OrderStatus.all) StatusCount(s, found[s] ?? 0),
    ];
  }

  // ------------------------------------------------------------ users

  /// The user list for the admin people screen.
  ///
  /// Password hashes and salts are never selected, so they cannot leak into a
  /// list widget or a log line.
  Future<List<AppUser>> users({String query = '', String role = ''}) async {
    final Database db = await _db;
    final List<String> where = <String>[];
    final List<Object?> args = <Object?>[];

    if (role.isNotEmpty) {
      where.add('role = ?');
      args.add(role);
    }
    final String term = query.trim();
    if (term.isNotEmpty) {
      where.add('(name LIKE ? OR email LIKE ?)');
      final String pattern = '%$term%';
      args..add(pattern)..add(pattern);
    }

    final String filter = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT id, name, email, phone, role, is_active, created_at, '
      "'' AS password_hash, '' AS password_salt "
      'FROM users $filter ORDER BY id ASC',
      args,
    );
    return rows.map(AppUser.fromMap).toList();
  }

  /// Suspends or restores an account.
  ///
  /// The shop must always keep at least one working administrator, so the
  /// last active admin cannot lock themselves out.
  Future<String?> setUserActive({
    required int userId,
    required bool active,
  }) async {
    final Database db = await _db;
    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'users',
        columns: <String>['role', 'is_active'],
        where: 'id = ?',
        whereArgs: <Object?>[userId],
        limit: 1,
      );
      if (rows.isEmpty) return 'That account no longer exists.';

      final bool isAdmin = asString(rows.first['role']) == UserRole.admin;
      if (!active && isAdmin) {
        final int otherAdmins = firstIntValue(await txn.rawQuery(
              'SELECT COUNT(*) FROM users '
              'WHERE role = ? AND is_active = 1 AND id != ?',
              <Object?>[UserRole.admin, userId],
            )) ??
            0;
        if (otherAdmins == 0) {
          return 'This is the only active administrator and cannot be '
              'suspended.';
        }
      }

      await txn.update(
        'users',
        <String, Object?>{'is_active': boolToInt(active)},
        where: 'id = ?',
        whereArgs: <Object?>[userId],
      );
      return null;
    });
  }

  // --------------------------------------------------------- products

  /// Creates a product. Returns the new row id.
  ///
  /// Rating totals always start at zero — a brand new listing has earned no
  /// stars — regardless of anything on the passed-in object.
  Future<int> createProduct(Product product) async {
    final Database db = await _db;
    final Map<String, Object?> values = product.toMap()
      ..remove('id')
      ..['rating_sum'] = 0
      ..['rating_count'] = 0
      ..['created_at'] = nowIso();
    return db.insert('products', values);
  }

  /// Updates an existing product.
  ///
  /// `rating_sum`, `rating_count` and `created_at` are stripped so an edit
  /// through the admin form can never overwrite the earned rating or rewrite
  /// history; those columns are owned by the review flow and the insert.
  Future<String?> updateProduct(Product product) async {
    if (product.id == null) return 'This product has not been saved yet.';
    final Database db = await _db;
    final Map<String, Object?> values = product.toMap()
      ..remove('id')
      ..remove('rating_sum')
      ..remove('rating_count')
      ..remove('created_at');
    final int changed = await db.update(
      'products',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[product.id],
    );
    return changed == 0 ? 'That product no longer exists.' : null;
  }

  /// Adjusts stock by a delta, never below zero.
  Future<String?> adjustStock({required int productId, required int delta}) async {
    final Database db = await _db;
    final int changed = await db.rawUpdate(
      'UPDATE products SET stock = MAX(0, stock + ?) WHERE id = ?',
      <Object?>[delta, productId],
    );
    return changed == 0 ? 'That product no longer exists.' : null;
  }

  /// Hides or restores a product.
  ///
  /// Listings are deactivated rather than deleted, because an order's history
  /// and a customer's basket may still point at them. A hidden product drops
  /// out of the shop but its records stay intact.
  Future<String?> setProductActive({
    required int productId,
    required bool active,
  }) async {
    final Database db = await _db;
    final int changed = await db.update(
      'products',
      <String, Object?>{'is_active': boolToInt(active)},
      where: 'id = ?',
      whereArgs: <Object?>[productId],
    );
    return changed == 0 ? 'That product no longer exists.' : null;
  }

  // ------------------------------------------------------- categories

  /// Adds a category. Names are unique, so a clash is reported rather than
  /// throwing a raw SQLite constraint error at the screen.
  Future<String?> createCategory(ProductCategory category) async {
    final Database db = await _db;
    final String name = category.name.trim();
    if (name.isEmpty) return 'Please give the category a name.';

    final int clashes = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM categories WHERE name = ? COLLATE NOCASE',
          <Object?>[name],
        )) ??
        0;
    if (clashes > 0) return 'A category called "$name" already exists.';

    await db.insert('categories', category.toMap()..remove('id'));
    return null;
  }

  Future<String?> updateCategory(ProductCategory category) async {
    if (category.id == null) return 'This category has not been saved yet.';
    final Database db = await _db;
    final String name = category.name.trim();
    if (name.isEmpty) return 'Please give the category a name.';

    final int clashes = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM categories '
          'WHERE name = ? COLLATE NOCASE AND id != ?',
          <Object?>[name, category.id],
        )) ??
        0;
    if (clashes > 0) return 'A category called "$name" already exists.';

    final int changed = await db.update(
      'categories',
      category.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[category.id],
    );
    return changed == 0 ? 'That category no longer exists.' : null;
  }

  /// Deletes a category, but only when nothing depends on it.
  ///
  /// A category with products still attached cannot be removed, because the
  /// products carry a NOT NULL category_id — pointing them nowhere would
  /// break the catalogue. The admin is told to move or hide the products
  /// first.
  Future<String?> deleteCategory(int categoryId) async {
    final Database db = await _db;
    final int inUse = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM products WHERE category_id = ?',
          <Object?>[categoryId],
        )) ??
        0;
    if (inUse > 0) {
      return 'This category still has $inUse product(s). Move or remove them '
          'before deleting it.';
    }
    final int changed = await db
        .delete('categories', where: 'id = ?', whereArgs: <Object?>[categoryId]);
    return changed == 0 ? 'That category no longer exists.' : null;
  }

  // ---------------------------------------------------------- sellers

  /// Adds a seller. Used by the product form so a listing can name a vendor
  /// that does not exist yet.
  Future<String?> createSeller(Seller seller) async {
    final Database db = await _db;
    final String name = seller.name.trim();
    if (name.isEmpty) return 'Please give the seller a name.';

    final int clashes = firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM sellers WHERE name = ? COLLATE NOCASE',
          <Object?>[name],
        )) ??
        0;
    if (clashes > 0) return 'A seller called "$name" already exists.';

    await db.insert('sellers', seller.toMap()..remove('id'));
    return null;
  }

  Future<String?> updateSeller(Seller seller) async {
    if (seller.id == null) return 'This seller has not been saved yet.';
    final Database db = await _db;
    final int changed = await db.update(
      'sellers',
      <String, Object?>{
        'name': seller.name.trim(),
        'description': seller.description.trim(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[seller.id],
    );
    return changed == 0 ? 'That seller no longer exists.' : null;
  }
}
