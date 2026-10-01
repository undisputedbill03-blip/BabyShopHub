import 'package:flutter/material.dart';

import '../core/formats.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'common.dart';
import 'star_rating.dart';

/// The product tile shown in grids on the home, category and search screens.
///
/// Tapping the card opens the product; the "add" affordance is a small button
/// so the whole card stays a single, predictable tap target.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppDecorations.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // The image flexes to fill whatever vertical space is left after
            // the text block below. This keeps the card within its bounded
            // parent (the horizontal strips and the product grid) no matter
            // how tall the title wraps, so it can never overflow.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ProductImage(path: product.imagePath, radius: 0),
                  if (!product.inStock)
                    const Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: StatusPill(
                        label: 'Out of stock',
                        color: AppColors.danger,
                      ),
                    )
                  else if (product.isLowStock)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: StatusPill(
                        label: 'Only ${product.stock} left',
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.brand.toUpperCase(),
                    style: AppText.tiny.copyWith(
                      letterSpacing: 0.5,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (product.ratingCount > 0)
                    StarRating(
                      rating: product.averageRating,
                      count: product.ratingCount,
                      size: 13,
                    )
                  else
                    const Text('No reviews yet', style: AppText.tiny),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          Formats.money(product.price),
                          style: AppText.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onAdd != null)
                        _AddButton(
                          enabled: product.inStock,
                          onTap: onAdd!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : AppColors.textMuted,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// A wide horizontal product row, used in the cart, order summaries and
/// the "you might also like" strip when a compact form is wanted.
class ProductRow extends StatelessWidget {
  final String imagePath;
  final String name;
  final String brand;
  final String priceLabel;
  final String? trailingLabel;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProductRow({
    super.key,
    required this.imagePath,
    required this.name,
    required this.brand,
    required this.priceLabel,
    this.trailingLabel,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProductImage(path: imagePath, width: 64, height: 64),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (brand.isNotEmpty)
                    Text(
                      brand.toUpperCase(),
                      style: AppText.tiny.copyWith(color: AppColors.accent),
                    ),
                  Text(
                    name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(priceLabel, style: AppText.price.copyWith(fontSize: 14)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && trailingLabel != null)
              Text(trailingLabel!, style: AppText.small),
          ],
        ),
      ),
    );
  }
}
