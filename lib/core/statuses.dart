import 'package:flutter/material.dart';

/// Order lifecycle used by both the customer tracking screen and the
/// admin order management screen.
///
/// The flow is deliberately linear:
///   Pending -> Confirmed -> Packed -> Shipped -> Out for delivery -> Delivered
/// with `Cancelled` reachable from any state before `Shipped`.
class OrderStatus {
  OrderStatus._();

  static const String pending = 'Pending';
  static const String confirmed = 'Confirmed';
  static const String packed = 'Packed';
  static const String shipped = 'Shipped';
  static const String outForDelivery = 'Out for delivery';
  static const String delivered = 'Delivered';
  static const String cancelled = 'Cancelled';

  /// The happy path, in order. Used to draw the tracking timeline.
  static const List<String> flow = <String>[
    pending,
    confirmed,
    packed,
    shipped,
    outForDelivery,
    delivered,
  ];

  static const List<String> all = <String>[
    pending,
    confirmed,
    packed,
    shipped,
    outForDelivery,
    delivered,
    cancelled,
  ];

  /// Statuses an admin is allowed to move an order to from [current].
  static List<String> nextOptions(String current) {
    if (current == delivered || current == cancelled) {
      return const <String>[];
    }
    final int index = flow.indexOf(current);
    final List<String> options = <String>[];
    if (index >= 0 && index < flow.length - 1) {
      options.add(flow[index + 1]);
    }
    // Cancelling is only sensible before the parcel has left the warehouse.
    if (index < flow.indexOf(shipped)) {
      options.add(cancelled);
    }
    return options;
  }

  /// True once the order can no longer change.
  static bool isFinal(String status) =>
      status == delivered || status == cancelled;

  /// How far along the flow an order is, from 0.0 to 1.0.
  static double progress(String status) {
    if (status == cancelled) return 0.0;
    final int index = flow.indexOf(status);
    if (index < 0) return 0.0;
    return (index + 1) / flow.length;
  }

  static IconData icon(String status) {
    switch (status) {
      case pending:
        return Icons.schedule;
      case confirmed:
        return Icons.check_circle_outline;
      case packed:
        return Icons.inventory_2_outlined;
      case shipped:
        return Icons.local_shipping_outlined;
      case outForDelivery:
        return Icons.directions_bike_outlined;
      case delivered:
        return Icons.home_outlined;
      case cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static Color color(String status) {
    switch (status) {
      case pending:
        return const Color(0xFFB98900);
      case confirmed:
        return const Color(0xFF2F7DD1);
      case packed:
        return const Color(0xFF6C4FB8);
      case shipped:
        return const Color(0xFF1E8E9E);
      case outForDelivery:
        return const Color(0xFF12806A);
      case delivered:
        return const Color(0xFF1B7A3D);
      case cancelled:
        return const Color(0xFFB3261E);
      default:
        return const Color(0xFF6B6B6B);
    }
  }

  /// A friendly sentence written into the tracking timeline.
  static String note(String status) {
    switch (status) {
      case pending:
        return 'Order placed and awaiting confirmation.';
      case confirmed:
        return 'Payment confirmed. We are preparing your items.';
      case packed:
        return 'Your items have been packed and labelled.';
      case shipped:
        return 'Parcel handed to the courier.';
      case outForDelivery:
        return 'The courier is on the way to your address.';
      case delivered:
        return 'Delivered. Thank you for shopping with us!';
      case cancelled:
        return 'Order cancelled and stock returned.';
      default:
        return '';
    }
  }
}

/// Status of a customer support ticket.
class TicketStatus {
  TicketStatus._();

  static const String open = 'Open';
  static const String inProgress = 'In progress';
  static const String resolved = 'Resolved';
  static const String closed = 'Closed';

  static const List<String> all = <String>[open, inProgress, resolved, closed];

  static Color color(String status) {
    switch (status) {
      case open:
        return const Color(0xFFB98900);
      case inProgress:
        return const Color(0xFF2F7DD1);
      case resolved:
        return const Color(0xFF1B7A3D);
      case closed:
        return const Color(0xFF6B6B6B);
      default:
        return const Color(0xFF6B6B6B);
    }
  }
}

/// Who wrote a support message.
class SenderRole {
  SenderRole._();
  static const String customer = 'customer';
  static const String support = 'support';
}

/// Account roles.
class UserRole {
  UserRole._();
  static const String customer = 'customer';
  static const String admin = 'admin';
}
