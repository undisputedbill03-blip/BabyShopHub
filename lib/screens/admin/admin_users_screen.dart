import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/admin_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// The people screen: every registered account, searchable and filterable by
/// role. An admin can suspend or restore an account here. The repository
/// refuses to suspend the last active administrator, so the shop can never be
/// locked out of its own back office.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminRepository _admin = AdminRepository();
  final TextEditingController _search = TextEditingController();

  late Future<List<AppUser>> _future;
  String _role = '';
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

  Future<List<AppUser>> _load() => _admin.users(query: _query, role: _role);

  void _reload() => setState(() => _future = _load());

  Future<void> _toggleActive(AppUser user) async {
    final String? error = await _admin.setUserActive(
      userId: user.id!,
      active: !user.isActive,
    );
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      showSnack(context,
          user.isActive ? 'Account suspended.' : 'Account restored.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
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
                label: 'Search by name or email',
                icon: Icons.search,
              ),
            ),
          ),
          _RoleFilter(
            selected: _role,
            onSelect: (String r) {
              setState(() {
                _role = r;
                _future = _load();
              });
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: AsyncView<List<AppUser>>(
                future: _future,
                builder: (List<AppUser> users) {
                  if (users.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No users',
                      message: 'Registered accounts appear here.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) => _UserCard(
                      user: users[i],
                      onToggleActive: () => _toggleActive(users[i]),
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

class _RoleFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _RoleFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final List<_RoleOption> options = <_RoleOption>[
      const _RoleOption('', 'Everyone'),
      const _RoleOption(UserRole.customer, 'Customers'),
      const _RoleOption(UserRole.admin, 'Admins'),
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int i) {
          final _RoleOption option = options[i];
          final bool active = option.value == selected;
          return Center(
            child: ChoiceChip(
              label: Text(option.label),
              selected: active,
              onSelected: (_) => onSelect(option.value),
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

class _RoleOption {
  final String value;
  final String label;
  const _RoleOption(this.value, this.label);
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onToggleActive;

  const _UserCard({required this.user, required this.onToggleActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor:
                user.isAdmin ? AppColors.accentSoft : AppColors.primarySoft,
            child: Text(
              user.initial,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w700,
                color: user.isAdmin ? AppColors.accent : AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(user.name,
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (user.isAdmin) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      const StatusPill(label: 'Admin', color: AppColors.accent),
                    ],
                    if (!user.isActive) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      const StatusPill(
                          label: 'Suspended', color: AppColors.danger),
                    ],
                  ],
                ),
                Text(user.email, style: AppText.tiny),
                Text('Joined ${Formats.date(user.createdAt)}',
                    style: AppText.tiny),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => onToggleActive(),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'toggle',
                child: Text(user.isActive ? 'Suspend account' : 'Restore access'),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
