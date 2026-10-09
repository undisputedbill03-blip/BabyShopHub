import 'package:flutter/foundation.dart';

import '../data/favorites_repository.dart';
import '../models/models.dart';

/// The signed-in customer's saved products (wishlist), shared so the heart on
/// every product card, the product page and the Favorites screen all reflect
/// the same state at once — the same pattern the cart uses.
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FavoritesRepository? favorites})
      : _favorites = favorites ?? FavoritesRepository();

  final FavoritesRepository _favorites;

  int? _userId;
  Set<int> _ids = <int>{};
  List<Product> _products = const <Product>[];
  bool _loading = false;

  /// The favorited products, newest first — what the Favorites screen shows.
  List<Product> get products => _products;

  bool get loading => _loading;
  bool get isEmpty => _ids.isEmpty;
  int get count => _ids.length;

  bool isFavorite(int productId) => _ids.contains(productId);

  /// Points the wishlist at a different account and reloads. Signing out
  /// (null) clears the in-memory view without touching the database.
  Future<void> bindUser(int? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      _ids = <int>{};
      _products = const <Product>[];
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
    _ids = await _favorites.idsFor(id);
    _products = await _favorites.listFor(id);
    _loading = false;
    notifyListeners();
  }

  /// Flips a product's favorite state. The heart set updates immediately so
  /// the icon responds at once, then the full product list is refreshed for
  /// the Favorites screen.
  Future<void> toggle(int productId) async {
    final int? id = _userId;
    if (id == null) return;
    final bool nowFavorite =
        await _favorites.toggle(userId: id, productId: productId);
    if (nowFavorite) {
      _ids.add(productId);
    } else {
      _ids.remove(productId);
    }
    notifyListeners();
    _products = await _favorites.listFor(id);
    notifyListeners();
  }
}
