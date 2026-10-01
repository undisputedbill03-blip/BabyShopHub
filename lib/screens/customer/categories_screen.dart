import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/catalog_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'product_list_screen.dart';

/// The categories tab: a tidy grid the shopper can browse by department.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CatalogRepository _catalog = CatalogRepository();
  late Future<List<ProductCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = _catalog.categories();
  }

  void _open(ProductCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductListScreen(
          title: category.name,
          categoryId: category.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: AsyncView<List<ProductCategory>>(
        future: _future,
        builder: (List<ProductCategory> categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.grid_view,
              title: 'No categories',
              message: 'Categories will appear here once they are added.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              childAspectRatio: 1.5,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: categories.length,
            itemBuilder: (BuildContext context, int i) =>
                _CategoryTile(category: categories[i], onTap: _open),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ProductCategory category;
  final ValueChanged<ProductCategory> onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(category),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.card(),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(category.icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    category.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${category.productCount} item'
                    '${category.productCount == 1 ? '' : 's'}',
                    style: AppText.tiny,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
