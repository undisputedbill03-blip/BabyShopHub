import 'package:sqflite/sqflite.dart';

import '../core/db_utils.dart';
import '../models/models.dart';
import 'database_helper.dart';

/// Product reviews and seller ratings.
///
/// Every write here finishes by asking [DatabaseHelper] to recompute the
/// affected average from the rows themselves. Nothing keeps a running total
/// by hand, so a hidden review, an edited star or a deleted account can
/// never leave a product showing an average it did not earn.
class ReviewRepository {
  ReviewRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  // ----------------------------------------------------- product reviews

  /// Reviews shown on a product page, newest first.
  ///
  /// Hidden reviews are left out unless an admin asks for them, and the
  /// same filter is used by the rating recompute, so the stars on the page
  /// always match the reviews printed under them.
  Future<List<Review>> forProduct(
    int productId, {
    bool includeHidden = false,
  }) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'reviews',
      where: includeHidden ? 'product_id = ?' : 'product_id = ? AND is_hidden = 0',
      whereArgs: <Object?>[productId],
      orderBy: 'id DESC',
    );
    return rows.map(Review.fromMap).toList();
  }

  /// How many reviews gave each star value, for the histogram.
  Future<RatingBreakdown> breakdownFor(int productId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT rating, COUNT(*) AS n FROM reviews '
      'WHERE product_id = ? AND is_hidden = 0 GROUP BY rating',
      <Object?>[productId],
    );
    if (rows.isEmpty) return RatingBreakdown.empty();

    final Map<int, int> counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    int total = 0;
    int sum = 0;
    for (final Map<String, Object?> row in rows) {
      final int star = asInt(row['rating']);
      final int n = asInt(row['n']);
      if (star < 1 || star > 5) continue;
      counts[star] = n;
      total += n;
      sum += star * n;
    }
    if (total == 0) return RatingBreakdown.empty();
    return RatingBreakdown(
      counts: counts,
      total: total,
      average: sum / total,
    );
  }

  /// This customer's own review of a product, if they have written one.
  Future<Review?> myReview({
    required int userId,
    required int productId,
  }) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'reviews',
      where: 'product_id = ? AND user_id = ?',
      whereArgs: <Object?>[productId, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Review.fromMap(rows.first);
  }

  /// Writes a review, replacing the customer's previous one if there is one.
  ///
  /// The schema holds UNIQUE (product_id, user_id), so editing rather than
  /// inserting is the only correct behaviour — one customer, one opinion per
  /// product. Re-reviewing also clears a previous hide, since the text an
  /// admin objected to is gone.
  Future<String?> submit({
    required int productId,
    required int userId,
    required String userName,
    required int rating,
    String title = '',
    String comment = '',
  }) async {
    if (rating < 1 || rating > 5) {
      return 'Please choose between one and five stars.';
    }
    final Database db = await _db;

    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> existing = await txn.query(
        'reviews',
        columns: <String>['id'],
        where: 'product_id = ? AND user_id = ?',
        whereArgs: <Object?>[productId, userId],
        limit: 1,
      );

      final Map<String, Object?> values = <String, Object?>{
        'product_id': productId,
        'user_id': userId,
        'user_name': userName.trim().isEmpty ? 'Customer' : userName.trim(),
        'rating': rating,
        'title': title.trim(),
        'comment': comment.trim(),
        'is_hidden': 0,
        'created_at': nowIso(),
      };

      if (existing.isEmpty) {
        await txn.insert('reviews', values);
      } else {
        await txn.update(
          'reviews',
          values,
          where: 'id = ?',
          whereArgs: <Object?>[asInt(existing.first['id'])],
        );
      }

      await DatabaseHelper.recomputeProductRating(txn, productId);
      return null;
    });
  }

  /// A customer removing their own review.
  Future<void> deleteOwn({
    required int userId,
    required int productId,
  }) async {
    final Database db = await _db;
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'reviews',
        where: 'product_id = ? AND user_id = ?',
        whereArgs: <Object?>[productId, userId],
      );
      await DatabaseHelper.recomputeProductRating(txn, productId);
    });
  }

  // -------------------------------------------------------- moderation

  /// Every review in the shop with its product name attached, for the admin
  /// moderation screen.
  Future<List<Review>> allForModeration({
    String query = '',
    bool onlyHidden = false,
  }) async {
    final Database db = await _db;
    final List<String> where = <String>[];
    final List<Object?> args = <Object?>[];

    if (onlyHidden) {
      where.add('r.is_hidden = 1');
    }
    final String term = query.trim();
    if (term.isNotEmpty) {
      where.add('(p.name LIKE ? OR r.user_name LIKE ? OR r.comment LIKE ?)');
      final String pattern = '%$term%';
      args..add(pattern)..add(pattern)..add(pattern);
    }

    final String filter = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT r.*, p.name AS product_name FROM reviews r '
      'JOIN products p ON p.id = r.product_id '
      '$filter ORDER BY r.id DESC',
      args,
    );
    return rows.map(Review.fromMap).toList();
  }

  /// Hides or restores a review.
  ///
  /// Hiding keeps the row, so the decision can be reversed and the record
  /// of what was said is not destroyed. The product average is recomputed
  /// either way, because a hidden review must stop counting immediately.
  Future<String?> setHidden({
    required int reviewId,
    required bool hidden,
  }) async {
    final Database db = await _db;
    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'reviews',
        columns: <String>['product_id'],
        where: 'id = ?',
        whereArgs: <Object?>[reviewId],
        limit: 1,
      );
      if (rows.isEmpty) return 'That review no longer exists.';

      await txn.update(
        'reviews',
        <String, Object?>{'is_hidden': boolToInt(hidden)},
        where: 'id = ?',
        whereArgs: <Object?>[reviewId],
      );
      await DatabaseHelper.recomputeProductRating(
          txn, asInt(rows.first['product_id']));
      return null;
    });
  }

  /// Permanently removes a review from the admin screen.
  Future<String?> deleteAsAdmin(int reviewId) async {
    final Database db = await _db;
    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'reviews',
        columns: <String>['product_id'],
        where: 'id = ?',
        whereArgs: <Object?>[reviewId],
        limit: 1,
      );
      if (rows.isEmpty) return 'That review no longer exists.';

      await txn.delete('reviews', where: 'id = ?', whereArgs: <Object?>[reviewId]);
      await DatabaseHelper.recomputeProductRating(
          txn, asInt(rows.first['product_id']));
      return null;
    });
  }

  // ----------------------------------------------------- seller ratings

  Future<List<SellerRating>> forSeller(int sellerId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'seller_ratings',
      where: 'seller_id = ?',
      whereArgs: <Object?>[sellerId],
      orderBy: 'id DESC',
    );
    return rows.map(SellerRating.fromMap).toList();
  }

  Future<SellerRating?> mySellerRating({
    required int userId,
    required int sellerId,
  }) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'seller_ratings',
      where: 'seller_id = ? AND user_id = ?',
      whereArgs: <Object?>[sellerId, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SellerRating.fromMap(rows.first);
  }

  /// Rates a seller, replacing this customer's previous rating.
  Future<String?> submitSellerRating({
    required int sellerId,
    required int userId,
    required String userName,
    required int rating,
    String comment = '',
  }) async {
    if (rating < 1 || rating > 5) {
      return 'Please choose between one and five stars.';
    }
    final Database db = await _db;

    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> existing = await txn.query(
        'seller_ratings',
        columns: <String>['id'],
        where: 'seller_id = ? AND user_id = ?',
        whereArgs: <Object?>[sellerId, userId],
        limit: 1,
      );

      final Map<String, Object?> values = <String, Object?>{
        'seller_id': sellerId,
        'user_id': userId,
        'user_name': userName.trim().isEmpty ? 'Customer' : userName.trim(),
        'rating': rating,
        'comment': comment.trim(),
        'created_at': nowIso(),
      };

      if (existing.isEmpty) {
        await txn.insert('seller_ratings', values);
      } else {
        await txn.update(
          'seller_ratings',
          values,
          where: 'id = ?',
          whereArgs: <Object?>[asInt(existing.first['id'])],
        );
      }

      await DatabaseHelper.recomputeSellerRating(txn, sellerId);
      return null;
    });
  }
}
