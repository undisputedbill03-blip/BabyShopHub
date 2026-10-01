import 'package:sqflite/sqflite.dart';

import '../core/db_utils.dart';
import '../core/statuses.dart';
import '../models/models.dart';
import 'database_helper.dart';
import 'password_service.dart';

/// The outcome of a sign-in or sign-up attempt.
///
/// Returning a result object rather than throwing keeps the screens simple:
/// there is exactly one thing to check and one message to show.
class AuthResult {
  final AppUser? user;
  final String? error;

  const AuthResult.success(AppUser this.user) : error = null;
  const AuthResult.failure(String this.error) : user = null;

  bool get ok => user != null;
}

/// Accounts, sessions, saved addresses and saved cards.
class AuthRepository {
  AuthRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  /// Key under which the signed-in user's id is kept in `app_state`.
  ///
  /// The session lives in the database rather than in shared_preferences so
  /// the project has one storage mechanism instead of two.
  static const String _sessionKey = 'session_user_id';

  Future<Database> get _db => _helper.database;

  // ------------------------------------------------------------ accounts

  /// Creates an account. Email is stored lower-cased and must be unique.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final Database db = await _db;
    final String normalised = email.trim().toLowerCase();

    final List<Map<String, Object?>> existing = await db.query(
      'users',
      columns: <String>['id'],
      where: 'email = ?',
      whereArgs: <Object?>[normalised],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return const AuthResult.failure(
          'An account already uses that email address.');
    }

    final String salt = PasswordService.generateSalt();
    final int id = await db.insert('users', <String, Object?>{
      'name': name.trim(),
      'email': normalised,
      'password_hash': PasswordService.hash(password, salt),
      'password_salt': salt,
      'phone': phone.trim(),
      'role': UserRole.customer,
      'is_active': 1,
      'created_at': nowIso(),
    });

    final AppUser? created = await findById(id);
    if (created == null) {
      return const AuthResult.failure(
          'The account could not be created. Please try again.');
    }
    return AuthResult.success(created);
  }

  /// Checks an email and password pair.
  ///
  /// The same message is returned whether the email is unknown or the
  /// password is wrong, so the screen cannot be used to discover which
  /// addresses have accounts.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: <Object?>[email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) {
      return const AuthResult.failure('Email or password is incorrect.');
    }

    final AppUser user = AppUser.fromMap(rows.first);
    final bool matches = PasswordService.verify(
      password: password,
      salt: user.passwordSalt,
      expectedHash: user.passwordHash,
    );
    if (!matches) {
      return const AuthResult.failure('Email or password is incorrect.');
    }
    if (!user.isActive) {
      return const AuthResult.failure(
          'This account has been suspended. Please contact support.');
    }
    return AuthResult.success(user);
  }

  Future<AppUser?> findById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  /// Updates the editable parts of a profile. The password, role and active
  /// flag are deliberately not touched here.
  Future<AppUser?> updateProfile({
    required int userId,
    required String name,
    required String phone,
  }) async {
    final Database db = await _db;
    await db.update(
      'users',
      <String, Object?>{'name': name.trim(), 'phone': phone.trim()},
      where: 'id = ?',
      whereArgs: <Object?>[userId],
    );
    return findById(userId);
  }

  /// Changes a password after re-checking the current one.
  ///
  /// A fresh salt is generated, so the stored hash changes completely even
  /// if the customer reuses a password they have had before.
  Future<AuthResult> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final AppUser? user = await findById(userId);
    if (user == null) {
      return const AuthResult.failure('That account no longer exists.');
    }
    final bool matches = PasswordService.verify(
      password: currentPassword,
      salt: user.passwordSalt,
      expectedHash: user.passwordHash,
    );
    if (!matches) {
      return const AuthResult.failure('Your current password is incorrect.');
    }

    final Database db = await _db;
    final String salt = PasswordService.generateSalt();
    await db.update(
      'users',
      <String, Object?>{
        'password_hash': PasswordService.hash(newPassword, salt),
        'password_salt': salt,
      },
      where: 'id = ?',
      whereArgs: <Object?>[userId],
    );

    final AppUser? updated = await findById(userId);
    if (updated == null) {
      return const AuthResult.failure('The password could not be changed.');
    }
    return AuthResult.success(updated);
  }

  // ------------------------------------------------------------ session

  Future<void> saveSession(int userId) =>
      _helper.writeState(_sessionKey, userId.toString());

  Future<void> clearSession() => _helper.clearState(_sessionKey);

  /// Returns the signed-in user if a session survives from a previous run.
  ///
  /// A suspended or deleted account clears the session rather than
  /// restoring it, so an admin can lock someone out even mid-session.
  Future<AppUser?> restoreSession() async {
    final String? raw = await _helper.readState(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    final int? id = int.tryParse(raw);
    if (id == null) {
      await clearSession();
      return null;
    }
    final AppUser? user = await findById(id);
    if (user == null || !user.isActive) {
      await clearSession();
      return null;
    }
    return user;
  }

  // ---------------------------------------------------------- addresses

  Future<List<Address>> addressesFor(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'addresses',
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'is_default DESC, id ASC',
    );
    return rows.map(Address.fromMap).toList();
  }

  Future<Address?> defaultAddressFor(int userId) async {
    final List<Address> all = await addressesFor(userId);
    if (all.isEmpty) return null;
    for (final Address a in all) {
      if (a.isDefault) return a;
    }
    return all.first;
  }

  /// Inserts or updates an address.
  ///
  /// The first address a customer saves becomes the default automatically,
  /// otherwise checkout would open with nothing selected.
  Future<int> saveAddress(Address address) async {
    final Database db = await _db;
    return db.transaction<int>((Transaction txn) async {
      final int existing = firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM addresses WHERE user_id = ?',
            <Object?>[address.userId],
          )) ??
          0;

      final bool shouldDefault = address.isDefault || existing == 0;
      final Map<String, Object?> values =
          address.copyWith(isDefault: shouldDefault).toMap();

      if (shouldDefault) {
        await txn.update(
          'addresses',
          <String, Object?>{'is_default': 0},
          where: 'user_id = ?',
          whereArgs: <Object?>[address.userId],
        );
      }

      if (address.id == null) {
        return txn.insert('addresses', values);
      }
      await txn.update(
        'addresses',
        values,
        where: 'id = ?',
        whereArgs: <Object?>[address.id],
      );
      return address.id!;
    });
  }

  Future<void> setDefaultAddress({
    required int userId,
    required int addressId,
  }) async {
    final Database db = await _db;
    await db.transaction((Transaction txn) async {
      await txn.update(
        'addresses',
        <String, Object?>{'is_default': 0},
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
      );
      await txn.update(
        'addresses',
        <String, Object?>{'is_default': 1},
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[addressId, userId],
      );
    });
  }

  /// Deletes an address and promotes another one if the default went with it.
  Future<void> deleteAddress({
    required int userId,
    required int addressId,
  }) async {
    final Database db = await _db;
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'addresses',
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[addressId, userId],
      );
      final int remainingDefaults = firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM addresses '
            'WHERE user_id = ? AND is_default = 1',
            <Object?>[userId],
          )) ??
          0;
      if (remainingDefaults > 0) return;

      final List<Map<String, Object?>> rows = await txn.query(
        'addresses',
        columns: <String>['id'],
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
        orderBy: 'id ASC',
        limit: 1,
      );
      if (rows.isEmpty) return;
      await txn.update(
        'addresses',
        <String, Object?>{'is_default': 1},
        where: 'id = ?',
        whereArgs: <Object?>[asInt(rows.first['id'])],
      );
    });
  }

  // ---------------------------------------------------- payment methods

  Future<List<PaymentMethod>> paymentMethodsFor(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'payment_methods',
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'is_default DESC, id ASC',
    );
    return rows.map(PaymentMethod.fromMap).toList();
  }

  Future<PaymentMethod?> defaultPaymentMethodFor(int userId) async {
    final List<PaymentMethod> all = await paymentMethodsFor(userId);
    if (all.isEmpty) return null;
    for (final PaymentMethod m in all) {
      if (m.isDefault) return m;
    }
    return all.first;
  }

  /// Saves a card. Only the brand and last four digits reach this method;
  /// the caller derives them and discards the number it was typed from.
  Future<int> savePaymentMethod(PaymentMethod method) async {
    final Database db = await _db;
    return db.transaction<int>((Transaction txn) async {
      final int existing = firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM payment_methods WHERE user_id = ?',
            <Object?>[method.userId],
          )) ??
          0;
      final bool shouldDefault = method.isDefault || existing == 0;

      if (shouldDefault) {
        await txn.update(
          'payment_methods',
          <String, Object?>{'is_default': 0},
          where: 'user_id = ?',
          whereArgs: <Object?>[method.userId],
        );
      }

      final Map<String, Object?> values = method.toMap();
      values['is_default'] = boolToInt(shouldDefault);

      if (method.id == null) {
        return txn.insert('payment_methods', values);
      }
      await txn.update(
        'payment_methods',
        values,
        where: 'id = ?',
        whereArgs: <Object?>[method.id],
      );
      return method.id!;
    });
  }

  Future<void> setDefaultPaymentMethod({
    required int userId,
    required int methodId,
  }) async {
    final Database db = await _db;
    await db.transaction((Transaction txn) async {
      await txn.update(
        'payment_methods',
        <String, Object?>{'is_default': 0},
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
      );
      await txn.update(
        'payment_methods',
        <String, Object?>{'is_default': 1},
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[methodId, userId],
      );
    });
  }

  Future<void> deletePaymentMethod({
    required int userId,
    required int methodId,
  }) async {
    final Database db = await _db;
    await db.transaction((Transaction txn) async {
      await txn.delete(
        'payment_methods',
        where: 'id = ? AND user_id = ?',
        whereArgs: <Object?>[methodId, userId],
      );
      final int remainingDefaults = firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM payment_methods '
            'WHERE user_id = ? AND is_default = 1',
            <Object?>[userId],
          )) ??
          0;
      if (remainingDefaults > 0) return;

      final List<Map<String, Object?>> rows = await txn.query(
        'payment_methods',
        columns: <String>['id'],
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
        orderBy: 'id ASC',
        limit: 1,
      );
      if (rows.isEmpty) return;
      await txn.update(
        'payment_methods',
        <String, Object?>{'is_default': 1},
        where: 'id = ?',
        whereArgs: <Object?>[asInt(rows.first['id'])],
      );
    });
  }
}
