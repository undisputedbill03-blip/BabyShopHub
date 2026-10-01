import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/theme.dart';
import 'providers/providers.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/splash_screen.dart';

void main() {
  // Required before any plugin (sqflite) is touched, and before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BabyShopHubApp());
}

class BabyShopHubApp extends StatelessWidget {
  const BabyShopHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Bare list literal: Dart infers List<SingleChildWidget> from
      // MultiProvider.providers, so no provider-internal type is named here.
      providers: [
        // The session restores itself immediately, so the splash screen is
        // only shown for as long as reading the saved session id takes.
        ChangeNotifierProvider<SessionProvider>(
          create: (_) => SessionProvider()..restore(),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _RootGate(),
      ),
    );
  }
}

/// Decides what the user sees based on the session, in one place.
///
///   still restoring        -> splash
///   not signed in          -> login
///   signed in as an admin  -> admin panel
///   signed in as a customer-> the shop
///
/// It also keeps the shared cart pointed at the signed-in customer. That is
/// done in a post-frame callback so binding the cart (which notifies its
/// listeners) never runs during this widget's build.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  int? _boundUserId;
  bool _bindScheduled = false;

  void _syncCart(int? userId) {
    if (userId == _boundUserId && !_bindScheduled) return;
    _boundUserId = userId;
    _bindScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindScheduled = false;
      if (mounted) {
        context.read<CartProvider>().bindUser(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();
    _syncCart(session.userId);

    if (session.restoring) {
      return const SplashScreen();
    }
    if (!session.isLoggedIn) {
      return const LoginScreen();
    }
    if (session.isAdmin) {
      return const AdminShell();
    }
    return const CustomerShell();
  }
}
