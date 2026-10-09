import 'package:sqflite/sqflite.dart';

import '../core/db_utils.dart';
import '../models/models.dart';
import 'database_helper.dart';

/// Reads and writes a customer's saved products (the wishlist).
///
/// Favorites are per-user rows in the `favorites` table. Nothing is shared
/// between accounts; signing out simply stops querying — the rows stay, so the
/// list is still there on the next sign-in. Like [CatalogRepository] this is
/// the one place that knows the favorites SQL.
class FavoritesRepository {
  FavoritesRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  /// Same joined columns the catalogue uses, so a favorited row maps to a full
  /// [Product] (category and seller names included) with no extra lookups.
  static const String _productColumns =
      'p.*, c.name AS category_name, s.name AS seller_name';

  /// The product ids this user has favorited, for fast heart look-ups.
  Future<Set<int>> idsFor(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'favorites',
      columns: <String>['product_id'],
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
    );
    return rows
        .map((Map<String, Object?> r) => asInt(r['product_id']))
        .toSet();
  }

  /// The full, still-active favorited products, newest save first.
  Future<List<Product>> listFor(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT $_productColumns
      FROM favorites f
      JOIN products p ON p.id = f.product_id
      JOIN categories c ON c.id = p.category_id
      JOIN sellers s ON s.id = p.seller_id
      WHERE f.user_id = ? AND p.is_active = 1
      ORDER BY f.created_at DESC, f.id DESC
    ''', <Object?>[userId]);
    return rows.map(Product.fromMap).toList();
  }

  Future<bool> isFavorite({required int userId, required int productId}) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'favorites',
      columns: <String>['id'],
      where: 'user_id = ? AND product_id = ?',
      whereArgs: <Object?>[userId, productId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> add({required int userId, required int productId}) async {
    final Database db = await _db;
    await db.insert(
      'favorites',
      <String, Object?>{
        'user_id': userId,
        'product_id': productId,
        'created_at': nowIso(),
      },
      // A product already on the list is left as-is rather than duplicated.
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> remove({required int userId, required int productId}) async {
    final Database db = await _db;
    await db.delete(
      'favorites',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: <Object?>[userId, productId],
    );
  }

  /// Flips the state and returns whether the product is now a favorite.
  Future<bool> toggle({required int userId, required int productId}) async {
    final bool already = await isFavorite(userId: userId, productId: productId);
    if (already) {
      await remove(userId: userId, productId: productId);
      return false;
    }
    await add(userId: userId, productId: productId);
    return true;
  }
}
