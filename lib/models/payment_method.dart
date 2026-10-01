import '../core/db_utils.dart';

/// A saved payment method.
///
/// IMPORTANT: payment in this project is a simulation for the eProject
/// brief. Only the cardholder name, the brand and the LAST FOUR digits are
/// ever stored. The full card number is validated for shape, used to derive
/// those four digits, and then discarded. No CVV is stored at any point and
/// nothing is transmitted anywhere.
class PaymentMethod {
  final int? id;
  final int userId;
  final String cardHolder;
  final String cardBrand;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;

  const PaymentMethod({
    this.id,
    required this.userId,
    required this.cardHolder,
    required this.cardBrand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
  });

  String get expiryLabel {
    final String mm = expiryMonth < 10 ? '0$expiryMonth' : '$expiryMonth';
    final String yy = (expiryYear % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  bool get isExpired {
    final DateTime now = DateTime.now();
    if (expiryYear < now.year) return true;
    if (expiryYear == now.year && expiryMonth < now.month) return true;
    return false;
  }

  /// Label written onto the order record, e.g. "Visa ending 4242".
  String get orderLabel => '$cardBrand ending $last4';

  factory PaymentMethod.fromMap(Map<String, Object?> map) {
    return PaymentMethod(
      id: asIntOrNull(map['id']),
      userId: asInt(map['user_id']),
      cardHolder: asString(map['card_holder']),
      cardBrand: asString(map['card_brand'], 'Card'),
      last4: asString(map['last4']),
      expiryMonth: asInt(map['expiry_month'], 1),
      expiryYear: asInt(map['expiry_year'], DateTime.now().year),
      isDefault: asBool(map['is_default']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'user_id': userId,
      'card_holder': cardHolder,
      'card_brand': cardBrand,
      'last4': last4,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'is_default': boolToInt(isDefault),
    };
  }

  /// Guesses the card brand from the leading digits. Display only.
  static String brandFromNumber(String rawNumber) {
    final String n = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.isEmpty) return 'Card';
    if (n.startsWith('4')) return 'Visa';
    if (RegExp(r'^5[1-5]').hasMatch(n)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(n)) return 'Amex';
    if (n.startsWith('6')) return 'Discover';
    if (RegExp(r'^50|^65').hasMatch(n)) return 'Verve';
    return 'Card';
  }

  /// Extracts the last four digits that are safe to keep.
  static String last4FromNumber(String rawNumber) {
    final String n = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.length <= 4) return n;
    return n.substring(n.length - 4);
  }
}
