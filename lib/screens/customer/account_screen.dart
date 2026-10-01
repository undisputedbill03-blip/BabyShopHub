import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'address_list_screen.dart';
import 'edit_profile_screen.dart';
import 'faq_screen.dart';
import 'payment_methods_screen.dart';
import 'support_list_screen.dart';

/// The account tab: profile header, links to the personal areas, and sign out.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to shop.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
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
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          _ProfileHeader(user: user),
          const SizedBox(height: AppSpacing.xl),
          _MenuGroup(
            title: 'Shopping',
            tiles: <Widget>[
              _MenuTile(
                icon: Icons.location_on_outlined,
                label: 'Delivery addresses',
                subtitle: 'Manage where your orders are sent',
                onTap: () => _push(context, const AddressListScreen()),
              ),
              _MenuTile(
                icon: Icons.credit_card_outlined,
                label: 'Payment methods',
                subtitle: 'Saved cards for faster checkout',
                onTap: () => _push(context, const PaymentMethodsScreen()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _MenuGroup(
            title: 'Profile',
            tiles: <Widget>[
              _MenuTile(
                icon: Icons.person_outline,
                label: 'Edit profile',
                subtitle: 'Name, phone and password',
                onTap: () => _push(context, const EditProfileScreen()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _MenuGroup(
            title: 'Support',
            tiles: <Widget>[
              _MenuTile(
                icon: Icons.support_agent_outlined,
                label: 'Help & support',
                subtitle: 'Message us and track your requests',
                onTap: () => _push(context, const SupportListScreen()),
              ),
              _MenuTile(
                icon: Icons.help_outline,
                label: 'FAQs',
                subtitle: 'Answers to common questions',
                onTap: () => _push(context, const FaqScreen()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Center(
            child: Text('${AppConfig.appName}  ·  v1.0.0',
                style: AppText.tiny),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AppUser? user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(color: AppColors.primarySoft),
      child: Row(
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user?.initial ?? '?',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(user?.name ?? 'Guest', style: AppText.h2),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: AppText.small),
                if (user?.phone.isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(user!.phone, style: AppText.small),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<Widget> tiles;

  const _MenuGroup({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(title, style: AppText.small),
        ),
        // The tiles sit on a Material so their tap ripple paints *above* the
        // card's white fill. Without it the ripple draws on the Scaffold
        // canvas underneath and is hidden by the fill ("ink splashes may be
        // invisible"). Clipping keeps the ripple inside the rounded corners.
        Container(
          decoration: AppDecorations.card(),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Column(children: tiles),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: AppText.tiny),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
