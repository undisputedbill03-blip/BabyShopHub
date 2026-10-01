import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/auth_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Edit name and phone, and change password, for the signed-in customer.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _profileKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    final AppUser? user = context.read<SessionProvider>().user;
    _name.text = user?.name ?? '';
    _phone.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final bool ok = await context
        .read<SessionProvider>()
        .updateProfile(name: _name.text, phone: _phone.text);
    if (!mounted) return;
    showSnack(
      context,
      ok ? 'Profile updated.' : 'Could not update your profile.',
      error: !ok,
    );
  }

  Future<void> _openPasswordSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = context.watch<SessionProvider>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Form(
            key: _profileKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: AppInput.decoration(
                    label: 'Full name',
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
                ElevatedButton(
                  onPressed: busy ? null : _saveProfile,
                  style: AppButtons.primary(),
                  child: const Text('Save changes'),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xxl),
          const Text('Security', style: AppText.h3),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: AppDecorations.card(),
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: Text('Change password',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              subtitle: const Text('Update the password you sign in with',
                  style: AppText.tiny),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: _openPasswordSheet,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final AuthResult result = await context.read<SessionProvider>().changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.ok) {
      Navigator.of(context).pop();
      showSnack(context, 'Your password has been changed.');
    } else {
      showSnack(context, result.error ?? 'Could not change password.',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Change password', style: AppText.h2),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: AppInput.decoration(
                label: 'Current password',
                icon: Icons.lock_outline,
              ),
              validator: (String? v) =>
                  Validators.required(v, field: 'Current password'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: AppInput.decoration(
                label: 'New password',
                icon: Icons.lock_reset_outlined,
                helper: 'At least 8 characters, with a letter and a number.',
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: AppInput.decoration(
                label: 'Confirm new password',
                icon: Icons.lock_outline,
              ),
              validator: (String? v) =>
                  Validators.confirmPassword(v, _next.text),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: AppButtons.primary(),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update password'),
            ),
          ],
        ),
      ),
    );
  }
}
