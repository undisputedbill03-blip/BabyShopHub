import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'payment_form_screen.dart';

/// Manage saved (simulated) payment cards: add, set default, delete.
///
/// Only the brand and last four digits are ever stored; see [PaymentMethod].
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final AuthRepository _auth = AuthRepository();
  late Future<List<PaymentMethod>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  int get _userId => context.read<SessionProvider>().userId!;

  Future<List<PaymentMethod>> _load() => _auth.paymentMethodsFor(_userId);

  void _reload() => setState(() => _future = _load());

  Future<void> _add() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PaymentFormScreen()),
    );
    if (saved == true) _reload();
  }

  Future<void> _makeDefault(PaymentMethod card) async {
    await _auth.setDefaultPaymentMethod(userId: _userId, methodId: card.id!);
    _reload();
  }

  Future<void> _delete(PaymentMethod card) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text(
            'Remove ${card.cardBrand} ${Formats.maskedCard(card.last4)}?'),
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
    await _auth.deletePaymentMethod(userId: _userId, methodId: card.id!);
    if (!mounted) return;
    showSnack(context, 'Card deleted.');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
      ),
      body: AsyncView<List<PaymentMethod>>(
        future: _future,
        builder: (List<PaymentMethod> cards) {
          if (cards.isEmpty) {
            return EmptyState(
              icon: Icons.credit_card_outlined,
              title: 'No cards saved',
              message: 'Add a card to check out faster. Payment is simulated '
                  'for this demo — no real card is charged.',
              actionLabel: 'Add card',
              onAction: _add,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int i) => _CardTile(
              card: cards[i],
              onMakeDefault: () => _makeDefault(cards[i]),
              onDelete: () => _delete(cards[i]),
            ),
          );
        },
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final PaymentMethod card;
  final VoidCallback onMakeDefault;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.onMakeDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.credit_card, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        '${card.cardBrand} ${Formats.maskedCard(card.last4)}',
                        style: AppText.body
                            .copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (card.isDefault) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      const StatusPill(
                          label: 'Default', color: AppColors.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${card.cardHolder}  ·  Expires ${card.expiryLabel}',
                    style: AppText.tiny),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'default') onMakeDefault();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (!card.isDefault)
                const PopupMenuItem<String>(
                    value: 'default', child: Text('Set as default')),
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
