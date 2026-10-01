import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'address_form_screen.dart';

/// Manage saved delivery addresses: add, edit, set default, delete.
class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final AuthRepository _auth = AuthRepository();
  late Future<List<Address>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  int get _userId => context.read<SessionProvider>().userId!;

  Future<List<Address>> _load() => _auth.addressesFor(_userId);

  void _reload() => setState(() => _future = _load());

  Future<void> _add() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddressFormScreen()),
    );
    if (saved == true) _reload();
  }

  Future<void> _edit(Address address) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddressFormScreen(existing: address),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _makeDefault(Address address) async {
    await _auth.setDefaultAddress(userId: _userId, addressId: address.id!);
    _reload();
  }

  Future<void> _delete(Address address) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove "${address.label}" from your saved addresses?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await _auth.deleteAddress(userId: _userId, addressId: address.id!);
    if (!mounted) return;
    showSnack(context, 'Address deleted.');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: AsyncView<List<Address>>(
        future: _future,
        builder: (List<Address> addresses) {
          if (addresses.isEmpty) {
            return EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No addresses saved',
              message: 'Add a delivery address to check out faster next time.',
              actionLabel: 'Add address',
              onAction: _add,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int i) => _AddressCard(
              address: addresses[i],
              onEdit: () => _edit(addresses[i]),
              onMakeDefault: () => _makeDefault(addresses[i]),
              onDelete: () => _delete(addresses[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onMakeDefault;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onMakeDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(address.label,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
              if (address.isDefault) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                const StatusPill(label: 'Default', color: AppColors.accent),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'default':
                      onMakeDefault();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                      value: 'edit', child: Text('Edit')),
                  if (!address.isDefault)
                    const PopupMenuItem<String>(
                        value: 'default', child: Text('Set as default')),
                  const PopupMenuItem<String>(
                      value: 'delete', child: Text('Delete')),
                ],
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(address.fullName,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
          Text(address.oneLine, style: AppText.small),
          Text(address.phone, style: AppText.small),
        ],
      ),
    );
  }
}
