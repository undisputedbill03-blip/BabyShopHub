import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/theme.dart';
import '../../data/admin_repository.dart';
import '../../data/catalog_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'admin_product_form_screen.dart';

/// The catalogue manager: search every product (including hidden ones), add a
/// new one, edit, adjust stock, or hide/restore a listing.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final CatalogRepository _catalog = CatalogRepository();
  final AdminRepository _admin = AdminRepository();
  final TextEditingController _search = TextEditingController();

  late Future<List<Product>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Product>> _load() =>
      _catalog.products(query: _query, includeInactive: true, limit: 200);

  void _reload() => setState(() => _future = _load());

  Future<void> _addProduct() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AdminProductFormScreen()),
    );
    if (saved == true) _reload();
  }

  Future<void> _editProduct(Product product) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminProductFormScreen(existing: product),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _toggleActive(Product product) async {
    final String? error = await _admin.setProductActive(
      productId: product.id!,
      active: !product.isActive,
    );
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      _reload();
    }
  }

  Future<void> _adjustStock(Product product) async {
    final int? delta = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => _StockDialog(product: product),
    );
    if (delta == null || delta == 0) return;
    final String? error =
        await _admin.adjustStock(productId: product.id!, delta: delta);
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      showSnack(context, 'Stock updated.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _search,
              onChanged: (String v) {
                _query = v;
                _reload();
              },
              decoration: AppInput.decoration(
                label: 'Search products',
                icon: Icons.search,
                suffix: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _query = '';
                          _reload();
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: AsyncView<List<Product>>(
              future: _future,
              builder: (List<Product> products) {
                if (products.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products',
                    message: 'Add your first product with the button below.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, 96),
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (BuildContext context, int i) => _ProductRow(
                    product: products[i],
                    onEdit: () => _editProduct(products[i]),
                    onToggleActive: () => _toggleActive(products[i]),
                    onAdjustStock: () => _adjustStock(products[i]),
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

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onAdjustStock;

  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onToggleActive,
    required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Opacity(
            opacity: product.isActive ? 1 : 0.5,
            child: ProductImage(
                path: product.imagePath, width: 56, height: 56),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(product.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(product.brand, style: AppText.tiny),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(Formats.money(product.price),
                        style: AppText.small
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: AppSpacing.sm),
                    _stockPill(product),
                    if (!product.isActive) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      const StatusPill(
                          label: 'Hidden', color: AppColors.textMuted),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'stock':
                  onAdjustStock();
                case 'active':
                  onToggleActive();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              const PopupMenuItem<String>(
                  value: 'stock', child: Text('Adjust stock')),
              PopupMenuItem<String>(
                value: 'active',
                child: Text(product.isActive ? 'Hide from shop' : 'Restore'),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _stockPill(Product product) {
    if (!product.inStock) {
      return const StatusPill(label: 'Out of stock', color: AppColors.danger);
    }
    if (product.isLowStock) {
      return StatusPill(
          label: 'Low: ${product.stock}', color: AppColors.warning);
    }
    return StatusPill(label: '${product.stock} in stock',
        color: AppColors.success);
  }
}

/// A small dialog to add or remove stock by a delta.
class _StockDialog extends StatefulWidget {
  final Product product;
  const _StockDialog({required this.product});

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  final TextEditingController _amount = TextEditingController(text: '1');

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${widget.product.name}\nCurrent stock: ${widget.product.stock}',
              style: AppText.small),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: AppInput.decoration(label: 'Amount'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(-_value),
          child: const Text('Remove'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
