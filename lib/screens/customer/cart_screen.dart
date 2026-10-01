import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/formats.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';

/// The shopping basket tab.
///
/// Reads live from [CartProvider], so the totals here are the same numbers
/// checkout will charge. A line that now exceeds stock is flagged and blocks
/// checkout until it is fixed.
class CartScreen extends StatelessWidget {
  final VoidCallback onStartShopping;

  const CartScreen({super.key, required this.onStartShopping});

  Future<void> _checkout(BuildContext context) async {
    final CartProvider cart = context.read<CartProvider>();
    final List<String> notes = await cart.reconcile();
    if (!context.mounted) return;
    if (notes.isNotEmpty) {
      showSnack(context, notes.first, error: true);
      return;
    }
    if (cart.isEmpty) {
      showSnack(context, 'Your basket is empty.', error: true);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CartProvider cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your basket'),
        actions: <Widget>[
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your basket is empty',
              message: 'Browse the shop and add items you love.',
              actionLabel: 'Start shopping',
              onAction: onStartShopping,
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: AppSpacing.lg),
                    itemBuilder: (BuildContext context, int i) =>
                        _CartLine(item: cart.items[i]),
                  ),
                ),
                _CheckoutBar(cart: cart, onCheckout: () => _checkout(context)),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CartProvider cart) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear basket?'),
        content: const Text('This removes every item from your basket.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (yes == true) await cart.clear();
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final CartProvider cart = context.read<CartProvider>();
    final Product product = item.product;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(productId: product.id!),
            ),
          ),
          child: ProductImage(path: product.imagePath, width: 76, height: 76),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(product.name,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              Text(Formats.money(product.price), style: AppText.small),
              if (item.exceedsStock) ...<Widget>[
                const SizedBox(height: 4),
                StatusPill(
                  label: product.inStock
                      ? 'Only ${product.stock} in stock'
                      : 'Out of stock',
                  color: AppColors.danger,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  QuantityStepper(
                    value: item.quantity,
                    min: 1,
                    max: product.stock < 1 ? 1 : product.stock,
                    onChanged: (int q) => cart.setQuantity(
                      cartItemId: item.id!,
                      quantity: q,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Formats.money(item.lineTotal),
                    style: AppText.price.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => cart.remove(item.id!),
          icon: const Icon(Icons.close, size: 20),
          color: AppColors.textMuted,
          tooltip: 'Remove',
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onCheckout;

  const _CheckoutBar({required this.cart, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final double toFree = cart.amountToFreeShipping;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (toFree > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.local_shipping_outlined,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Add ${Formats.money(toFree)} more for free delivery.',
                        style: AppText.small,
                      ),
                    ),
                  ],
                ),
              ),
            _summaryRow('Subtotal', cart.subtotal),
            _summaryRow(
              'Delivery',
              cart.shipping,
              freeLabel: cart.shipping == 0,
            ),
            _summaryRow('VAT (${(AppConfig.taxRate * 100).round()}%)', cart.tax),
            const Divider(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                const Text('Total', style: AppText.h3),
                const Spacer(),
                Text(Formats.money(cart.total), style: AppText.priceLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: cart.hasStockProblem ? null : onCheckout,
              style: AppButtons.primary(),
              child: Text(
                cart.hasStockProblem
                    ? 'Fix basket to continue'
                    : 'Proceed to checkout',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool freeLabel = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Text(label, style: AppText.bodyMuted),
          const Spacer(),
          Text(
            freeLabel ? 'Free' : Formats.money(value),
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w600,
              color: freeLabel ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
