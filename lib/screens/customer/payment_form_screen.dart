import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/auth_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

/// Add a simulated payment card.
///
/// The full number is validated for shape and used only to derive the brand
/// and last four digits. Nothing more is kept, no CVV is stored, and nothing
/// is transmitted — payment in this project is a demo, as the brief states.
class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _auth = AuthRepository();

  final TextEditingController _number = TextEditingController();
  final TextEditingController _holder = TextEditingController();
  final TextEditingController _month = TextEditingController();
  final TextEditingController _year = TextEditingController();

  bool _isDefault = false;
  bool _saving = false;
  String _brand = 'Card';

  @override
  void initState() {
    super.initState();
    _number.addListener(_updateBrand);
  }

  void _updateBrand() {
    final String brand = PaymentMethod.brandFromNumber(_number.text);
    if (brand != _brand) setState(() => _brand = brand);
  }

  @override
  void dispose() {
    _number.removeListener(_updateBrand);
    _number.dispose();
    _holder.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final int userId = context.read<SessionProvider>().userId!;
    final PaymentMethod method = PaymentMethod(
      userId: userId,
      cardHolder: _holder.text.trim(),
      cardBrand: PaymentMethod.brandFromNumber(_number.text),
      last4: PaymentMethod.last4FromNumber(_number.text),
      expiryMonth: int.parse(_month.text.trim()),
      expiryYear: _normaliseYear(_year.text.trim()),
      isDefault: _isDefault,
    );

    await _auth.savePaymentMethod(method);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  /// Accepts a two- or four-digit year and always stores four digits.
  int _normaliseYear(String raw) {
    final int value = int.tryParse(raw) ?? DateTime.now().year;
    if (value < 100) return 2000 + value;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add card')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            _SimBanner(),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _number,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
              ],
              decoration: AppInput.decoration(
                label: 'Card number',
                icon: Icons.credit_card,
                suffix: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Center(
                    widthFactor: 1,
                    child: Text(_brand,
                        style: AppText.small
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              validator: Validators.cardNumber,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _holder,
              textCapitalization: TextCapitalization.words,
              decoration: AppInput.decoration(
                label: 'Cardholder name',
                icon: Icons.person_outline,
              ),
              validator: (String? v) =>
                  Validators.required(v, field: 'Cardholder name'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _month,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: AppInput.decoration(
                      label: 'Exp. month',
                      hint: 'MM',
                    ),
                    validator: Validators.expiryMonth,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: AppInput.decoration(
                      label: 'Exp. year',
                      hint: 'YYYY',
                    ),
                    validator: Validators.expiryYear,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              value: _isDefault,
              onChanged: (bool v) => setState(() => _isDefault = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: Text('Set as default card',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              subtitle:
                  const Text('Used automatically at checkout', style: AppText.tiny),
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
                  : const Text('Save card'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.lock_outline, size: 18, color: AppColors.accent),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Only your card brand and last four digits are saved. No CVV is '
              'stored and nothing is charged.',
              style: AppText.tiny,
            ),
          ),
        ],
      ),
    );
  }
}
