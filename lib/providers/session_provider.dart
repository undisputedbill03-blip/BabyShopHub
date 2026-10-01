import 'package:flutter/foundation.dart';

import '../core/statuses.dart';
import '../data/auth_repository.dart';
import '../models/models.dart';

/// The signed-in account, shared across the whole app.
///
/// Screens read this to decide what to show. Only registered users reach the
/// shop, the cart, checkout and the account area — the brief's "only
/// registered users can access certain features" — and only an admin account
/// reaches the admin panel. Those two questions are answered here, in one
/// place, so no screen has to reinvent the check.
class SessionProvider extends ChangeNotifier {
  SessionProvider({AuthRepository? auth})
      : _auth = auth ?? AuthRepository();

  final AuthRepository _auth;

  AppUser? _user;
  bool _restoring = true;
  bool _busy = false;

  AppUser? get user => _user;

  /// True while the app is still checking for a saved session at startup, so
  /// the splash screen knows to wait rather than flashing the login page.
  bool get restoring => _restoring;

  /// True while a login, registration or password change is in flight, so
  /// buttons can disable themselves and avoid a double submit.
  bool get busy => _busy;

  bool get isLoggedIn => _user != null;

  bool get isAdmin => _user?.role == UserRole.admin;

  int? get userId => _user?.id;

  AuthRepository get auth => _auth;

  /// Looks for a session left by a previous run. Called once at startup.
  Future<void> restore() async {
    _restoring = true;
    notifyListeners();
    _user = await _auth.restoreSession();
    _restoring = false;
    notifyListeners();
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final AuthResult result = await _auth.login(email: email, password: password);
      if (result.ok) {
        _user = result.user;
        await _auth.saveSession(result.user!.id!);
        notifyListeners();
      }
      return result;
    } finally {
      _setBusy(false);
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    _setBusy(true);
    try {
      final AuthResult result = await _auth.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      if (result.ok) {
        _user = result.user;
        await _auth.saveSession(result.user!.id!);
        notifyListeners();
      }
      return result;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    await _auth.clearSession();
    _user = null;
    notifyListeners();
  }

  /// Saves profile edits and refreshes the cached user so every screen shows
  /// the new name at once.
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    final int? id = _user?.id;
    if (id == null) return false;
    _setBusy(true);
    try {
      final AppUser? updated =
          await _auth.updateProfile(userId: id, name: name, phone: phone);
      if (updated != null) {
        _user = updated;
        notifyListeners();
        return true;
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final int? id = _user?.id;
    if (id == null) {
      return const AuthResult.failure('You are not signed in.');
    }
    _setBusy(true);
    try {
      final AuthResult result = await _auth.changePassword(
        userId: id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (result.ok) {
        _user = result.user;
        notifyListeners();
      }
      return result;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
