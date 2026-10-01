import 'package:flutter/material.dart';

import '../core/db_utils.dart';

/// A product category such as Diapering or Baby Food.
class ProductCategory {
  final int? id;
  final String name;
  final String description;

  /// Stored as a short keyword and mapped to a Material icon by [icon].
  /// Storing a name rather than an icon code point keeps the database
  /// readable and avoids tree-shaking problems with dynamic IconData.
  final String iconName;
  final int sortOrder;

  /// Populated by joined queries; not a stored column.
  final int productCount;

  const ProductCategory({
    this.id,
    required this.name,
    this.description = '',
    this.iconName = 'category',
    this.sortOrder = 0,
    this.productCount = 0,
  });

  factory ProductCategory.fromMap(Map<String, Object?> map) {
    return ProductCategory(
      id: asIntOrNull(map['id']),
      name: asString(map['name']),
      description: asString(map['description']),
      iconName: asString(map['icon_name'], 'category'),
      sortOrder: asInt(map['sort_order']),
      productCount: asInt(map['product_count']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'sort_order': sortOrder,
    };
  }

  ProductCategory copyWith({
    int? id,
    String? name,
    String? description,
    String? iconName,
    int? sortOrder,
    int? productCount,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      productCount: productCount ?? this.productCount,
    );
  }

  IconData get icon => iconFor(iconName);

  /// Icons are referenced as constants so Flutter's icon tree-shaking works.
  static IconData iconFor(String key) {
    switch (key) {
      case 'diaper':
        return Icons.baby_changing_station;
      case 'food':
        return Icons.restaurant;
      case 'clothing':
        return Icons.checkroom;
      case 'toys':
        return Icons.toys;
      case 'bath':
        return Icons.bathtub_outlined;
      case 'feeding':
        return Icons.local_drink_outlined;
      case 'nursery':
        return Icons.crib;
      case 'travel':
        return Icons.stroller;
      case 'health':
        return Icons.medical_services_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  /// The keys offered in the admin category form.
  static const List<String> iconKeys = <String>[
    'diaper',
    'food',
    'clothing',
    'toys',
    'bath',
    'feeding',
    'nursery',
    'travel',
    'health',
    'category',
  ];
}
