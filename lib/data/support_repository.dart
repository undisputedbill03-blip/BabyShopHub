import 'package:sqflite/sqflite.dart';

import '../core/db_utils.dart';
import '../core/statuses.dart';
import '../models/models.dart';
import 'database_helper.dart';

/// The support desk: customers raise tickets and reply to them, support staff
/// (the admin) answer and change the status.
///
/// A ticket carries a short conversation. The list screens need each ticket's
/// message count and last line without loading every message, so those two
/// values are computed in the list query and read back through the joined
/// keys `message_count` and `last_message`.
class SupportRepository {
  SupportRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db => _helper.database;

  /// The list query. A correlated subquery counts the messages and a second
  /// one pulls the most recent line. Ordering by `updated_at` keeps a ticket
  /// that was just answered at the top of the list.
  static const String _selectTickets = '''
    SELECT t.*,
           (SELECT COUNT(*) FROM support_messages m
            WHERE m.ticket_id = t.id) AS message_count,
           (SELECT m.message FROM support_messages m
            WHERE m.ticket_id = t.id
            ORDER BY m.id DESC LIMIT 1) AS last_message
    FROM support_tickets t
  ''';

  // ------------------------------------------------------------ customer

  /// A customer's own tickets, most recently active first.
  Future<List<SupportTicket>> listForUser(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_selectTickets WHERE t.user_id = ? ORDER BY t.updated_at DESC, t.id DESC',
      <Object?>[userId],
    );
    return rows.map(SupportTicket.fromMap).toList();
  }

  /// One ticket with its whole conversation attached.
  ///
  /// When [userId] is given the ticket must belong to that customer, so a
  /// stale ticket id cannot open somebody else's conversation. The admin
  /// screens call this without a [userId].
  Future<SupportTicket?> byId(int ticketId, {int? userId}) async {
    final Database db = await _db;
    final List<Object?> args = <Object?>[ticketId];
    String where = 't.id = ?';
    if (userId != null) {
      where = '$where AND t.user_id = ?';
      args.add(userId);
    }
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_selectTickets WHERE $where LIMIT 1',
      args,
    );
    if (rows.isEmpty) return null;

    final List<Map<String, Object?>> messageRows = await db.query(
      'support_messages',
      where: 'ticket_id = ?',
      whereArgs: <Object?>[ticketId],
      orderBy: 'id ASC',
    );
    return SupportTicket.fromMap(rows.first).copyWith(
      messages: messageRows.map(SupportMessage.fromMap).toList(),
    );
  }

  /// Raises a new ticket and stores the first message in one transaction, so
  /// a ticket never exists with nothing said in it.
  Future<int> create({
    required int userId,
    required String userName,
    required String subject,
    required String category,
    required String firstMessage,
  }) async {
    final Database db = await _db;
    final String timestamp = nowIso();
    final String safeName = userName.trim().isEmpty ? 'Customer' : userName.trim();

    return db.transaction<int>((Transaction txn) async {
      final int ticketId = await txn.insert('support_tickets', <String, Object?>{
        'user_id': userId,
        'user_name': safeName,
        'subject': subject.trim(),
        'category': category,
        'status': TicketStatus.open,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await txn.insert('support_messages', <String, Object?>{
        'ticket_id': ticketId,
        'sender_role': SenderRole.customer,
        'sender_name': safeName,
        'message': firstMessage.trim(),
        'created_at': timestamp,
      });
      return ticketId;
    });
  }

  /// A customer adding a reply to their own ticket.
  ///
  /// A reply reopens a ticket the support side had marked resolved — the
  /// customer clearly is not finished — but a fully closed ticket stays
  /// closed and refuses new messages.
  Future<String?> customerReply({
    required int ticketId,
    required int userId,
    required String userName,
    required String message,
  }) async {
    final String body = message.trim();
    if (body.isEmpty) return 'Please type a message before sending.';

    final Database db = await _db;
    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'support_tickets',
        columns: <String>['status'],
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[ticketId, userId],
        limit: 1,
      );
      if (rows.isEmpty) return 'That ticket was not found.';
      if (asString(rows.first['status']) == TicketStatus.closed) {
        return 'This ticket is closed. Please raise a new one.';
      }

      final String timestamp = nowIso();
      await txn.insert('support_messages', <String, Object?>{
        'ticket_id': ticketId,
        'sender_role': SenderRole.customer,
        'sender_name': userName.trim().isEmpty ? 'Customer' : userName.trim(),
        'message': body,
        'created_at': timestamp,
      });
      // A customer replying to a resolved ticket puts it back in the queue.
      await txn.update(
        'support_tickets',
        <String, Object?>{'status': TicketStatus.open, 'updated_at': timestamp},
        where: 'id = ? AND status = ?',
        whereArgs: <Object?>[ticketId, TicketStatus.resolved],
      );
      // Any other status just gets its activity time bumped.
      await txn.update(
        'support_tickets',
        <String, Object?>{'updated_at': timestamp},
        where: 'id = ? AND status != ?',
        whereArgs: <Object?>[ticketId, TicketStatus.resolved],
      );
      return null;
    });
  }

  // ------------------------------------------------------------ admin

  /// Every ticket in the shop, for the admin support screen.
  Future<List<SupportTicket>> listAll({
    String status = '',
    String query = '',
  }) async {
    final Database db = await _db;
    final List<String> where = <String>[];
    final List<Object?> args = <Object?>[];

    if (status.isNotEmpty) {
      where.add('t.status = ?');
      args.add(status);
    }
    final String term = query.trim();
    if (term.isNotEmpty) {
      where.add('(t.subject LIKE ? OR t.user_name LIKE ?)');
      final String pattern = '%$term%';
      args..add(pattern)..add(pattern);
    }

    final String filter = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_selectTickets $filter ORDER BY t.updated_at DESC, t.id DESC',
      args,
    );
    return rows.map(SupportTicket.fromMap).toList();
  }

  /// Support answering a ticket. Sending a reply moves an open ticket to
  /// "in progress" so the queue shows it has been picked up.
  Future<String?> supportReply({
    required int ticketId,
    required String staffName,
    required String message,
  }) async {
    final String body = message.trim();
    if (body.isEmpty) return 'Please type a reply before sending.';

    final Database db = await _db;
    return db.transaction<String?>((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        'support_tickets',
        columns: <String>['status'],
        where: 'id = ?',
        whereArgs: <Object?>[ticketId],
        limit: 1,
      );
      if (rows.isEmpty) return 'That ticket no longer exists.';

      final String timestamp = nowIso();
      await txn.insert('support_messages', <String, Object?>{
        'ticket_id': ticketId,
        'sender_role': SenderRole.support,
        'sender_name': staffName.trim().isEmpty ? 'Support' : staffName.trim(),
        'message': body,
        'created_at': timestamp,
      });

      // An open ticket that just got its first answer is now being handled.
      final String current = asString(rows.first['status']);
      final String nextStatus =
          current == TicketStatus.open ? TicketStatus.inProgress : current;
      await txn.update(
        'support_tickets',
        <String, Object?>{'status': nextStatus, 'updated_at': timestamp},
        where: 'id = ?',
        whereArgs: <Object?>[ticketId],
      );
      return null;
    });
  }

  /// Support changing a ticket's status directly (resolve, close, reopen).
  Future<String?> setStatus({
    required int ticketId,
    required String status,
  }) async {
    if (!TicketStatus.all.contains(status)) {
      return 'That is not a valid ticket status.';
    }
    final Database db = await _db;
    final int changed = await db.update(
      'support_tickets',
      <String, Object?>{'status': status, 'updated_at': nowIso()},
      where: 'id = ?',
      whereArgs: <Object?>[ticketId],
    );
    return changed == 0 ? 'That ticket no longer exists.' : null;
  }

  /// Count of tickets still needing attention, for the admin dashboard badge.
  Future<int> openCount() async {
    final Database db = await _db;
    return firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM support_tickets WHERE status IN (?, ?)',
          <Object?>[TicketStatus.open, TicketStatus.inProgress],
        )) ??
        0;
  }
}
