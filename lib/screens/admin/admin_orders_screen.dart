import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/order_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'admin_order_detail_screen.dart';

/// Every order in the shop, searchable and filterable by status. Tapping one
/// opens the detail screen where its status is advanced.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final OrderRepository _orders = OrderRepository();
  final TextEditingController _search = TextEditingController();

  late Future<List<Order>> _future;
  String _status = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Order>> _load() => _orders.listAll(status: _status, query: _query);

  void _reload() => setState(() => _future = _load());

  Future<void> _open(Order order) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminOrderDetailScreen(orderId: order.id!),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _search,
              onChanged: (String v) {
                _query = v;
                _reload();
              },
              decoration: AppInput.decoration(
                label: 'Search by code, name or email',
                icon: Icons.search,
              ),
            ),
          ),
          _StatusFilter(
            selected: _status,
            onSelect: (String s) {
              setState(() {
                _status = s;
                _future = _load();
              });
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: AsyncView<List<Order>>(
                future: _future,
                builder: (List<Order> orders) {
                  if (orders.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders',
                      message: 'Orders placed by customers appear here.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) => _OrderCard(
                      order: orders[i],
                      onTap: () => _open(orders[i]),
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
}

class _StatusFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _StatusFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final List<String> options = <String>['', ...OrderStatus.all];
    return SizedBox(
      height: 46,
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
                    color: active ? AppColors.primary : AppColors.border),
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
                      Text(order.customerName, style: AppText.tiny),
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
                Text(Formats.dateTime(order.placedAt), style: AppText.tiny),
                const Spacer(),
                Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                    style: AppText.small),
                const SizedBox(width: AppSpacing.md),
                Text(Formats.money(order.total), style: AppText.price),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
