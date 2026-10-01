import '../core/db_utils.dart';
import '../core/statuses.dart';

/// A placed order.
///
/// The shipping address and the payment label are COPIED onto the order
/// rather than referenced by id. If the customer later edits or deletes the
/// saved address, historical orders must still show where the parcel
/// actually went.
class Order {
  final int? id;
  final String orderCode;
  final int userId;

  final String shipFullName;
  final String shipPhone;
  final String shipLine1;
  final String shipLine2;
  final String shipCity;
  final String shipState;
  final String shipPostalCode;

  final String paymentLabel;

  final double subtotal;
  final double shippingFee;
  final double tax;
  final double total;

  final String status;
  final String placedAt;
  final String updatedAt;

  /// Joined extras used by the admin order list.
  final String customerName;
  final int itemCount;

  /// Loaded on demand by the order detail screen.
  final List<OrderItem> items;
  final List<OrderEvent> events;

  const Order({
    this.id,
    required this.orderCode,
    required this.userId,
    required this.shipFullName,
    required this.shipPhone,
    required this.shipLine1,
    this.shipLine2 = '',
    required this.shipCity,
    required this.shipState,
    required this.shipPostalCode,
    required this.paymentLabel,
    required this.subtotal,
    required this.shippingFee,
    required this.tax,
    required this.total,
    this.status = OrderStatus.pending,
    required this.placedAt,
    required this.updatedAt,
    this.customerName = '',
    this.itemCount = 0,
    this.items = const <OrderItem>[],
    this.events = const <OrderEvent>[],
  });

  String get shippingOneLine {
    final List<String> parts = <String>[
      shipLine1,
      if (shipLine2.trim().isNotEmpty) shipLine2,
      shipCity,
      '$shipState $shipPostalCode'.trim(),
    ];
    return parts.where((String p) => p.trim().isNotEmpty).join(', ');
  }

  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isFinal => OrderStatus.isFinal(status);

  /// A delivered order is the only one a customer may review items from.
  bool get canReview => isDelivered;

  factory Order.fromMap(Map<String, Object?> map) {
    return Order(
      id: asIntOrNull(map['id']),
      orderCode: asString(map['order_code']),
      userId: asInt(map['user_id']),
      shipFullName: asString(map['ship_full_name']),
      shipPhone: asString(map['ship_phone']),
      shipLine1: asString(map['ship_line1']),
      shipLine2: asString(map['ship_line2']),
      shipCity: asString(map['ship_city']),
      shipState: asString(map['ship_state']),
      shipPostalCode: asString(map['ship_postal_code']),
      paymentLabel: asString(map['payment_label']),
      subtotal: asDouble(map['subtotal']),
      shippingFee: asDouble(map['shipping_fee']),
      tax: asDouble(map['tax']),
      total: asDouble(map['total']),
      status: asString(map['status'], OrderStatus.pending),
      placedAt: asString(map['placed_at']),
      updatedAt: asString(map['updated_at']),
      customerName: asString(map['customer_name']),
      itemCount: asInt(map['item_count']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'order_code': orderCode,
      'user_id': userId,
      'ship_full_name': shipFullName,
      'ship_phone': shipPhone,
      'ship_line1': shipLine1,
      'ship_line2': shipLine2,
      'ship_city': shipCity,
      'ship_state': shipState,
      'ship_postal_code': shipPostalCode,
      'payment_label': paymentLabel,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'tax': tax,
      'total': total,
      'status': status,
      'placed_at': placedAt,
      'updated_at': updatedAt,
    };
  }

  Order copyWith({
    String? status,
    String? updatedAt,
    List<OrderItem>? items,
    List<OrderEvent>? events,
    String? customerName,
    int? itemCount,
  }) {
    return Order(
      id: id,
      orderCode: orderCode,
      userId: userId,
      shipFullName: shipFullName,
      shipPhone: shipPhone,
      shipLine1: shipLine1,
      shipLine2: shipLine2,
      shipCity: shipCity,
      shipState: shipState,
      shipPostalCode: shipPostalCode,
      paymentLabel: paymentLabel,
      subtotal: subtotal,
      shippingFee: shippingFee,
      tax: tax,
      total: total,
      status: status ?? this.status,
      placedAt: placedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      itemCount: itemCount ?? this.itemCount,
      items: items ?? this.items,
      events: events ?? this.events,
    );
  }
}

/// One product line inside an order.
///
/// Name, brand, image and unit price are SNAPSHOTS taken when the order was
/// placed. If an admin later renames a product or changes its price, the
/// customer's receipt must not silently change with it.
class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final String productName;
  final String brand;
  final String imagePath;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.brand,
    this.imagePath = '',
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItem.fromMap(Map<String, Object?> map) {
    return OrderItem(
      id: asIntOrNull(map['id']),
      orderId: asInt(map['order_id']),
      productId: asInt(map['product_id']),
      productName: asString(map['product_name']),
      brand: asString(map['brand']),
      imagePath: asString(map['image_path']),
      unitPrice: asDouble(map['unit_price']),
      quantity: asInt(map['quantity'], 1),
      lineTotal: asDouble(map['line_total']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'brand': brand,
      'image_path': imagePath,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
    };
  }
}

/// One entry in an order's tracking timeline.
class OrderEvent {
  final int? id;
  final int orderId;
  final String status;
  final String note;
  final String createdAt;

  const OrderEvent({
    this.id,
    required this.orderId,
    required this.status,
    this.note = '',
    required this.createdAt,
  });

  factory OrderEvent.fromMap(Map<String, Object?> map) {
    return OrderEvent(
      id: asIntOrNull(map['id']),
      orderId: asInt(map['order_id']),
      status: asString(map['status']),
      note: asString(map['note']),
      createdAt: asString(map['created_at']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'order_id': orderId,
      'status': status,
      'note': note,
      'created_at': createdAt,
    };
  }
}
