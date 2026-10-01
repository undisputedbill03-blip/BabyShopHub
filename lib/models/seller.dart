import '../core/db_utils.dart';

/// A vendor whose products are listed in the store.
///
/// Ratings are stored as a running sum plus a count so the average can be
/// derived. Storing a pre-computed average instead would drift out of sync
/// the first time a rating is edited or deleted.
class Seller {
  final int? id;
  final String name;
  final String description;
  final int ratingSum;
  final int ratingCount;

  const Seller({
    this.id,
    required this.name,
    this.description = '',
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  double get averageRating =>
      ratingCount == 0 ? 0 : ratingSum / ratingCount;

  factory Seller.fromMap(Map<String, Object?> map) {
    return Seller(
      id: asIntOrNull(map['id']),
      name: asString(map['name']),
      description: asString(map['description']),
      ratingSum: asInt(map['rating_sum']),
      ratingCount: asInt(map['rating_count']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'rating_sum': ratingSum,
      'rating_count': ratingCount,
    };
  }

  Seller copyWith({
    int? id,
    String? name,
    String? description,
    int? ratingSum,
    int? ratingCount,
  }) {
    return Seller(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ratingSum: ratingSum ?? this.ratingSum,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
