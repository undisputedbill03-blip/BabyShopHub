import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../data/catalog_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'favorites_screen.dart';
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

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FavoritesScreen(),
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
                _Greeting(
                  firstName: firstName,
                  onCartTap: widget.onGoToCart,
                  onFavoritesTap: _openFavorites,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SearchBar(onTap: _openSearch),
                const SizedBox(height: AppSpacing.lg),
                const _PromoCarousel(),
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
  final VoidCallback onFavoritesTap;

  const _Greeting({
    required this.firstName,
    required this.onCartTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final int count = context.watch<CartProvider>().unitCount;
    final int favCount = context.watch<FavoritesProvider>().count;
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
          isLabelVisible: favCount > 0,
          label: Text('$favCount'),
          backgroundColor: AppColors.primary,
          child: IconButton(
            onPressed: onFavoritesTap,
            icon: const Icon(Icons.favorite_border),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
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

/// An auto-advancing promo banner carousel: swipeable, with page dots, and it
/// rotates on its own every few seconds — the hero a real storefront opens
/// with.
class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  static const List<_Promo> _promos = <_Promo>[
    _Promo(
      title: 'Free delivery',
      subtitle: 'On orders over ${AppConfig.currencySymbol}50,000. '
          'Everything for your little one, delivered.',
      icon: Icons.local_shipping_outlined,
      colors: <Color>[AppColors.primary, AppColors.primaryDark],
    ),
    _Promo(
      title: 'New arrivals weekly',
      subtitle: 'Fresh styles and essentials added every week.',
      icon: Icons.auto_awesome_outlined,
      colors: <Color>[Color(0xFF2E8B84), Color(0xFF1F6F69)],
    ),
    _Promo(
      title: 'Trusted brands',
      subtitle: 'Pampers, Huggies, Avent, Aveeno and more.',
      icon: Icons.verified_outlined,
      colors: <Color>[Color(0xFF6D5BD0), Color(0xFF4C3DA8)],
    ),
  ];

  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), _tick);
  }
  void _tick(Timer _) {
    if (!mounted || !_controller.hasClients) return;
    _controller.animateToPage(
      (_page + 1) % _promos.length,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 104,
          child: PageView.builder(
            controller: _controller,
            itemCount: _promos.length,
            onPageChanged: (int i) => setState(() => _page = i),
            itemBuilder: (_, int i) => _PromoSlide(promo: _promos[i]),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < _promos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Promo {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _Promo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}

class _PromoSlide extends StatelessWidget {
  final _Promo promo;
  const _PromoSlide({required this.promo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: promo.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(promo.title,
                    style: AppText.h2.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(promo.subtitle,
                    style: AppText.small.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(promo.icon, color: Colors.white, size: 48),
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
          final List<Color> tint = AppCategoryTints.at(i);
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
                      color: tint[0],
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(category.icon, color: tint[1], size: 30),
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
