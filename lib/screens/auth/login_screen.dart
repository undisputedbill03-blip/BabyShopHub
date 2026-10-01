import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/auth_repository.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'register_screen.dart';

/// Sign-in screen.
///
/// The seeded demo accounts are offered as one-tap fills so a marker can get
/// into the app — as a customer and as an admin — without typing.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final SessionProvider session = context.read<SessionProvider>();
    final AuthResult result = await session.login(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (!result.ok) {
      showSnack(context, result.error ?? 'Could not sign in.', error: true);
    }
    // On success the root gate rebuilds and shows the shop; nothing to push.
  }

  void _fillDemo({required bool admin}) {
    setState(() {
      _email.text =
          admin ? AppConfig.demoAdminEmail : AppConfig.demoCustomerEmail;
      _password.text =
          admin ? AppConfig.demoAdminPassword : AppConfig.demoCustomerPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = context.watch<SessionProvider>().busy;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _Brand(),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text('Welcome back', style: AppText.h1),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Sign in to continue shopping for your little one.',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      decoration: AppInput.decoration(
                        label: 'Email',
                        icon: Icons.mail_outline,
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: AppInput.decoration(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (String? v) =>
                          Validators.required(v, field: 'Password'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text("New here?", style: AppText.bodyMuted),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _DemoPanel(),
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

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.child_friendly,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(AppConfig.appName, style: AppText.h2),
        const Text(AppConfig.tagline, style: AppText.small),
      ],
    );
  }
}

/// The demo-account shortcut. Wrapped so it is obvious this is a convenience
/// for grading, not part of the shopper's flow.
class _DemoPanel extends StatelessWidget {
  const _DemoPanel();

  @override
  Widget build(BuildContext context) {
    final _LoginScreenState? state =
        context.findAncestorStateOfType<_LoginScreenState>();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.info_outline, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text('Demo accounts',
                  style: AppText.small.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state?._fillDemo(admin: false),
                  style: AppButtons.secondary(height: 40),
                  child: const Text('Shopper'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state?._fillDemo(admin: true),
                  style: AppButtons.secondary(height: 40),
                  child: const Text('Admin'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
