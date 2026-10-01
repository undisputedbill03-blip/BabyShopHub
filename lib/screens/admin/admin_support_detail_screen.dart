import 'package:flutter/material.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/support_repository.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// The admin side of one support conversation.
///
/// The bubbles mirror the customer screen: here the admin is "Support", so
/// support messages sit on the right and the customer's on the left. A reply
/// moves an open ticket to "in progress"; the status menu lets the admin
/// resolve, close or reopen it directly.
class AdminSupportDetailScreen extends StatefulWidget {
  final int ticketId;

  const AdminSupportDetailScreen({super.key, required this.ticketId});

  @override
  State<AdminSupportDetailScreen> createState() =>
      _AdminSupportDetailScreenState();
}

class _AdminSupportDetailScreenState extends State<AdminSupportDetailScreen> {
  final SupportRepository _support = SupportRepository();
  final TextEditingController _reply = TextEditingController();
  late Future<SupportTicket?> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<SupportTicket?> _load() => _support.byId(widget.ticketId);

  void _reload() => setState(() => _future = _load());

  Future<void> _send() async {
    final String body = _reply.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);
    final String? error = await _support.supportReply(
      ticketId: widget.ticketId,
      staffName: 'Support',
      message: body,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _reply.clear();
      _reload();
    } else {
      showSnack(context, error, error: true);
    }
  }

  Future<void> _setStatus(String status) async {
    final String? error =
        await _support.setStatus(ticketId: widget.ticketId, status: status);
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      showSnack(context, 'Marked as $status.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support ticket'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _setStatus,
            icon: const Icon(Icons.flag_outlined),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              for (final String status in TicketStatus.all)
                PopupMenuItem<String>(
                  value: status,
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.circle,
                          size: 12, color: TicketStatus.color(status)),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Mark $status'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: AsyncView<SupportTicket?>(
        future: _future,
        builder: (SupportTicket? ticket) {
          if (ticket == null) {
            return const EmptyState(
              icon: Icons.help_outline,
              title: 'Ticket not found',
              message: 'This support ticket could not be located.',
            );
          }
          return _conversation(ticket);
        },
      ),
    );
  }

  Widget _conversation(SupportTicket ticket) {
    final bool closed = ticket.status == TicketStatus.closed;
    return Column(
      children: <Widget>[
        _Header(ticket: ticket),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: ticket.messages.length,
            itemBuilder: (BuildContext context, int i) =>
                _MessageBubble(message: ticket.messages[i]),
          ),
        ),
        if (closed)
          _ClosedNote(onReopen: () => _setStatus(TicketStatus.open))
        else
          _ReplyBar(
            controller: _reply,
            sending: _sending,
            onSend: _send,
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final SupportTicket ticket;
  const _Header({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(ticket.subject, style: AppText.h3)),
              StatusPill(
                  label: ticket.status,
                  color: TicketStatus.color(ticket.status)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
              '${ticket.userName}  ·  ${ticket.category}  ·  '
              'opened ${Formats.date(ticket.createdAt)}',
              style: AppText.tiny),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool fromSupport = message.isFromSupport;
    // On the admin screen the operator is "Support", so their own messages
    // sit on the right and the customer's on the left.
    final Alignment align =
        fromSupport ? Alignment.centerRight : Alignment.centerLeft;
    final Color bg = fromSupport ? AppColors.primarySoft : AppColors.surfaceAlt;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              fromSupport ? 'You · Support' : message.senderName,
              style: AppText.tiny.copyWith(
                fontWeight: FontWeight.w700,
                color: fromSupport ? AppColors.primaryDark : AppColors.accent,
              ),
            ),
            const SizedBox(height: 3),
            Text(message.message, style: AppText.body),
            const SizedBox(height: 3),
            Text(Formats.relative(message.createdAt), style: AppText.tiny),
          ],
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ReplyBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SendButton(sending: sending, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onSend;

  const _SendButton({required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: sending ? null : onSend,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: sending
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                )
              : const Icon(Icons.send, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ClosedNote extends StatelessWidget {
  final VoidCallback onReopen;
  const _ClosedNote({required this.onReopen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const Text('This ticket is closed.',
                style: AppText.small, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onReopen,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reopen ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
