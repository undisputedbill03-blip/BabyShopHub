import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/admin_repository.dart';
import '../../widgets/widgets.dart';

/// The admin landing screen: headline numbers, a revenue figure and a
/// breakdown of orders by status. Read-only — every figure comes from
/// [AdminRepository.stats] in a single pass.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminRepository _admin = AdminRepository();
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final AdminStats stats = await _admin.stats();
    final List<StatusCount> byStatus = await _admin.ordersByStatus();
    return _DashboardData(stats: stats, byStatus: byStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: AsyncView<_DashboardData>(
          future: _future,
          builder: (_DashboardData data) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              _RevenueCard(revenue: data.stats.totalRevenue,
                  orders: data.stats.orderCount),
              const SizedBox(height: AppSpacing.lg),
              _StatGrid(stats: data.stats),
              const SizedBox(height: AppSpacing.xl),
              const Text('Orders by status', style: AppText.h3),
              const SizedBox(height: AppSpacing.md),
              _StatusBreakdown(rows: data.byStatus),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double revenue;
  final int orders;

  const _RevenueCard({required this.revenue, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Total revenue',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            Formats.money(revenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text('across $orders order${orders == 1 ? '' : 's'} (excludes cancelled)',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final AdminStats stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final List<_Stat> tiles = <_Stat>[
      _Stat('Orders today', '${stats.ordersToday}', Icons.today_outlined,
          AppColors.accent),
      _Stat('Pending orders', '${stats.pendingOrderCount}',
          Icons.schedule_outlined, AppColors.warning),
      _Stat('Active products', '${stats.activeProductCount}',
          Icons.inventory_2_outlined, AppColors.primary),
      _Stat('Out of stock', '${stats.outOfStockCount}',
          Icons.remove_shopping_cart_outlined, AppColors.danger),
      _Stat('Low stock', '${stats.lowStockCount}',
          Icons.trending_down, AppColors.warning),
      _Stat('Customers', '${stats.customerCount}', Icons.people_outline,
          AppColors.accent),
      _Stat('Open tickets', '${stats.openTicketCount}',
          Icons.support_agent_outlined, AppColors.primaryDark),
      _Stat('All products', '${stats.productCount}', Icons.category_outlined,
          AppColors.textSecondary),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.7,
      children: <Widget>[for (final _Stat s in tiles) _StatTile(stat: s)],
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(stat.icon, color: stat.color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(stat.value,
                  style: AppText.h2.copyWith(color: stat.color)),
              Text(stat.label, style: AppText.tiny),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final List<StatusCount> rows;
  const _StatusBreakdown({required this.rows});

  @override
  Widget build(BuildContext context) {
    final int max = rows.fold<int>(
        1, (int m, StatusCount r) => r.count > m ? r.count : m);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Column(
        children: <Widget>[
          for (final StatusCount row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 110,
                    child: Text(row.status, style: AppText.small),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: row.count / max,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            OrderStatus.color(row.status)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text('${row.count}',
                        textAlign: TextAlign.end,
                        style: AppText.small
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardData {
  final AdminStats stats;
  final List<StatusCount> byStatus;

  const _DashboardData({required this.stats, required this.byStatus});
}
