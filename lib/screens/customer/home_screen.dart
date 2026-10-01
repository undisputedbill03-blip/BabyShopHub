import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../data/catalog_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';

/// The shop's front page: a greeting, a search entry, a category strip and
/// two featured product rows (popular and new).
class HomeScreen extends StatefulWidget {
  final VoidCallback onSeeAllCategories;
  final VoidCallback onGoToCart;

  const HomeScreen({
    super.key,
    required this.onSeeAllCategories,
    required this.onGoToCart,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CatalogRepository _catalog = CatalogRepository();
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final List<ProductCategory> categories =
        await _catalog.categories(onlyWithProducts: true);
    final List<Product> popular = await _catalog.topRated(limit: 8);
    final List<Product> fresh = await _catalog.newArrivals(limit: 8);
    return _HomeData(categories: categories, popular: popular, fresh: fresh);
  }

  Future<void> _refresh() async {
    final Future<_HomeData> next = _load();
    setState(() => _future = next);
    await next;
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProductListScreen(
          title: 'Search',
          autofocusSearch: true,
        ),
      ),
    );
  }

  void _openCategory(ProductCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductListScreen(
          title: category.name,
          categoryId: category.id,
        ),
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(productId: product.id!),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    final CartProvider cart = context.read<CartProvider>();
    final String? error = await cart.add(product.id!);
    if (!mounted) return;
    showSnack(context, error ?? 'Added to your basket.', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final String name = context.watch<SessionProvider>().user?.name ?? 'there';
    final String firstName = name.split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: AsyncView<_HomeData>(
            future: _future,
            builder: (_HomeData data) => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                _Greeting(firstName: firstName, onCartTap: widget.onGoToCart),
                const SizedBox(height: AppSpacing.lg),
                _SearchBar(onTap: _openSearch),
                const SizedBox(height: AppSpacing.lg),
                const _PromoCard(),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(
                  title: 'Shop by category',
                  actionLabel: 'See all',
                  onAction: widget.onSeeAllCategories,
                ),
                _CategoryStrip(
                  categories: data.categories,
                  onTap: _openCategory,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (data.popular.isNotEmpty) ...<Widget>[
                  const SectionHeader(title: 'Popular right now'),
                  _ProductStrip(
                    products: data.popular,
                    onOpen: _openProduct,
                    onAdd: _addToCart,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (data.fresh.isNotEmpty) ...<Widget>[
                  const SectionHeader(title: 'New in'),
                  _ProductStrip(
                    products: data.fresh,
                    onOpen: _openProduct,
                    onAdd: _addToCart,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String firstName;
  final VoidCallback onCartTap;

  const _Greeting({required this.firstName, required this.onCartTap});

  @override
  Widget build(BuildContext context) {
    final int count = context.watch<CartProvider>().unitCount;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Hello, $firstName', style: AppText.h1),
              const Text(AppConfig.tagline, style: AppText.bodyMuted),
            ],
          ),
        ),
        Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: AppColors.primary,
          child: IconButton(
            onPressed: onCartTap,
            icon: const Icon(Icons.shopping_cart_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.search, color: AppColors.textMuted),
            SizedBox(width: AppSpacing.sm),
            Text('Search for diapers, food, toys...',
                style: AppText.bodyMuted),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Free delivery',
                  style: AppText.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'On orders over ${AppConfig.currencySymbol}50,000. '
                  'Everything for your little one, delivered.',
                  style: AppText.small.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.local_shipping_outlined,
              color: Colors.white, size: 48),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onTap;

  const _CategoryStrip({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text('No categories yet.', style: AppText.bodyMuted);
    }
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) {
          final ProductCategory category = categories[i];
          return GestureDetector(
            onTap: () => onTap(category),
            child: SizedBox(
              width: 78,
              child: Column(
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(category.icon,
                        color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    style: AppText.tiny,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductStrip extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;

  const _ProductStrip({
    required this.products,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 268,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) => SizedBox(
          width: 168,
          child: ProductCard(
            product: products[i],
            onTap: () => onOpen(products[i]),
            onAdd: () => onAdd(products[i]),
          ),
        ),
      ),
    );
  }
}

class _HomeData {
  final List<ProductCategory> categories;
  final List<Product> popular;
  final List<Product> fresh;

  const _HomeData({
    required this.categories,
    required this.popular,
    required this.fresh,
  });
}
