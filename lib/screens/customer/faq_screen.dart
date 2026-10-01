import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';

/// A simple in-app help centre: frequently asked questions as expandable
/// tiles. The list is fixed content, so it lives here rather than in the
/// database.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<FaqEntry> _faqs = <FaqEntry>[
    FaqEntry(
      'How do I place an order?',
      'Browse or search for a product, open it, choose a quantity and tap '
          'Add to basket. When you are ready, open your basket, tap Proceed '
          'to checkout, choose a delivery address and a payment method, then '
          'place the order.',
    ),
    FaqEntry(
      'Is my payment real?',
      'No. Payment in this app is simulated for demonstration. No real card '
          'is charged and no card number is stored — only the card brand and '
          'last four digits are kept so you can recognise a saved card.',
    ),
    FaqEntry(
      'How do I track my order?',
      'Open the Orders tab and tap an order to see its tracking timeline. It '
          'moves through Pending, Confirmed, Packed, Shipped, Out for delivery '
          'and Delivered, each with the time it happened.',
    ),
    FaqEntry(
      'Can I cancel an order?',
      'Yes, while it is still being prepared. Open the order and tap Cancel '
          'order. Once an order has shipped it can no longer be cancelled — '
          'please contact support instead. Cancelling returns the items to '
          'stock.',
    ),
    FaqEntry(
      'How do I leave a review?',
      'You can review a product once you have a delivered order that '
          'contains it. Open the product and tap Write a review to give a '
          'star rating and a comment.',
    ),
    FaqEntry(
      'How do I change my delivery address?',
      'Go to Account, then Delivery addresses. You can add, edit or delete '
          'addresses and choose which one is used by default at checkout.',
    ),
    FaqEntry(
      'When do I get free delivery?',
      'Delivery is free once your basket subtotal reaches the free-delivery '
          'threshold. The basket shows how much more you need to add to '
          'qualify.',
    ),
    FaqEntry(
      'How do I contact support?',
      'Go to Account, then Help & support, and tap New request. Choose a '
          'category, add a subject and describe your issue. You can reply to '
          'the conversation any time until it is closed.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int i) => _FaqCard(entry: _faqs[i]),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final FaqEntry entry;
  const _FaqCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.card(),
      child: Theme(
        // Removes the default divider lines an ExpansionTile draws.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textMuted,
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(entry.question,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
          children: <Widget>[
            Text(entry.answer, style: AppText.bodyMuted),
          ],
        ),
      ),
    );
  }
}
