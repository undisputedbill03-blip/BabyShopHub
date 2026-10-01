import '../core/db_utils.dart';
import 'product.dart';

/// One line in the shopping cart.
///
/// The [product] is loaded alongside the row so the cart screen can show
/// the name, image, live price and stock without a second query.
class CartItem {
  final int? id;
  final int userId;
  final int productId;
  final int quantity;
  final String addedAt;
  final Product product;

  const CartItem({
    this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.addedAt,
    required this.product,
  });

  double get lineTotal => product.price * quantity;

  /// True when the shopper is asking for more than the warehouse has.
  bool get exceedsStock => quantity > product.stock;

  /// Built from the cart JOIN in `CartRepository.itemsForUser`.
  ///
  /// That query selects `ci.id AS cart_id` together with `p.*`, so the bare
  /// `id` key belongs to the PRODUCT and the cart row's own id arrives as
  /// `cart_id`. Reading `map['id']` here would silently store the product id
  /// on the cart line and every update would hit the wrong row.
  factory CartItem.fromMap(Map<String, Object?> map) {
    return CartItem(
      id: asIntOrNull(map['cart_id']),
      userId: asInt(map['user_id']),
      productId: asInt(map['product_id']),
      quantity: asInt(map['quantity'], 1),
      addedAt: asString(map['added_at']),
      product: Product.fromMap(map),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'added_at': addedAt,
    };
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      userId: userId,
      productId: productId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt,
      product: product,
    );
  }
}
