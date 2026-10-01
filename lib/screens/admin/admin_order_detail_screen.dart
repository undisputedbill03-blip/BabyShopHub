import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/order_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// The admin view of one order: who ordered what, where it goes, and the
/// controls to move it to its next status. Every status change writes a
/// tracking event the customer then sees.
class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final OrderRepository _orders = OrderRepository();
  late Future<Order?> _future;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _future = _orders.byId(widget.orderId);
  }

  void _reload() => setState(() => _future = _orders.byId(widget.orderId));

  Future<void> _advance(String newStatus) async {
    final bool cancelling = newStatus == OrderStatus.cancelled;
    if (cancelling) {
      final bool? yes = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Cancel this order?'),
          content: const Text('Stock will be returned to the shelf.'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancel order')),
          ],
        ),
      );
      if (yes != true) return;
    }

    setState(() => _working = true);
    final String? error =
        await _orders.advanceStatus(orderId: widget.orderId, newStatus: newStatus);
    if (!mounted) return;
    setState(() => _working = false);
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      showSnack(context, 'Order moved to $newStatus.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage order')),
      body: AsyncView<Order?>(
        future: _future,
        builder: (Order? order) {
          if (order == null) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Order not found',
              message: 'This order could not be located.',
            );
          }
          return _content(order);
        },
      ),
    );
  }

  Widget _content(Order order) {
    final List<String> options = OrderStatus.nextOptions(order.status);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(order.orderCode, style: AppText.h2),
                  Text('Placed ${Formats.dateTime(order.placedAt)}',
                      style: AppText.tiny),
                ],
              ),
            ),
            StatusPill(
              label: order.status,
              color: OrderStatus.color(order.status),
              icon: OrderStatus.icon(order.status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: 'Update status',
          child: options.isEmpty
              ? Text(
                  order.isCancelled
                      ? 'This order was cancelled. No further changes.'
                      : 'This order is delivered. No further changes.',
                  style: AppText.bodyMuted,
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final String status in options)
                      ElevatedButton.icon(
                        onPressed: _working ? null : () => _advance(status),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == OrderStatus.cancelled
                              ? AppColors.danger
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        icon: Icon(OrderStatus.icon(status), size: 18),
                        label: Text(status),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          title: 'Customer',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(order.customerName,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Text(order.shipFullName, style: AppText.small),
              Text(order.shippingOneLine, style: AppText.small),
              Text(order.shipPhone, style: AppText.small),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          title: 'Items (${order.items.length})',
          child: Column(
            children: <Widget>[
              for (final OrderItem item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ProductImage(
                          path: item.imagePath, width: 46, height: 46),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item.productName,
                                style: AppText.small
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            Text('${item.quantity} × ${Formats.money(item.unitPrice)}',
                                style: AppText.tiny),
                          ],
                        ),
                      ),
                      Text(Formats.money(item.lineTotal), style: AppText.small),
                    ],
                  ),
                ),
              const Divider(height: AppSpacing.lg),
              _row('Subtotal', Formats.money(order.subtotal)),
              _row('Delivery',
                  order.shippingFee == 0 ? 'Free' : Formats.money(order.shippingFee)),
              _row('VAT', Formats.money(order.tax)),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const Text('Total', style: AppText.h3),
                  const Spacer(),
                  Text(Formats.money(order.total), style: AppText.price),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Payment: ${order.paymentLabel}', style: AppText.tiny),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          title: 'History',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final OrderEvent event in order.events)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(OrderStatus.icon(event.status),
                          size: 16, color: OrderStatus.color(event.status)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(event.status,
                                style: AppText.small
                                    .copyWith(fontWeight: FontWeight.w600)),
                            if (event.note.isNotEmpty)
                              Text(event.note, style: AppText.tiny),
                          ],
                        ),
                      ),
                      Text(Formats.dateTime(event.createdAt),
                          style: AppText.tiny),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Text(label, style: AppText.bodyMuted),
          const Spacer(),
          Text(value, style: AppText.body),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppText.h3),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
