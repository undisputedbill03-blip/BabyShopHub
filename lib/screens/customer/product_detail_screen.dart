import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/theme.dart';
import '../../data/catalog_repository.dart';
import '../../data/order_repository.dart';
import '../../data/review_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'write_review_screen.dart';

/// Full product page: gallery, price, stock, description, rating breakdown,
/// reviews, and add-to-basket.
///
/// It reloads its own data through a Future held in state, so writing a
/// review and coming back shows the new rating without leaving the page.
class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CatalogRepository _catalog = CatalogRepository();
  final ReviewRepository _reviews = ReviewRepository();
  final OrderRepository _orders = OrderRepository();

  late Future<_ProductBundle> _future;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProductBundle> _load() async {
    // Capture the session id before any awaits, so no BuildContext is read
    // across an async gap.
    final int? userId = context.read<SessionProvider>().userId;

    final Product? product = await _catalog.productById(widget.productId);
    if (product == null) {
      throw Exception('This product is no longer available.');
    }
    final RatingBreakdown breakdown =
        await _reviews.breakdownFor(widget.productId);
    final List<Review> reviews = await _reviews.forProduct(widget.productId);
    final List<Product> related = await _catalog.relatedProducts(
      productId: widget.productId,
      categoryId: product.categoryId,
    );

    bool canReview = false;
    Review? myReview;
    if (userId != null) {
      canReview =
          await _orders.hasPurchased(userId: userId, productId: widget.productId);
      myReview =
          await _reviews.myReview(userId: userId, productId: widget.productId);
    }

    return _ProductBundle(
      product: product,
      breakdown: breakdown,
      reviews: reviews,
      related: related,
      canReview: canReview,
      myReview: myReview,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addToCart(Product product) async {
    final CartProvider cart = context.read<CartProvider>();
    final String? error = await cart.add(product.id!, quantity: _quantity);
    if (!mounted) return;
    showSnack(
      context,
      error ?? 'Added $_quantity ${product.name} to your basket.',
      error: error != null,
    );
  }

  Future<void> _openReview(Product product, Review? existing) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WriteReviewScreen(product: product, existing: existing),
      ),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: AsyncView<_ProductBundle>(
        future: _future,
        errorMessage: (_) => 'This product is no longer available.',
        builder: (_ProductBundle data) => _content(data),
      ),
    );
  }

  Widget _content(_ProductBundle data) {
    final Product product = data.product;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: ProductImage(
                  path: product.imagePath,
                  radius: AppRadius.lg,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(product.brand.toUpperCase(),
                  style: AppText.small.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  )),
              const SizedBox(height: 4),
              Text(product.name, style: AppText.h1),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  if (product.ratingCount > 0) ...<Widget>[
                    StarRating(
                      rating: product.averageRating,
                      count: product.ratingCount,
                      showValue: true,
                      size: 18,
                    ),
                  ] else
                    const Text('No reviews yet', style: AppText.small),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(Formats.money(product.price), style: AppText.priceLarge),
              const SizedBox(height: AppSpacing.sm),
              _StockLine(product: product),
              const SizedBox(height: AppSpacing.lg),
              _InfoChips(product: product),
              const SizedBox(height: AppSpacing.lg),
              const Text('About this product', style: AppText.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                product.description.isEmpty
                    ? 'No description provided.'
                    : product.description,
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              _RatingSummary(breakdown: data.breakdown),
              const SizedBox(height: AppSpacing.lg),
              _ReviewsSection(
                data: data,
                onWriteReview: () => _openReview(product, data.myReview),
              ),
              if (data.related.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'You might also like'),
                _RelatedStrip(
                  products: data.related,
                  onOpen: (int id) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailScreen(productId: id),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        _BuyBar(
          product: product,
          quantity: _quantity,
          onQuantityChanged: (int q) => setState(() => _quantity = q),
          onAdd: () => _addToCart(product),
        ),
      ],
    );
  }
}

class _StockLine extends StatelessWidget {
  final Product product;
  const _StockLine({required this.product});

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) {
      return const StatusPill(
        label: 'Out of stock',
        color: AppColors.danger,
        icon: Icons.remove_shopping_cart_outlined,
      );
    }
    if (product.isLowStock) {
      return StatusPill(
        label: 'Only ${product.stock} left in stock',
        color: AppColors.warning,
        icon: Icons.timelapse,
      );
    }
    return const StatusPill(
      label: 'In stock',
      color: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }
}

class _InfoChips extends StatelessWidget {
  final Product product;
  const _InfoChips({required this.product});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        if (product.categoryName.isNotEmpty)
          _chip(Icons.category_outlined, product.categoryName),
        if (product.ageGroup.isNotEmpty)
          _chip(Icons.child_care_outlined, product.ageGroup),
        if (product.sellerName.isNotEmpty)
          _chip(Icons.storefront_outlined, product.sellerName),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppText.small),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final RatingBreakdown breakdown;
  const _RatingSummary({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(color: AppColors.surfaceAlt),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text(breakdown.average.toStringAsFixed(1), style: AppText.h1),
              StarRating(rating: breakdown.average, size: 14),
              const SizedBox(height: 4),
              Text('${breakdown.total} review${breakdown.total == 1 ? '' : 's'}',
                  style: AppText.tiny),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              children: <Widget>[
                for (int star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        Text('$star', style: AppText.tiny),
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded,
                            size: 12, color: AppColors.star),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: breakdown.fractionFor(star),
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              color: AppColors.star,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 22,
                          child: Text('${breakdown.countFor(star)}',
                              style: AppText.tiny, textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final _ProductBundle data;
  final VoidCallback onWriteReview;

  const _ReviewsSection({required this.data, required this.onWriteReview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(child: Text('Reviews', style: AppText.h3)),
            if (data.canReview)
              TextButton.icon(
                onPressed: onWriteReview,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: Text(data.myReview == null ? 'Write' : 'Edit'),
              ),
          ],
        ),
        if (!data.canReview)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Only customers who have received this item can review it.',
              style: AppText.tiny,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (data.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('Be the first to review this product.',
                style: AppText.bodyMuted),
          )
        else
          for (final Review review in data.reviews)
            _ReviewTile(review: review),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  review.userName.isEmpty
                      ? '?'
                      : review.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(review.userName,
                        style: AppText.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(Formats.relative(review.createdAt),
                        style: AppText.tiny),
                  ],
                ),
              ),
              StarRating(rating: review.rating.toDouble(), size: 14),
            ],
          ),
          if (review.title.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(review.title,
                style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
          ],
          if (review.comment.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(review.comment, style: AppText.bodyMuted),
          ],
        ],
      ),
    );
  }
}

class _RelatedStrip extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<int> onOpen;

  const _RelatedStrip({required this.products, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) {
          final Product product = products[i];
          return SizedBox(
            width: 150,
            child: ProductCard(
              product: product,
              onTap: () => onOpen(product.id!),
            ),
          );
        },
      ),
    );
  }
}

class _BuyBar extends StatelessWidget {
  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAdd;

  const _BuyBar({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bool available = product.inStock;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            if (available)
              QuantityStepper(
                value: quantity,
                max: product.stock,
                onChanged: onQuantityChanged,
              ),
            if (available) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: available ? onAdd : null,
                style: AppButtons.primary(),
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(available ? 'Add to basket' : 'Out of stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything the detail page needs, gathered in one load.
class _ProductBundle {
  final Product product;
  final RatingBreakdown breakdown;
  final List<Review> reviews;
  final List<Product> related;
  final bool canReview;
  final Review? myReview;

  const _ProductBundle({
    required this.product,
    required this.breakdown,
    required this.reviews,
    required this.related,
    required this.canReview,
    required this.myReview,
  });
}
