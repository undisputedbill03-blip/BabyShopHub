import 'app_config.dart';

/// Every money calculation in the app goes through here.
///
/// Checkout, the cart summary and the seeded demo orders all call these
/// methods, so a receipt can never disagree with the cart it came from, and
/// the worked example in the documentation cannot drift away from the code.
class Pricing {
  Pricing._();

  /// Rounds to two decimal places. Doubles cannot represent every decimal
  /// exactly, so 1234.5600000000002 is a real possibility after a few
  /// additions; rounding at each step keeps the displayed total honest.
  static double roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  /// Sum of every line in the cart.
  static double subtotalOf(Iterable<double> lineTotals) {
    double sum = 0;
    for (final double line in lineTotals) {
      sum += line;
    }
    return roundMoney(sum);
  }

  /// Delivery is free once the subtotal reaches the threshold.
  static double shippingFor(double subtotal) {
    if (subtotal <= 0) return 0;
    return subtotal >= AppConfig.freeShippingThreshold ? 0 : AppConfig.shippingFee;
  }

  static double taxFor(double subtotal) {
    return roundMoney(subtotal * AppConfig.taxRate);
  }

  static double totalFor(double subtotal) {
    return roundMoney(subtotal + shippingFor(subtotal) + taxFor(subtotal));
  }

  /// How much more the shopper must add to qualify for free delivery.
  /// Returns 0 once they already qualify.
  static double amountToFreeShipping(double subtotal) {
    final double gap = AppConfig.freeShippingThreshold - subtotal;
    return gap <= 0 ? 0 : roundMoney(gap);
  }
}
