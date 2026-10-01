import '../core/db_utils.dart';

/// An item for sale.
///
/// `categoryName` and `sellerName` are filled in by the JOIN used in
/// [ProductRepository]; they are not columns on the products table.
class Product {
  final int? id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final int categoryId;
  final int sellerId;
  final int stock;
  final String imagePath;
  final String ageGroup;
  final int ratingSum;
  final int ratingCount;
  final bool isActive;
  final String createdAt;

  // Joined, read-only extras.
  final String categoryName;
  final String sellerName;

  const Product({
    this.id,
    required this.name,
    required this.brand,
    this.description = '',
    required this.price,
    required this.categoryId,
    required this.sellerId,
    this.stock = 0,
    this.imagePath = '',
    this.ageGroup = '',
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.categoryName = '',
    this.sellerName = '',
  });

  double get averageRating => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  bool get inStock => stock > 0;

  bool get isLowStock => stock > 0 && stock <= 5;

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: asIntOrNull(map['id']),
      name: asString(map['name']),
      brand: asString(map['brand']),
      description: asString(map['description']),
      price: asDouble(map['price']),
      categoryId: asInt(map['category_id']),
      sellerId: asInt(map['seller_id']),
      stock: asInt(map['stock']),
      imagePath: asString(map['image_path']),
      ageGroup: asString(map['age_group']),
      ratingSum: asInt(map['rating_sum']),
      ratingCount: asInt(map['rating_count']),
      isActive: asBool(map['is_active'], true),
      createdAt: asString(map['created_at']),
      categoryName: asString(map['category_name']),
      sellerName: asString(map['seller_name']),
    );
  }

  /// Only real columns are written back, so a joined Product can be saved
  /// without SQLite complaining about unknown columns.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'name': name,
      'brand': brand,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'seller_id': sellerId,
      'stock': stock,
      'image_path': imagePath,
      'age_group': ageGroup,
      'rating_sum': ratingSum,
      'rating_count': ratingCount,
      'is_active': boolToInt(isActive),
      'created_at': createdAt,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? brand,
    String? description,
    double? price,
    int? categoryId,
    int? sellerId,
    int? stock,
    String? imagePath,
    String? ageGroup,
    int? ratingSum,
    int? ratingCount,
    bool? isActive,
    String? createdAt,
    String? categoryName,
    String? sellerName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      sellerId: sellerId ?? this.sellerId,
      stock: stock ?? this.stock,
      imagePath: imagePath ?? this.imagePath,
      ageGroup: ageGroup ?? this.ageGroup,
      ratingSum: ratingSum ?? this.ratingSum,
      ratingCount: ratingCount ?? this.ratingCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
      sellerName: sellerName ?? this.sellerName,
    );
  }
}

/// Sorting options offered on the product list and search screens.
enum ProductSort { newest, priceLowHigh, priceHighLow, rating, nameAZ }

extension ProductSortLabel on ProductSort {
  String get label {
    switch (this) {
      case ProductSort.newest:
        return 'Newest first';
      case ProductSort.priceLowHigh:
        return 'Price: low to high';
      case ProductSort.priceHighLow:
        return 'Price: high to low';
      case ProductSort.rating:
        return 'Top rated';
      case ProductSort.nameAZ:
        return 'Name: A to Z';
    }
  }

  /// The ORDER BY clause used by the repository. Written as a fixed string
  /// per case - never built from user input - so it cannot be injected.
  String get orderByClause {
    switch (this) {
      case ProductSort.newest:
        return 'p.created_at DESC, p.id DESC';
      case ProductSort.priceLowHigh:
        return 'p.price ASC';
      case ProductSort.priceHighLow:
        return 'p.price DESC';
      case ProductSort.rating:
        return 'CASE WHEN p.rating_count = 0 THEN 0 '
            'ELSE CAST(p.rating_sum AS REAL) / p.rating_count END DESC, '
            'p.rating_count DESC';
      case ProductSort.nameAZ:
        return 'p.name COLLATE NOCASE ASC';
    }
  }
}
