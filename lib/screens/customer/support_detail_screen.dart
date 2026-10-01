import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formats.dart';
import '../../core/statuses.dart';
import '../../core/theme.dart';
import '../../data/support_repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// One support conversation: the messages so far and a box to reply.
class SupportDetailScreen extends StatefulWidget {
  final int ticketId;

  const SupportDetailScreen({super.key, required this.ticketId});

  @override
  State<SupportDetailScreen> createState() => _SupportDetailScreenState();
}

class _SupportDetailScreenState extends State<SupportDetailScreen> {
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

  Future<SupportTicket?> _load() {
    final int userId = context.read<SessionProvider>().userId!;
    return _support.byId(widget.ticketId, userId: userId);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _send() async {
    final String body = _reply.text.trim();
    if (body.isEmpty) return;

    final SessionProvider session = context.read<SessionProvider>();
    setState(() => _sending = true);
    final String? error = await _support.customerReply(
      ticketId: widget.ticketId,
      userId: session.userId!,
      userName: session.user?.name ?? 'Customer',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support request')),
      body: AsyncView<SupportTicket?>(
        future: _future,
        builder: (SupportTicket? ticket) {
          if (ticket == null) {
            return const EmptyState(
              icon: Icons.help_outline,
              title: 'Request not found',
              message: 'This support request could not be located.',
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
          _ClosedNote()
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
          Text('${ticket.category}  ·  opened ${Formats.date(ticket.createdAt)}',
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
    final Alignment align =
        fromSupport ? Alignment.centerLeft : Alignment.centerRight;
    final Color bg = fromSupport ? AppColors.surfaceAlt : AppColors.primarySoft;

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
              fromSupport ? '${message.senderName} · Support' : 'You',
              style: AppText.tiny.copyWith(
                fontWeight: FontWeight.w700,
                color: fromSupport ? AppColors.accent : AppColors.primaryDark,
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: const SafeArea(
        top: false,
        child: Text(
          'This request is closed. Please raise a new request if you still '
          'need help.',
          style: AppText.small,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
