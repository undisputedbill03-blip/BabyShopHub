import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/order_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'order_detail_screen.dart';

/// The order history tab: every order the signed-in customer has placed,
/// newest first, with a status filter and pull-to-refresh.
class OrdersScreen extends StatefulWidget {
  final VoidCallback onStartShopping;

  const OrdersScreen({super.key, required this.onStartShopping});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderRepository _orders = OrderRepository();
  late Future<List<Order>> _future;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Order>> _load() {
    final int userId = context.read<SessionProvider>().userId!;
    return _orders.listForUser(userId, status: _statusFilter);
  }

  void _reload() => setState(() => _future = _load());

  void _setFilter(String status) {
    setState(() {
      _statusFilter = status;
      _future = _load();
    });
  }

  Future<void> _openOrder(Order order) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(orderId: order.id!),
      ),
    );
    // A cancel on the detail screen changes this list, so refresh on return.
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: Column(
        children: <Widget>[
          _FilterBar(selected: _statusFilter, onSelect: _setFilter),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: AsyncView<List<Order>>(
                future: _future,
                builder: (List<Order> orders) {
                  if (orders.isEmpty) {
                    return _emptyList();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) => _OrderCard(
                      order: orders[i],
                      onTap: () => _openOrder(orders[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyList() {
    // Wrapped in a scroll view so pull-to-refresh still works when empty.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: _statusFilter.isEmpty
                  ? 'No orders yet'
                  : 'No $_statusFilter orders',
              message: _statusFilter.isEmpty
                  ? 'When you place an order it will show up here so you can '
                      'track it.'
                  : 'Try a different filter to see your other orders.',
              actionLabel: _statusFilter.isEmpty ? 'Start shopping' : null,
              onAction: _statusFilter.isEmpty ? widget.onStartShopping : null,
            ),
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final List<String> options = <String>['', ...OrderStatus.all];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int i) {
          final String value = options[i];
          final bool active = value == selected;
          return Center(
            child: ChoiceChip(
              label: Text(value.isEmpty ? 'All' : value),
              selected: active,
              onSelected: (_) => onSelect(value),
              showCheckmark: false,
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                side: BorderSide(
                  color: active ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(order.orderCode,
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(Formats.date(order.placedAt), style: AppText.tiny),
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
            const Divider(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                const Icon(Icons.shopping_bag_outlined,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                  style: AppText.small,
                ),
                const Spacer(),
                Text(Formats.money(order.total), style: AppText.price),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
