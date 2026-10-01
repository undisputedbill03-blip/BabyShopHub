import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Password hashing for the local account store.
///
/// Passwords are never written to the database in plain text. Each account
/// gets its own random salt, and only `sha256(salt + password)` is stored,
/// so two users who happen to choose the same password still end up with
/// different hashes and the stored value cannot be reversed by lookup.
///
/// An honest note for the report: SHA-256 is a fast hash, not a dedicated
/// password-derivation function. A production system would use bcrypt,
/// scrypt or Argon2, which are deliberately slow and therefore far more
/// expensive to attack offline. Those algorithms are out of scope for this
/// project, which keeps its dependency list to the packages the eProject
/// requires; the salt-per-user design here is the part that matters for the
/// requirement that credentials are not stored in readable form.
class PasswordService {
  PasswordService._();

  static final Random _random = Random.secure();

  /// Generates a fresh random salt, URL-safe base64 encoded.
  static String generateSalt([int byteLength = 16]) {
    final List<int> bytes =
        List<int>.generate(byteLength, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hashes [password] with [salt] and returns the hex digest.
  static String hash(String password, String salt) {
    final List<int> bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  /// Checks a login attempt against a stored salt and hash.
  ///
  /// The comparison walks the whole string instead of returning early on the
  /// first mismatch, so the time it takes does not leak how much of the hash
  /// was correct.
  static bool verify({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    final String actual = hash(password, salt);
    if (actual.length != expectedHash.length) return false;
    int difference = 0;
    for (int i = 0; i < actual.length; i++) {
      difference |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return difference == 0;
  }
}
