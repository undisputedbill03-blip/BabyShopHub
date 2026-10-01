import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/auth_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

/// Add a new delivery address or edit an existing one.
///
/// Pops with `true` when something was saved, so the screen that opened it
/// knows to reload its list.
class AddressFormScreen extends StatefulWidget {
  final Address? existing;

  const AddressFormScreen({super.key, this.existing});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _auth = AuthRepository();

  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postal;

  late String _label;
  late bool _isDefault;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Address? a = widget.existing;
    _fullName = TextEditingController(text: a?.fullName ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
    _line1 = TextEditingController(text: a?.line1 ?? '');
    _line2 = TextEditingController(text: a?.line2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _state = TextEditingController(text: a?.state ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _label = a?.label ?? Address.labelOptions.first;
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final int userId = context.read<SessionProvider>().userId!;
    final Address address = Address(
      id: widget.existing?.id,
      userId: userId,
      label: _label,
      fullName: _fullName.text.trim(),
      phone: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      postalCode: _postal.text.trim(),
      isDefault: _isDefault,
    );

    await _auth.saveAddress(address);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit address' : 'Add address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            const Text('Label', style: AppText.small),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final String option in Address.labelOptions)
                  ChoiceChip(
                    label: Text(option),
                    selected: _label == option,
                    onSelected: (_) => setState(() => _label = option),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _label == option
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide(
                        color: _label == option
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _fullName,
              textCapitalization: TextCapitalization.words,
              decoration: AppInput.decoration(
                label: 'Recipient name',
                icon: Icons.person_outline,
              ),
              validator: Validators.name,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: AppInput.decoration(
                label: 'Phone number',
                icon: Icons.phone_outlined,
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _line1,
              textCapitalization: TextCapitalization.words,
              decoration: AppInput.decoration(
                label: 'Address line 1',
                icon: Icons.home_outlined,
                hint: 'House number and street',
              ),
              validator: (String? v) =>
                  Validators.required(v, field: 'Address line 1'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _line2,
              textCapitalization: TextCapitalization.words,
              decoration: AppInput.decoration(
                label: 'Address line 2 (optional)',
                icon: Icons.apartment_outlined,
                hint: 'Flat, suite, landmark',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: AppInput.decoration(label: 'City'),
                    validator: (String? v) =>
                        Validators.required(v, field: 'City'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _state,
                    textCapitalization: TextCapitalization.words,
                    decoration: AppInput.decoration(label: 'State'),
                    validator: (String? v) =>
                        Validators.required(v, field: 'State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _postal,
              keyboardType: TextInputType.number,
              decoration: AppInput.decoration(
                label: 'Postal code',
                icon: Icons.markunread_mailbox_outlined,
              ),
              validator: Validators.postalCode,
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              value: _isDefault,
              onChanged: (bool v) => setState(() => _isDefault = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: Text('Set as default address',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text('Used automatically at checkout',
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
                  : Text(_isEditing ? 'Save changes' : 'Save address'),
            ),
          ],
        ),
      ),
    );
  }
}
