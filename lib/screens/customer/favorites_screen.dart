import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'product_detail_screen.dart';

/// The customer's saved products. It reads the shared [FavoritesProvider], so
/// un-hearting an item here (or anywhere else) updates this grid live.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _addToCart(BuildContext context, Product product) async {
    final String? error = await context.read<CartProvider>().add(product.id!);
    if (!context.mounted) return;
    showSnack(context, error ?? 'Added to your basket.', error: error != null);
  }

  void _open(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(productId: product.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> products = context.watch<FavoritesProvider>().products;

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              message:
                  'Tap the heart on any product to save it here for later.',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.60,
              ),
              itemCount: products.length,
              itemBuilder: (BuildContext context, int i) {
                final Product product = products[i];
                return ProductCard(
                  product: product,
                  onTap: () => _open(context, product),
                  onAdd: () => _addToCart(context, product),
                );
              },
            ),
    );
  }
}
