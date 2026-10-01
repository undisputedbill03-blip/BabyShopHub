import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/catalog_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'product_detail_screen.dart';

/// The browse-and-search screen.
///
/// One screen serves three entry points: tapping a category (opens filtered
/// to that category), tapping the search box (opens with the keyboard up),
/// and "see all" links. Filters live in a bottom sheet so the results stay
/// full-width on a phone.
class ProductListScreen extends StatefulWidget {
  final String title;
  final int? categoryId;
  final String initialQuery;
  final bool autofocusSearch;

  const ProductListScreen({
    super.key,
    this.title = 'Products',
    this.categoryId,
    this.initialQuery = '',
    this.autofocusSearch = false,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final CatalogRepository _catalog = CatalogRepository();
  final TextEditingController _search = TextEditingController();

  late Future<List<Product>> _future;

  // Active filter state.
  String _query = '';
  int? _categoryId;
  String _brand = '';
  double? _minPrice;
  double? _maxPrice;
  double _minRating = 0;
  bool _inStockOnly = false;
  ProductSort _sort = ProductSort.newest;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _search.text = widget.initialQuery;
    _categoryId = widget.categoryId;
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Product>> _load() {
    return _catalog.products(
      query: _query,
      categoryId: _categoryId,
      brand: _brand,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      inStockOnly: _inStockOnly,
      sort: _sort,
    );
  }

  void _apply() => setState(() => _future = _load());

  void _runSearch(String value) {
    _query = value.trim();
    _apply();
  }

  int get _activeFilterCount {
    int n = 0;
    if (_brand.isNotEmpty) n++;
    if (_minPrice != null || _maxPrice != null) n++;
    if (_minRating > 0) n++;
    if (_inStockOnly) n++;
    return n;
  }

  Future<void> _openFilters() async {
    final _FilterResult? result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _FilterSheet(
        catalog: _catalog,
        brand: _brand,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        inStockOnly: _inStockOnly,
      ),
    );
    if (result == null) return;
    setState(() {
      _brand = result.brand;
      _minPrice = result.minPrice;
      _maxPrice = result.maxPrice;
      _minRating = result.minRating;
      _inStockOnly = result.inStockOnly;
      _future = _load();
    });
  }

  Future<void> _addToCart(Product product) async {
    final CartProvider cart = context.read<CartProvider>();
    final String? error = await cart.add(product.id!);
    if (!mounted) return;
    showSnack(context, error ?? 'Added to your basket.', error: error != null);
  }

  void _open(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(productId: product.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _search,
                    autofocus: widget.autofocusSearch,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _runSearch,
                    decoration: AppInput.decoration(
                      label: 'Search products',
                      hint: 'Name, brand or category',
                      icon: Icons.search,
                      suffix: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                _runSearch('');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterButton(
                  count: _activeFilterCount,
                  onTap: _openFilters,
                ),
              ],
            ),
          ),
          _SortBar(
            sort: _sort,
            onChanged: (ProductSort s) => setState(() {
              _sort = s;
              _future = _load();
            }),
          ),
          Expanded(
            child: AsyncView<List<Product>>(
              future: _future,
              builder: (List<Product> products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    message: _activeFilterCount > 0 || _query.isNotEmpty
                        ? 'Try removing a filter or searching for something else.'
                        : 'There is nothing here yet.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: products.length,
                  itemBuilder: (BuildContext context, int i) => ProductCard(
                    product: products[i],
                    onTap: () => _open(products[i]),
                    onAdd: () => _addToCart(products[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: AppColors.primary,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.tune, color: AppColors.primaryDark),
          ),
        ),
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  final ProductSort sort;
  final ValueChanged<ProductSort> onChanged;

  const _SortBar({required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: <Widget>[
          for (final ProductSort option in ProductSort.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(option.label),
                selected: sort == option,
                onSelected: (_) => onChanged(option),
                selectedColor: AppColors.primarySoft,
                labelStyle: TextStyle(
                  color: sort == option
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontWeight:
                      sort == option ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The result handed back from the filter sheet.
class _FilterResult {
  final String brand;
  final double? minPrice;
  final double? maxPrice;
  final double minRating;
  final bool inStockOnly;

  const _FilterResult({
    required this.brand,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
    required this.inStockOnly,
  });
}

class _FilterSheet extends StatefulWidget {
  final CatalogRepository catalog;
  final String brand;
  final double? minPrice;
  final double? maxPrice;
  final double minRating;
  final bool inStockOnly;

  const _FilterSheet({
    required this.catalog,
    required this.brand,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
    required this.inStockOnly,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Future<_FilterData> _future;

  String _brand = '';
  double _minRating = 0;
  bool _inStockOnly = false;
  RangeValues? _priceRange;
  PriceBounds _bounds = const PriceBounds(0, 100000);

  @override
  void initState() {
    super.initState();
    _brand = widget.brand;
    _minRating = widget.minRating;
    _inStockOnly = widget.inStockOnly;
    _future = _load();
  }

  Future<_FilterData> _load() async {
    final List<String> brands = await widget.catalog.brands();
    final PriceBounds bounds = await widget.catalog.priceBounds();
    _bounds = bounds;
    _priceRange = RangeValues(
      widget.minPrice ?? bounds.min,
      widget.maxPrice ?? bounds.max,
    );
    return _FilterData(brands: brands, bounds: bounds);
  }

  void _reset() {
    setState(() {
      _brand = '';
      _minRating = 0;
      _inStockOnly = false;
      _priceRange = RangeValues(_bounds.min, _bounds.max);
    });
  }

  void _submit() {
    final RangeValues? range = _priceRange;
    final bool priceTouched = range != null &&
        (range.start > _bounds.min || range.end < _bounds.max);
    Navigator.of(context).pop(_FilterResult(
      brand: _brand,
      minPrice: priceTouched ? range.start : null,
      maxPrice: priceTouched ? range.end : null,
      minRating: _minRating,
      inStockOnly: _inStockOnly,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController controller) {
        return AsyncView<_FilterData>(
          future: _future,
          builder: (_FilterData data) => _sheetBody(controller, data),
        );
      },
    );
  }

  Widget _sheetBody(ScrollController controller, _FilterData data) {
    final RangeValues range = _priceRange ?? RangeValues(_bounds.min, _bounds.max);
    return Column(
      children: <Widget>[
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              const Expanded(child: Text('Filters', style: AppText.h2)),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: <Widget>[
              const Text('Price range', style: AppText.h3),
              RangeSlider(
                min: _bounds.min,
                max: _bounds.max,
                divisions: 20,
                activeColor: AppColors.primary,
                values: range,
                labels: RangeLabels(
                  range.start.round().toString(),
                  range.end.round().toString(),
                ),
                onChanged: (RangeValues v) => setState(() => _priceRange = v),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Brand', style: AppText.h3),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('All brands'),
                    selected: _brand.isEmpty,
                    onSelected: (_) => setState(() => _brand = ''),
                    selectedColor: AppColors.primarySoft,
                  ),
                  for (final String brand in data.brands)
                    ChoiceChip(
                      label: Text(brand),
                      selected: _brand == brand,
                      onSelected: (_) => setState(() => _brand = brand),
                      selectedColor: AppColors.primarySoft,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Minimum rating', style: AppText.h3),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (final double r in <double>[0, 3, 4, 4.5])
                    ChoiceChip(
                      label: Text(r == 0 ? 'Any' : '$r+'),
                      selected: _minRating == r,
                      onSelected: (_) => setState(() => _minRating = r),
                      selectedColor: AppColors.primarySoft,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                value: _inStockOnly,
                onChanged: (bool v) => setState(() => _inStockOnly = v),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text('In stock only', style: AppText.body),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: ElevatedButton(
              onPressed: _submit,
              style: AppButtons.primary(),
              child: const Text('Show results'),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterData {
  final List<String> brands;
  final PriceBounds bounds;

  const _FilterData({required this.brands, required this.bounds});
}
