import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'database_helper.dart';

/// The cheapest and dearest price in the live catalogue.
///
/// A small named class rather than a record, so the meaning of each value is
/// visible at the call site and the type works on every Dart 3 release.
class PriceBounds {
  final double min;
  final double max;

  const PriceBounds(this.min, this.max);
}

/// Reads the shop: categories, sellers, and every product query behind
/// browsing, searching and filtering.
///
/// Nothing here writes. Product edits belong to [AdminRepository], so there
/// is exactly one place to look when a catalogue write misbehaves.
class CatalogRepository {
  CatalogRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  /// Columns every product query selects.
  ///
  /// `p.*` must come before the joined aliases so the bare `id`, `name` and
  /// `rating_count` keys belong to the product and not to the category or
  /// the seller, both of which have columns by those names.
  static const String _productColumns =
      'p.*, c.name AS category_name, s.name AS seller_name';

  static const String _productJoins =
      'FROM products p '
      'JOIN categories c ON c.id = p.category_id '
      'JOIN sellers s ON s.id = p.seller_id';

  // --------------------------------------------------------- categories

  /// Every category with a live product count attached.
  ///
  /// The count comes from a correlated subquery rather than a GROUP BY so a
  /// category with no products still appears, showing zero.
  Future<List<ProductCategory>> categories(
      {bool onlyWithProducts = false}) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT c.*,
             (SELECT COUNT(*) FROM products p
              WHERE p.category_id = c.id AND p.is_active = 1) AS product_count
      FROM categories c
      ORDER BY c.sort_order ASC, c.name COLLATE NOCASE ASC
    ''');
    final List<ProductCategory> all = rows.map(ProductCategory.fromMap).toList();
    if (!onlyWithProducts) return all;
    return all
        .where((ProductCategory c) => c.productCount > 0)
        .toList(growable: false);
  }

  Future<ProductCategory?> categoryById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
      SELECT c.*,
             (SELECT COUNT(*) FROM products p
              WHERE p.category_id = c.id AND p.is_active = 1) AS product_count
      FROM categories c
      WHERE c.id = ?
    ''', <Object?>[id]);
    if (rows.isEmpty) return null;
    return ProductCategory.fromMap(rows.first);
  }

  // ------------------------------------------------------------ sellers

  Future<List<Seller>> sellers() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows =
        await db.query('sellers', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Seller.fromMap).toList();
  }

  Future<Seller?> sellerById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'sellers',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Seller.fromMap(rows.first);
  }

  // ----------------------------------------------------------- products

  /// The one query behind the home page, category pages and search.
  ///
  /// Every filter is optional and every value is bound as a parameter. The
  /// only text interpolated into the SQL is [ProductSort.orderByClause],
  /// which is a fixed string chosen by a switch over an enum — it can never
  /// contain anything a user typed.
  Future<List<Product>> products({
    String query = '',
    int? categoryId,
    int? sellerId,
    String brand = '',
    double? minPrice,
    double? maxPrice,
    double minRating = 0,
    bool inStockOnly = false,
    ProductSort sort = ProductSort.newest,
    bool includeInactive = false,
    int? limit,
    int offset = 0,
  }) async {
    final Database db = await _db;
    final List<String> where = <String>[];
    final List<Object?> args = <Object?>[];

    if (!includeInactive) {
      where.add('p.is_active = 1');
    }

    final String term = query.trim();
    if (term.isNotEmpty) {
      // Searching name, brand and category together is what the brief asks
      // for: one box, and the shopper does not have to know which field the
      // word they remember lives in.
      where.add('(p.name LIKE ? ESCAPE \'\\\' '
          'OR p.brand LIKE ? ESCAPE \'\\\' '
          'OR c.name LIKE ? ESCAPE \'\\\')');
      final String pattern = '%${_escapeLike(term)}%';
      args..add(pattern)..add(pattern)..add(pattern);
    }

    if (categoryId != null) {
      where.add('p.category_id = ?');
      args.add(categoryId);
    }
    if (sellerId != null) {
      where.add('p.seller_id = ?');
      args.add(sellerId);
    }
    if (brand.trim().isNotEmpty) {
      where.add('p.brand = ?');
      args.add(brand.trim());
    }
    if (minPrice != null) {
      where.add('p.price >= ?');
      args.add(minPrice);
    }
    if (maxPrice != null) {
      where.add('p.price <= ?');
      args.add(maxPrice);
    }
    if (inStockOnly) {
      where.add('p.stock > 0');
    }
    if (minRating > 0) {
      // Products with no reviews yet are excluded rather than treated as
      // zero-star, which would be unfair to a new listing.
      where.add('p.rating_count > 0 AND '
          'CAST(p.rating_sum AS REAL) / p.rating_count >= ?');
      args.add(minRating);
    }

    final String whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final String limitSql = limit == null ? '' : 'LIMIT $limit OFFSET $offset';

    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT $_productColumns $_productJoins $whereSql '
      'ORDER BY ${sort.orderByClause} $limitSql',
      args,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> productById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT $_productColumns $_productJoins WHERE p.id = ?',
      <Object?>[id],
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  /// Other products in the same category, excluding the one being viewed.
  Future<List<Product>> relatedProducts({
    required int productId,
    required int categoryId,
    int limit = 8,
  }) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT $_productColumns $_productJoins '
      'WHERE p.is_active = 1 AND p.category_id = ? AND p.id != ? '
      'ORDER BY ${ProductSort.rating.orderByClause} LIMIT ?',
      <Object?>[categoryId, productId, limit],
    );
    return rows.map(Product.fromMap).toList();
  }

  /// Best-rated products, used for the "Popular right now" row.
  Future<List<Product>> topRated({int limit = 8}) {
    return products(sort: ProductSort.rating, inStockOnly: true, limit: limit);
  }

  /// Most recently added products, used for the "New in" row.
  Future<List<Product>> newArrivals({int limit = 8}) {
    return products(sort: ProductSort.newest, limit: limit);
  }

  /// Distinct brands, for the brand filter chips.
  Future<List<String>> brands() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT DISTINCT brand FROM products "
      "WHERE is_active = 1 AND brand != '' "
      "ORDER BY brand COLLATE NOCASE ASC",
    );
    return rows
        .map((Map<String, Object?> r) => r['brand']?.toString() ?? '')
        .where((String b) => b.isNotEmpty)
        .toList();
  }

  /// The cheapest and dearest live product, so the price slider can size
  /// itself to the real catalogue instead of a hard-coded guess.
  Future<PriceBounds> priceBounds() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT MIN(price) AS lo, MAX(price) AS hi '
      'FROM products WHERE is_active = 1',
    );
    const PriceBounds fallback = PriceBounds(0, 100000);
    if (rows.isEmpty) return fallback;
    final Object? lo = rows.first['lo'];
    final Object? hi = rows.first['hi'];
    if (lo is! num || hi is! num) return fallback;
    final double low = lo.toDouble();
    final double high = hi.toDouble();
    // A catalogue where everything costs the same would give a zero-width
    // slider, so widen it rather than hand the UI an empty range.
    if (high <= low) return PriceBounds(0, low + 1000);
    return PriceBounds(low, high);
  }

  /// Escapes the LIKE wildcards so a shopper searching for "50%" gets
  /// products containing "50%" rather than everything in the shop.
  static String _escapeLike(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }
}
