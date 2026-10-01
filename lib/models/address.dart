import '../core/db_utils.dart';

/// A saved delivery address belonging to a user.
class Address {
  final int? id;
  final int userId;
  final String label;
  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  const Address({
    this.id,
    required this.userId,
    this.label = 'Home',
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    this.isDefault = false,
  });

  /// "12 Awolowo Road, Flat 4, Ikoyi, Lagos 101233"
  String get oneLine {
    final List<String> parts = <String>[
      line1,
      if (line2.trim().isNotEmpty) line2,
      city,
      '$state $postalCode'.trim(),
    ];
    return parts.where((String p) => p.trim().isNotEmpty).join(', ');
  }

  factory Address.fromMap(Map<String, Object?> map) {
    return Address(
      id: asIntOrNull(map['id']),
      userId: asInt(map['user_id']),
      label: asString(map['label'], 'Home'),
      fullName: asString(map['full_name']),
      phone: asString(map['phone']),
      line1: asString(map['line1']),
      line2: asString(map['line2']),
      city: asString(map['city']),
      state: asString(map['state']),
      postalCode: asString(map['postal_code']),
      isDefault: asBool(map['is_default']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'user_id': userId,
      'label': label,
      'full_name': fullName,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'is_default': boolToInt(isDefault),
    };
  }

  Address copyWith({
    int? id,
    int? userId,
    String? label,
    String? fullName,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  static const List<String> labelOptions = <String>['Home', 'Work', 'Other'];
}
