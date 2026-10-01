import 'package:flutter/foundation.dart';

import '../core/pricing.dart';
import '../data/cart_repository.dart';
import '../models/models.dart';

/// The shopping basket, shared so the badge on the app bar, the cart screen
/// and checkout all read the same live numbers.
///
/// The basket belongs to one signed-in customer. When the account changes
/// (sign in, sign out, switch user) [bindUser] swaps the basket over, so a
/// customer never sees a basket that was not theirs.
class CartProvider extends ChangeNotifier {
  CartProvider({CartRepository? cart}) : _cart = cart ?? CartRepository();

  final CartRepository _cart;

  int? _userId;
  List<CartItem> _items = const <CartItem>[];
  bool _loading = false;

  List<CartItem> get items => _items;
  bool get loading => _loading;
  bool get isEmpty => _items.isEmpty;

  /// Total units, for the little number on the cart icon.
  int get unitCount {
    int total = 0;
    for (final CartItem item in _items) {
      total += item.quantity;
    }
    return total;
  }

  /// Number of distinct lines, shown as "3 items in your basket".
  int get lineCount => _items.length;

  /// Sum of every line at the product's live price.
  double get subtotal =>
      Pricing.subtotalOf(_items.map((CartItem i) => i.lineTotal));

  double get shipping => Pricing.shippingFor(subtotal);

  double get tax => Pricing.taxFor(subtotal);

  double get total => Pricing.totalFor(subtotal);

  /// How much more to spend for free delivery, 0 once it is reached.
  double get amountToFreeShipping => Pricing.amountToFreeShipping(subtotal);

  /// True if any line is now asking for more than the product has in stock,
  /// which blocks checkout until it is reconciled.
  bool get hasStockProblem => _items.any((CartItem i) => i.exceedsStock);

  /// Points the basket at a different account and reloads.
  ///
  /// Called from the provider wiring whenever the signed-in user changes.
  /// Signing out passes null, which empties the basket in memory without
  /// touching the database.
  Future<void> bindUser(int? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      _items = const <CartItem>[];
      notifyListeners();
      return;
    }
    await reload();
  }

  Future<void> reload() async {
    final int? id = _userId;
    if (id == null) return;
    _loading = true;
    notifyListeners();
    _items = await _cart.itemsFor(id);
    _loading = false;
    notifyListeners();
  }

  /// Adds a product to the basket. Returns null on success or a message to
  /// show the shopper (out of stock, exceeds stock).
  Future<String?> add(int productId, {int quantity = 1}) async {
    final int? id = _userId;
    if (id == null) return 'Please sign in to add items to your basket.';
    final String? error =
        await _cart.add(userId: id, productId: productId, quantity: quantity);
    if (error == null) await reload();
    return error;
  }

  Future<String?> setQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    final int? id = _userId;
    if (id == null) return 'Please sign in first.';
    final String? error = await _cart.setQuantity(
      userId: id,
      cartItemId: cartItemId,
      quantity: quantity,
    );
    if (error == null) await reload();
    return error;
  }

  Future<void> remove(int cartItemId) async {
    final int? id = _userId;
    if (id == null) return;
    await _cart.remove(userId: id, cartItemId: cartItemId);
    await reload();
  }

  Future<void> clear() async {
    final int? id = _userId;
    if (id == null) return;
    await _cart.clear(id);
    await reload();
  }

  /// Trims lines that drifted above stock before checkout, returning any
  /// human-readable notes about what changed so the screen can explain them.
  Future<List<String>> reconcile() async {
    final int? id = _userId;
    if (id == null) return const <String>[];
    final List<String> notes = await _cart.reconcileWithStock(id);
    if (notes.isNotEmpty) await reload();
    return notes;
  }
}
