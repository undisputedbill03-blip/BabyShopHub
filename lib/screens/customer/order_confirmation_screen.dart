import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import 'order_detail_screen.dart';

/// The thank-you screen shown after checkout.
///
/// It replaces the checkout route, so the device back button returns to the
/// shop rather than to a checkout for an order that is already placed.
class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: <Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle,
                          size: 56, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Thank you for your order!',
                      style: AppText.h1, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Your order has been placed and is now being prepared. '
                    'You can follow its progress any time from your orders.',
                    style: AppText.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: AppDecorations.card(color: AppColors.surfaceAlt),
                    child: Column(
                      children: <Widget>[
                        _row('Order number', order.orderCode),
                        _row('Placed on', Formats.date(order.placedAt)),
                        _row('Delivering to', order.shipFullName),
                        _row('Address', order.shippingOneLine),
                        _row('Payment', order.paymentLabel),
                        const Divider(height: AppSpacing.lg),
                        Row(
                          children: <Widget>[
                            const Text('Total paid', style: AppText.h3),
                            const Spacer(),
                            Text(Formats.money(order.total),
                                style: AppText.price),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailScreen(orderId: order.id!),
                      ),
                    ),
                    style: AppButtons.primary(),
                    icon: const Icon(Icons.local_shipping_outlined, size: 20),
                    label: const Text('Track this order'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
                    style: AppButtons.secondary(),
                    child: const Text('Continue shopping'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, style: AppText.small),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
