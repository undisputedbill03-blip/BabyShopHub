/// Central place for values you may want to change in one edit.
class AppConfig {
  AppConfig._();

  static const String appName = 'BabyShopHub';
  static const String tagline = 'Everything your little one needs';

  /// Currency symbol used everywhere in the UI.
  /// Change this ONE line to switch currency, e.g. r'$' or '₹' (rupee).
  static const String currencySymbol = '₦'; // Naira

  /// Flat delivery fee applied at checkout.
  static const double shippingFee = 1500.0;

  /// Orders at or above this subtotal ship free.
  static const double freeShippingThreshold = 50000.0;

  /// Tax applied to the subtotal at checkout (7.5%).
  static const double taxRate = 0.075;

  /// Database file name created on the device.
  static const String databaseName = 'babyshophub.db';

  /// Bump this when the schema changes so onUpgrade runs.
  static const int databaseVersion = 1;

  /// Seeded demo accounts, shown on the login screen for convenience.
  static const String demoCustomerEmail = 'parent@babyshophub.com';
  static const String demoCustomerPassword = 'Parent@123';
  static const String demoAdminEmail = 'admin@babyshophub.com';
  static const String demoAdminPassword = 'Admin@123';
}
