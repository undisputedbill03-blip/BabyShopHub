import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/auth_repository.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Account creation. On success the root gate takes over and drops the
/// customer straight into the shop, so this screen just pops itself.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _obscure = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      showSnack(context, 'Please accept the terms to continue.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();

    final SessionProvider session = context.read<SessionProvider>();
    final AuthResult result = await session.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      phone: _phone.text,
    );
    if (!mounted) return;
    if (result.ok) {
      Navigator.of(context).pop();
    } else {
      showSnack(context, result.error ?? 'Could not create account.',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = context.watch<SessionProvider>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text('Join BabyShopHub', style: AppText.h1),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'It only takes a minute to set up your account.',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: AppInput.decoration(
                        label: 'Full name',
                        icon: Icons.person_outline,
                      ),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: AppInput.decoration(
                        label: 'Email',
                        icon: Icons.mail_outline,
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: AppInput.decoration(
                        label: 'Phone number',
                        icon: Icons.phone_outlined,
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: AppInput.decoration(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        helper: 'At least 8 characters, with a letter and a number.',
                        suffix: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: AppInput.decoration(
                        label: 'Confirm password',
                        icon: Icons.lock_outline,
                      ),
                      validator: (String? v) =>
                          Validators.confirmPassword(v, _password.text),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (bool? v) =>
                          setState(() => _acceptedTerms = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      title: const Text(
                        'I agree to the terms of service and privacy policy.',
                        style: AppText.small,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: busy ? null : _submit,
                      style: AppButtons.primary(),
                      child: busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
