import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../data/support_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Raise a new support request: pick a category, give a subject and describe
/// the problem. Pops with `true` when the ticket is created.
class SupportNewScreen extends StatefulWidget {
  const SupportNewScreen({super.key});

  @override
  State<SupportNewScreen> createState() => _SupportNewScreenState();
}

class _SupportNewScreenState extends State<SupportNewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SupportRepository _support = SupportRepository();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();

  String _category = SupportTicket.categories.first;
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final SessionProvider session = context.read<SessionProvider>();
    setState(() => _sending = true);
    await _support.create(
      userId: session.userId!,
      userName: session.user?.name ?? 'Customer',
      subject: _subject.text,
      category: _category,
      firstMessage: _message.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    showSnack(context, 'Your request has been sent.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            const Text('Category', style: AppText.small),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String option in SupportTicket.categories)
                  ChoiceChip(
                    label: Text(option),
                    selected: _category == option,
                    onSelected: (_) => setState(() => _category = option),
                    showCheckmark: false,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _category == option
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide(
                        color: _category == option
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _subject,
              textCapitalization: TextCapitalization.sentences,
              decoration: AppInput.decoration(
                label: 'Subject',
                icon: Icons.subject,
                hint: 'A short summary',
              ),
              validator: (String? v) =>
                  Validators.required(v, field: 'Subject'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _message,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: AppInput.decoration(
                label: 'How can we help?',
                hint: 'Describe your question or problem',
              ),
              validator: (String? v) =>
                  Validators.required(v, field: 'Message'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _sending ? null : _submit,
              style: AppButtons.primary(),
              child: _sending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Send request'),
            ),
          ],
        ),
      ),
    );
  }
}
