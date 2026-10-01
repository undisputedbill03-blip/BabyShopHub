import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/order_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// A customer's view of one order: status, tracking timeline, the items,
/// the delivery address, the payment summary, and — while still allowed — a
/// cancel button.
class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderRepository _orders = OrderRepository();
  late Future<Order?> _future;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _future = _orders.byId(widget.orderId);
  }

  void _reload() => setState(() => _future = _orders.byId(widget.orderId));

  Future<void> _cancel(Order order) async {
    // Read the session id before the dialog await, so no BuildContext is used
    // across an async gap; the signed-in user cannot change mid-dialog.
    final int userId = context.read<SessionProvider>().userId!;
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'The items will be returned to stock. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _cancelling = true);
    final String? error =
        await _orders.cancelForCustomer(userId: userId, orderId: order.id!);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (error == null) {
      showSnack(context, 'Your order has been cancelled.');
      _reload();
    } else {
      showSnack(context, error, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
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
    final bool canCancel =
        OrderStatus.nextOptions(order.status).contains(OrderStatus.cancelled);

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
        _Timeline(order: order),
        const SizedBox(height: AppSpacing.lg),
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
                          path: item.imagePath, width: 52, height: 52),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item.productName,
                                style: AppText.body
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              '${item.quantity} × ${Formats.money(item.unitPrice)}',
                              style: AppText.tiny,
                            ),
                          ],
                        ),
                      ),
                      Text(Formats.money(item.lineTotal), style: AppText.small),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          title: 'Delivery address',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(order.shipFullName,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              Text(order.shippingOneLine, style: AppText.small),
              Text(order.shipPhone, style: AppText.small),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          title: 'Payment summary',
          child: Column(
            children: <Widget>[
              _row('Payment method', order.paymentLabel),
              _row('Subtotal', Formats.money(order.subtotal)),
              _row('Delivery',
                  order.shippingFee == 0 ? 'Free' : Formats.money(order.shippingFee)),
              _row('VAT', Formats.money(order.tax)),
              const Divider(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  const Text('Total', style: AppText.h3),
                  const Spacer(),
                  Text(Formats.money(order.total), style: AppText.price),
                ],
              ),
            ],
          ),
        ),
        if (canCancel) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _cancelling ? null : () => _cancel(order),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: _cancelling
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: AppColors.danger),
                  )
                : const Icon(Icons.cancel_outlined, size: 20),
            label: const Text('Cancel order'),
          ),
        ],
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
          Flexible(
            child: Text(value,
                style: AppText.body, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// The vertical tracking timeline built from the order's recorded events.
class _Timeline extends StatelessWidget {
  final Order order;
  const _Timeline({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.isCancelled) {
      return _Section(
        title: 'Tracking',
        child: Row(
          children: <Widget>[
            const Icon(Icons.cancel, color: AppColors.danger),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Order cancelled',
                      style: AppText.body
                          .copyWith(fontWeight: FontWeight.w700)),
                  if (order.events.isNotEmpty)
                    Text(Formats.dateTime(order.events.last.createdAt),
                        style: AppText.tiny),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final int currentIndex = OrderStatus.flow.indexOf(order.status);
    return _Section(
      title: 'Tracking',
      child: Column(
        children: <Widget>[
          for (int i = 0; i < OrderStatus.flow.length; i++)
            _step(
              status: OrderStatus.flow[i],
              reached: i <= currentIndex,
              isCurrent: i == currentIndex,
              isLast: i == OrderStatus.flow.length - 1,
              event: _eventFor(OrderStatus.flow[i]),
            ),
        ],
      ),
    );
  }

  OrderEvent? _eventFor(String status) {
    for (final OrderEvent e in order.events) {
      if (e.status == status) return e;
    }
    return null;
  }

  Widget _step({
    required String status,
    required bool reached,
    required bool isCurrent,
    required bool isLast,
    required OrderEvent? event,
  }) {
    final Color color =
        reached ? OrderStatus.color(status) : AppColors.textMuted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: reached ? color.withValues(alpha: 0.14) : AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: isCurrent ? 2 : 1),
                ),
                child: Icon(
                  reached ? OrderStatus.icon(status) : Icons.circle_outlined,
                  size: 15,
                  color: color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: reached ? color : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    status,
                    style: AppText.body.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: reached
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    event != null && event.note.isNotEmpty
                        ? event.note
                        : OrderStatus.note(status),
                    style: AppText.tiny,
                  ),
                  if (event != null)
                    Text(Formats.dateTime(event.createdAt),
                        style: AppText.tiny.copyWith(color: AppColors.accent)),
                ],
              ),
            ),
          ),
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
