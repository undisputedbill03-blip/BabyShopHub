import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

/// The signed-in customer's home container: five tabs behind a bottom bar.
///
/// The tab screens are kept alive with an [IndexedStack] so scrolling the
/// home feed, opening the cart and coming back does not rebuild and reset the
/// scroll position.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  /// Lets a child tab (e.g. an empty cart's "start shopping" button) switch
  /// the shell to another tab.
  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final int cartCount = context.watch<CartProvider>().unitCount;

    final List<Widget> tabs = <Widget>[
      HomeScreen(onSeeAllCategories: () => _goTo(1), onGoToCart: () => _goTo(2)),
      const CategoriesScreen(),
      CartScreen(onStartShopping: () => _goTo(0)),
      OrdersScreen(onStartShopping: () => _goTo(0)),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        destinations: <Widget>[
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: AppColors.primary),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: _CartIcon(count: cartCount, filled: false),
            selectedIcon: _CartIcon(count: cartCount, filled: true),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

/// The cart icon with a badge showing how many units are in the basket.
class _CartIcon extends StatelessWidget {
  final int count;
  final bool filled;

  const _CartIcon({required this.count, required this.filled});

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(
      filled ? Icons.shopping_cart : Icons.shopping_cart_outlined,
      color: filled ? AppColors.primary : null,
    );
    if (count == 0) return icon;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.primary,
      child: icon,
    );
  }
}
