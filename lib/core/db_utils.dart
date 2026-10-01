/// Defensive converters for values coming out of SQLite.
///
/// sqflite returns `Map<String, Object?>` where an INTEGER column can arrive
/// as `int`, a REAL as `double`, and anything nullable as `null`. Casting
/// directly (`map['price'] as double`) throws at runtime the moment a value
/// is not exactly the expected type. These helpers never throw.
library;

String asString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

int asInt(Object? value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double asDouble(Object? value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

/// SQLite has no boolean type; this project stores 1 / 0.
bool asBool(Object? value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  return asInt(value, fallback ? 1 : 0) == 1;
}

/// Converts a Dart bool back to the integer SQLite stores.
int boolToInt(bool value) => value ? 1 : 0;

/// Current time as an ISO-8601 string, the format every timestamp column
/// in this project uses.
String nowIso() => DateTime.now().toIso8601String();

/// The first column of the first row of a query result, as an `int`.
///
/// Aggregate queries (`SELECT COUNT(*) ...`, `SELECT SUM(quantity) ...`)
/// come back as a single row holding a single value. Returns `null` when the
/// query produced no rows at all, so the caller decides the fallback with
/// `?? 0` rather than this helper guessing one.
int? firstIntValue(List<Map<String, Object?>> rows) {
  if (rows.isEmpty) return null;
  final Map<String, Object?> first = rows.first;
  if (first.isEmpty) return null;
  return asIntOrNull(first.values.first);
}
