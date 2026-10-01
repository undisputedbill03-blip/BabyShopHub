import 'app_config.dart';

/// Small formatting helpers.
///
/// Deliberately hand-written instead of using the `intl` package so the
/// project has one dependency less to resolve.
class Formats {
  Formats._();

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// 1234.5 -> "N1,234.50"
  static String money(double value) {
    final String fixed = value.toStringAsFixed(2);
    final int dot = fixed.indexOf('.');
    final String whole = fixed.substring(0, dot);
    final String fraction = fixed.substring(dot);
    return '${AppConfig.currencySymbol}${_group(whole)}$fraction';
  }

  /// 1234567 -> "1,234,567"
  static String _group(String digits) {
    final bool negative = digits.startsWith('-');
    final String body = negative ? digits.substring(1) : digits;
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < body.length; i++) {
      final int fromEnd = body.length - i;
      out.write(body[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        out.write(',');
      }
    }
    return negative ? '-${out.toString()}' : out.toString();
  }

  /// ISO string -> "19 Sep 2026"
  static String date(String iso) {
    final DateTime? d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';
  }

  /// ISO string -> "19 Sep 2026, 14:05"
  static String dateTime(String iso) {
    final DateTime? d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${date(iso)}, ${_two(d.hour)}:${_two(d.minute)}';
  }

  /// "3 days ago" style label used on reviews.
  static String relative(String iso) {
    final DateTime? d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final Duration diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return date(iso);
  }

  static String _two(int n) => n < 10 ? '0$n' : '$n';

  /// 4.25 -> "4.3"
  static String rating(double value) => value.toStringAsFixed(1);

  /// Masks a card number for display: "4242" -> "**** **** **** 4242".
  static String maskedCard(String last4) => '**** **** **** $last4';
}
