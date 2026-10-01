import '../core/db_utils.dart';
import '../core/statuses.dart';

/// A customer support request.
class SupportTicket {
  final int? id;
  final int userId;
  final String userName;
  final String subject;
  final String category;
  final String status;
  final String createdAt;
  final String updatedAt;

  /// Joined extras for the list screens.
  final int messageCount;
  final String lastMessage;

  /// Loaded on demand by the ticket detail screen.
  final List<SupportMessage> messages;

  const SupportTicket({
    this.id,
    required this.userId,
    required this.userName,
    required this.subject,
    this.category = 'General',
    this.status = TicketStatus.open,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessage = '',
    this.messages = const <SupportMessage>[],
  });

  bool get isClosed =>
      status == TicketStatus.closed || status == TicketStatus.resolved;

  factory SupportTicket.fromMap(Map<String, Object?> map) {
    return SupportTicket(
      id: asIntOrNull(map['id']),
      userId: asInt(map['user_id']),
      userName: asString(map['user_name'], 'Customer'),
      subject: asString(map['subject']),
      category: asString(map['category'], 'General'),
      status: asString(map['status'], TicketStatus.open),
      createdAt: asString(map['created_at']),
      updatedAt: asString(map['updated_at']),
      messageCount: asInt(map['message_count']),
      lastMessage: asString(map['last_message']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'user_id': userId,
      'user_name': userName,
      'subject': subject,
      'category': category,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  SupportTicket copyWith({
    String? status,
    String? updatedAt,
    List<SupportMessage>? messages,
  }) {
    return SupportTicket(
      id: id,
      userId: userId,
      userName: userName,
      subject: subject,
      category: category,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount,
      lastMessage: lastMessage,
      messages: messages ?? this.messages,
    );
  }

  /// Categories offered when raising a ticket.
  static const List<String> categories = <String>[
    'General',
    'Order issue',
    'Delivery',
    'Payment',
    'Product question',
    'Return or refund',
  ];
}

/// One message in a support conversation.
class SupportMessage {
  final int? id;
  final int ticketId;

  /// Either `SenderRole.customer` or `SenderRole.support`.
  final String senderRole;
  final String senderName;
  final String message;
  final String createdAt;

  const SupportMessage({
    this.id,
    required this.ticketId,
    required this.senderRole,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  bool get isFromSupport => senderRole == SenderRole.support;

  factory SupportMessage.fromMap(Map<String, Object?> map) {
    return SupportMessage(
      id: asIntOrNull(map['id']),
      ticketId: asInt(map['ticket_id']),
      senderRole: asString(map['sender_role'], SenderRole.customer),
      senderName: asString(map['sender_name']),
      message: asString(map['message']),
      createdAt: asString(map['created_at']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'ticket_id': ticketId,
      'sender_role': senderRole,
      'sender_name': senderName,
      'message': message,
      'created_at': createdAt,
    };
  }
}

/// A single frequently-asked question shown in the in-app help centre.
class FaqEntry {
  final String question;
  final String answer;

  const FaqEntry(this.question, this.answer);
}
