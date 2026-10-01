import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/support_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'admin_support_detail_screen.dart';

/// The support queue. Every ticket in the shop, searchable and filterable by
/// status, ordered so the most recently active sits at the top. Tapping one
/// opens the conversation where the admin replies and changes its status.
class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final SupportRepository _support = SupportRepository();
  final TextEditingController _search = TextEditingController();

  late Future<List<SupportTicket>> _future;
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

  Future<List<SupportTicket>> _load() =>
      _support.listAll(status: _status, query: _query);

  void _reload() => setState(() => _future = _load());

  Future<void> _open(SupportTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminSupportDetailScreen(ticketId: ticket.id!),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
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
                label: 'Search subject or customer',
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
              child: AsyncView<List<SupportTicket>>(
                future: _future,
                builder: (List<SupportTicket> tickets) {
                  if (tickets.isEmpty) {
                    return const EmptyState(
                      icon: Icons.support_agent_outlined,
                      title: 'No tickets',
                      message: 'Customer support requests appear here.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) => _TicketCard(
                      ticket: tickets[i],
                      onTap: () => _open(tickets[i]),
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
    final List<String> options = <String>['', ...TicketStatus.all];
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

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

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
                  child: Text(ticket.subject,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusPill(
                    label: ticket.status,
                    color: TicketStatus.color(ticket.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                '${ticket.userName}  ·  ${ticket.category}  ·  '
                '${Formats.relative(ticket.updatedAt)}',
                style: AppText.tiny),
            if (ticket.lastMessage.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(ticket.lastMessage,
                  style: AppText.small,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}
