import '../core/db_utils.dart';

/// A customer review of a product.
///
/// One review per user per product is enforced by a UNIQUE constraint in
/// the schema, so submitting again updates the existing review.
class Review {
  final int? id;
  final int productId;
  final int userId;

  /// The author's name is copied in so the review list needs no JOIN and
  /// still reads correctly if the account is later removed.
  final String userName;
  final int rating;
  final String title;
  final String comment;

  /// Admins can hide an abusive review without destroying the record.
  final bool isHidden;
  final String createdAt;

  /// Joined extra, used on the admin moderation screen.
  final String productName;

  const Review({
    this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.title = '',
    this.comment = '',
    this.isHidden = false,
    required this.createdAt,
    this.productName = '',
  });

  factory Review.fromMap(Map<String, Object?> map) {
    return Review(
      id: asIntOrNull(map['id']),
      productId: asInt(map['product_id']),
      userId: asInt(map['user_id']),
      userName: asString(map['user_name'], 'Customer'),
      rating: asInt(map['rating'], 5),
      title: asString(map['title']),
      comment: asString(map['comment']),
      isHidden: asBool(map['is_hidden']),
      createdAt: asString(map['created_at']),
      productName: asString(map['product_name']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'title': title,
      'comment': comment,
      'is_hidden': boolToInt(isHidden),
      'created_at': createdAt,
    };
  }

  Review copyWith({
    int? rating,
    String? title,
    String? comment,
    bool? isHidden,
    String? createdAt,
  }) {
    return Review(
      id: id,
      productId: productId,
      userId: userId,
      userName: userName,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      productName: productName,
    );
  }
}

/// A rating given to a seller, used to build trust in the marketplace.
class SellerRating {
  final int? id;
  final int sellerId;
  final int userId;
  final String userName;
  final int rating;
  final String comment;
  final String createdAt;

  const SellerRating({
    this.id,
    required this.sellerId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory SellerRating.fromMap(Map<String, Object?> map) {
    return SellerRating(
      id: asIntOrNull(map['id']),
      sellerId: asInt(map['seller_id']),
      userId: asInt(map['user_id']),
      userName: asString(map['user_name'], 'Customer'),
      rating: asInt(map['rating'], 5),
      comment: asString(map['comment']),
      createdAt: asString(map['created_at']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'seller_id': sellerId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
    };
  }
}

/// Breakdown of how many reviews gave each star value, used to draw the
/// rating histogram on the product page.
class RatingBreakdown {
  final Map<int, int> counts;
  final int total;
  final double average;

  const RatingBreakdown({
    required this.counts,
    required this.total,
    required this.average,
  });

  factory RatingBreakdown.empty() => const RatingBreakdown(
        counts: <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        total: 0,
        average: 0,
      );

  int countFor(int star) => counts[star] ?? 0;

  /// Share of reviews at [star], from 0.0 to 1.0.
  double fractionFor(int star) => total == 0 ? 0 : countFor(star) / total;
}
