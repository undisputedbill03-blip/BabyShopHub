import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/support_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'support_detail_screen.dart';
import 'support_new_screen.dart';

/// The customer's list of support tickets, most recently active first.
class SupportListScreen extends StatefulWidget {
  const SupportListScreen({super.key});

  @override
  State<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends State<SupportListScreen> {
  final SupportRepository _support = SupportRepository();
  late Future<List<SupportTicket>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SupportTicket>> _load() {
    final int userId = context.read<SessionProvider>().userId!;
    return _support.listForUser(userId);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _newTicket() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const SupportNewScreen()),
    );
    if (created == true) _reload();
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportDetailScreen(ticketId: ticket.id!),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTicket,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New request'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: AsyncView<List<SupportTicket>>(
          future: _future,
          builder: (List<SupportTicket> tickets) {
            if (tickets.isEmpty) {
              return _empty();
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
              itemCount: tickets.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int i) => _TicketCard(
                ticket: tickets[i],
                onTap: () => _openTicket(tickets[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: EmptyState(
              icon: Icons.support_agent_outlined,
              title: 'No requests yet',
              message: 'Have a question or a problem with an order? Send us a '
                  'message and we will help.',
              actionLabel: 'New request',
              onAction: _newTicket,
            ),
          ),
        );
      },
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
                      style: AppText.body
                          .copyWith(fontWeight: FontWeight.w700),
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
            Text('${ticket.category}  ·  ${Formats.relative(ticket.updatedAt)}',
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
