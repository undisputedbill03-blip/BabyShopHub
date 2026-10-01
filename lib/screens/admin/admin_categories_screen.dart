import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/admin_repository.dart';
import '../../data/catalog_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// Category management. Lists every category with how many products sit in it,
/// and lets the admin add, rename, re-icon or delete one. A category that
/// still has products cannot be deleted — the repository reports that rather
/// than orphaning the listings — so the count on each row doubles as a guard
/// the admin can read before trying.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final CatalogRepository _catalog = CatalogRepository();
  final AdminRepository _admin = AdminRepository();

  late Future<List<ProductCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // The management screen shows every category, including empty ones.
  Future<List<ProductCategory>> _load() => _catalog.categories();

  void _reload() => setState(() => _future = _load());

  Future<void> _addOrEdit({ProductCategory? existing}) async {
    final ProductCategory? draft = await showModalBottomSheet<ProductCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _CategoryFormSheet(existing: existing),
    );
    if (draft == null) return;

    final String? error = existing == null
        ? await _admin.createCategory(draft)
        : await _admin.updateCategory(draft);
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      showSnack(context, existing == null ? 'Category added.' : 'Category saved.');
      _reload();
    }
  }

  Future<void> _delete(ProductCategory category) async {
    if (category.productCount > 0) {
      showSnack(
        context,
        'This category has ${category.productCount} product(s). Move or hide '
        'them before deleting it.',
        error: true,
      );
      return;
    }
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text('This removes the empty category.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;

    final String? error = await _admin.deleteCategory(category.id!);
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      showSnack(context, 'Category deleted.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: AsyncView<List<ProductCategory>>(
          future: _future,
          builder: (List<ProductCategory> categories) {
            if (categories.isEmpty) {
              return const EmptyState(
                icon: Icons.category_outlined,
                title: 'No categories',
                message: 'Add your first category with the button below.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
              itemCount: categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int i) => _CategoryCard(
                category: categories[i],
                onEdit: () => _addOrEdit(existing: categories[i]),
                onDelete: () => _delete(categories[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ProductCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySoft,
            child: Icon(category.icon, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(category.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                Text(
                    '${category.productCount} product'
                    '${category.productCount == 1 ? '' : 's'}',
                    style: AppText.tiny),
                if (category.description.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(category.description,
                      style: AppText.tiny,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              const PopupMenuItem<String>(
                  value: 'delete', child: Text('Delete')),
            ],
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// The add/edit form, shown as a bottom sheet. Returns a [ProductCategory]
/// draft (never written directly — the screen calls the repository so the
/// unique-name check and the result message live in one place).
class _CategoryFormSheet extends StatefulWidget {
  final ProductCategory? existing;

  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _iconName;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ProductCategory? c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _description = TextEditingController(text: c?.description ?? '');
    _iconName = c?.iconName ?? ProductCategory.iconKeys.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final ProductCategory base = widget.existing ??
        const ProductCategory(name: '');
    Navigator.of(context).pop(
      base.copyWith(
        name: _name.text.trim(),
        description: _description.text.trim(),
        iconName: _iconName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_isEditing ? 'Edit category' : 'New category',
                style: AppText.h3),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: AppInput.decoration(label: 'Category name'),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  AppInput.decoration(label: 'Description (optional)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Icon', style: AppText.small),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String key in ProductCategory.iconKeys)
                  _IconChoice(
                    iconData: ProductCategory.iconFor(key),
                    selected: key == _iconName,
                    onTap: () => setState(() => _iconName = key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: AppButtons.primary(),
                child: Text(_isEditing ? 'Save changes' : 'Add category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final IconData iconData;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.iconData,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(iconData,
            color: selected ? AppColors.primaryDark : AppColors.textSecondary),
      ),
    );
  }
}
