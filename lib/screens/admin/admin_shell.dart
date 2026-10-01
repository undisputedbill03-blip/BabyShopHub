import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'admin_categories_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_support_screen.dart';
import 'admin_users_screen.dart';

/// The administrator's home container.
///
/// The four screens used most — the dashboard, orders, products and the
/// support queue — sit behind the bottom bar. Everything else (users,
/// categories, reviews and sign-out) lives on a fifth "More" tab, so the bar
/// stays readable while the whole back office is still one or two taps away.
///
/// Screens are kept alive in an [IndexedStack] so a half-typed search or a
/// scroll position survives switching tabs.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const List<Widget> tabs = <Widget>[
      AdminDashboardScreen(),
      AdminOrdersScreen(),
      AdminProductsScreen(),
      AdminSupportScreen(),
      _MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent, color: AppColors.primary),
            label: 'Support',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz, color: AppColors.primary),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

/// The "More" tab: the secondary management screens plus account controls.
class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to manage the shop.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await context.read<SessionProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<SessionProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          if (user != null) _AdminHeader(user: user),
          const SizedBox(height: AppSpacing.lg),
          _MenuTile(
            icon: Icons.people_outline,
            title: 'Users',
            subtitle: 'View accounts, suspend or restore access',
            onTap: () => _open(context, const AdminUsersScreen()),
          ),
          _MenuTile(
            icon: Icons.category_outlined,
            title: 'Categories',
            subtitle: 'Add, rename or remove product categories',
            onTap: () => _open(context, const AdminCategoriesScreen()),
          ),
          _MenuTile(
            icon: Icons.reviews_outlined,
            title: 'Reviews',
            subtitle: 'Moderate customer reviews',
            onTap: () => _open(context, const AdminReviewsScreen()),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final AppUser user;
  const _AdminHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.accentSoft,
            child: Text(
              user.initial,
              style: AppText.h3.copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(user.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                Text(user.email, style: AppText.tiny),
                const SizedBox(height: 2),
                const StatusPill(label: 'Administrator', color: AppColors.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppDecorations.card(),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                child: Icon(icon, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: AppText.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: AppText.tiny),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
