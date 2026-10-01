import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/admin_repository.dart';
import '../../data/catalog_repository.dart';
import '../../data/database_helper.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// Add or edit a product.
///
/// The image is chosen from the set of bundled product pictures rather than
/// typed as a path, so a listing can never point at an asset that is not in
/// the app. Ratings are never editable here — they are earned through reviews.
class AdminProductFormScreen extends StatefulWidget {
  final Product? existing;

  const AdminProductFormScreen({super.key, this.existing});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CatalogRepository _catalog = CatalogRepository();
  final AdminRepository _admin = AdminRepository();

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _ageGroup;

  int? _categoryId;
  int? _sellerId;
  late String _imageStem;
  bool _isActive = true;
  bool _saving = false;

  late Future<_FormLookups> _lookups;

  /// The stems of the 40 bundled product pictures.
  static const List<String> _imageStems = <String>[
    'bath-aveeno-lotion', 'bath-duck-set', 'bath-foldable-tub',
    'bath-johnsons-wash', 'bath-sudocrem-cream', 'changing-mat-raised',
    'clothing-bamboo-romper', 'clothing-hat-mittens', 'clothing-hooded-towel',
    'clothing-knit-cardigan', 'clothing-sleepsuit-3pack',
    'diapers-huggies-comfort', 'diapers-molfix-newborn', 'diapers-pampers-dry',
    'feeding-avent-bottle', 'feeding-silicone-bib', 'feeding-steam-steriliser',
    'feeding-suction-plate', 'feeding-training-cup', 'food-banana-oat-pouch',
    'food-cerelac-wheat', 'food-gerber-apple', 'food-heinz-rice',
    'food-nan-optipro', 'nursery-baby-monitor', 'nursery-blackout-curtains',
    'nursery-cot-bed', 'nursery-cot-mattress', 'nursery-night-light',
    'toys-play-gym', 'toys-rattle-set', 'toys-shape-sorter',
    'toys-stacking-rings', 'toys-teether-rainbow', 'travel-baby-carrier',
    'travel-bottle-warmer', 'travel-car-seat', 'travel-changing-backpack',
    'travel-fold-stroller', 'wipes-waterwipes-4pack',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Product? p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p == null ? '' : _trimZeros(p.price));
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _ageGroup = TextEditingController(text: p?.ageGroup ?? '');
    _categoryId = p?.categoryId;
    _sellerId = p?.sellerId;
    _imageStem = _stemFromPath(p?.imagePath) ?? _imageStems.first;
    _isActive = p?.isActive ?? true;
    _lookups = _loadLookups();
  }

  String _trimZeros(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  String? _stemFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final String file = path.split('/').last;
    return file.endsWith('.png') ? file.substring(0, file.length - 4) : file;
  }

  Future<_FormLookups> _loadLookups() async {
    final List<ProductCategory> categories = await _catalog.categories();
    final List<Seller> sellers = await _catalog.sellers();
    // Default the pickers to the first option when adding a new product.
    _categoryId ??= categories.isNotEmpty ? categories.first.id : null;
    _sellerId ??= sellers.isNotEmpty ? sellers.first.id : null;
    return _FormLookups(categories: categories, sellers: sellers);
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _ageGroup.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final String? chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _ImagePickerSheet(
        stems: _imageStems,
        selected: _imageStem,
      ),
    );
    if (chosen != null) setState(() => _imageStem = chosen);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      showSnack(context, 'Please choose a category.', error: true);
      return;
    }
    if (_sellerId == null) {
      showSnack(context, 'Please choose a seller.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final Product base = widget.existing ??
        const Product(
          name: '',
          brand: '',
          price: 0,
          categoryId: 0,
          sellerId: 0,
          createdAt: '',
        );
    final Product product = base.copyWith(
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      description: _description.text.trim(),
      price: double.parse(_price.text.trim()),
      categoryId: _categoryId,
      sellerId: _sellerId,
      stock: int.parse(_stock.text.trim()),
      imagePath: DatabaseHelper.imagePathFor(_imageStem),
      ageGroup: _ageGroup.text.trim(),
      isActive: _isActive,
    );

    final String? error;
    if (_isEditing) {
      error = await _admin.updateProduct(product);
    } else {
      await _admin.createProduct(product);
      error = null;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnack(context, error, error: true);
      return;
    }
    showSnack(context, _isEditing ? 'Product updated.' : 'Product added.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'Add product'),
      ),
      body: AsyncView<_FormLookups>(
        future: _lookups,
        builder: (_FormLookups lookups) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Column(
                    children: <Widget>[
                      ProductImage(
                        path: DatabaseHelper.imagePathFor(_imageStem),
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Tap to change image',
                          style: AppText.small
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: AppInput.decoration(label: 'Product name'),
                validator: (String? v) =>
                    Validators.required(v, field: 'Product name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _brand,
                textCapitalization: TextCapitalization.words,
                decoration: AppInput.decoration(label: 'Brand'),
                validator: (String? v) =>
                    Validators.required(v, field: 'Brand'),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: AppInput.decoration(label: 'Category'),
                items: <DropdownMenuItem<int>>[
                  for (final ProductCategory c in lookups.categories)
                    DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (int? v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<int>(
                value: _sellerId,
                decoration: AppInput.decoration(label: 'Seller'),
                items: <DropdownMenuItem<int>>[
                  for (final Seller s in lookups.sellers)
                    DropdownMenuItem<int>(value: s.id, child: Text(s.name)),
                ],
                onChanged: (int? v) => setState(() => _sellerId = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: AppInput.decoration(
                        label: 'Price',
                        prefixText: '₦ ',
                      ),
                      validator: Validators.price,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: AppInput.decoration(label: 'Stock'),
                      validator: Validators.stock,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _ageGroup,
                decoration: AppInput.decoration(
                  label: 'Age group (optional)',
                  hint: 'e.g. 0-6 months',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: AppInput.decoration(
                  label: 'Description (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                value: _isActive,
                onChanged: (bool v) => setState(() => _isActive = v),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: Text('Visible in shop',
                    style:
                        AppText.body.copyWith(fontWeight: FontWeight.w600)),
                subtitle: const Text('Hidden products keep their order history',
                    style: AppText.tiny),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: AppButtons.primary(),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Add product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerSheet extends StatelessWidget {
  final List<String> stems;
  final String selected;

  const _ImagePickerSheet({required this.stems, required this.selected});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            const Text('Choose a product image', style: AppText.h3),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GridView.count(
                controller: controller,
                padding: const EdgeInsets.all(AppSpacing.lg),
                crossAxisCount: 3,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                children: <Widget>[
                  for (final String stem in stems)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(stem),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: stem == selected
                                ? AppColors.primary
                                : AppColors.border,
                            width: stem == selected ? 2.4 : 1,
                          ),
                        ),
                        child: ProductImage(
                          path: 'assets/images/products/$stem.png',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FormLookups {
  final List<ProductCategory> categories;
  final List<Seller> sellers;

  const _FormLookups({required this.categories, required this.sellers});
}
