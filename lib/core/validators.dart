/// Reusable form-field validators.
///
/// Every validator returns `null` when the value is acceptable, or an error
/// message when it is not. That is exactly the contract Flutter's
/// `TextFormField.validator` expects.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? name(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 3) return 'Name must be at least 3 characters';
    if (v.length > 60) return 'Name must be 60 characters or fewer';
    return null;
  }

  static String? email(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    final RegExp re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!re.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// At least 8 characters, one letter and one digit.
  static String? password(String? value) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
      return 'Password must contain a letter';
    }
    if (!RegExp(r'\d').hasMatch(v)) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^[0-9+\-\s]{7,20}$').hasMatch(v)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? postalCode(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Postal code is required';
    if (!RegExp(r'^[A-Za-z0-9\s-]{3,12}$').hasMatch(v)) {
      return 'Enter a valid postal code';
    }
    return null;
  }

  /// Accepts a positive price such as "1299" or "1299.50".
  static String? price(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Price is required';
    final double? parsed = double.tryParse(v);
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Price must be greater than zero';
    if (parsed > 100000000) return 'Price is unrealistically high';
    return null;
  }

  /// Accepts a stock quantity of zero or more.
  static String? stock(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Stock quantity is required';
    final int? parsed = int.tryParse(v);
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 0) return 'Stock cannot be negative';
    return null;
  }

  /// Dummy card number check - length and digits only. This app never
  /// stores or transmits a real card number.
  static String? cardNumber(String? value) {
    final String v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return 'Card number is required';
    if (!RegExp(r'^\d{13,19}$').hasMatch(v)) {
      return 'Card number must be 13 to 19 digits';
    }
    return null;
  }

  static String? expiryMonth(String? value) {
    final int? m = int.tryParse((value ?? '').trim());
    if (m == null) return 'Month';
    if (m < 1 || m > 12) return '1-12';
    return null;
  }

  static String? expiryYear(String? value) {
    final int? y = int.tryParse((value ?? '').trim());
    if (y == null) return 'Year';
    final int current = DateTime.now().year;
    if (y < current || y > current + 25) return 'Invalid';
    return null;
  }
}
