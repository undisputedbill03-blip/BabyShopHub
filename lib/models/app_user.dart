import '../core/db_utils.dart';
import '../core/statuses.dart';

/// A registered account. Named `AppUser` rather than `User` to avoid any
/// clash with framework or plugin types.
class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String phone;
  final String role;
  final bool isActive;
  final String createdAt;

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    this.phone = '',
    this.role = UserRole.customer,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  /// First letter of the name, for the avatar circle.
  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: asIntOrNull(map['id']),
      name: asString(map['name']),
      email: asString(map['email']),
      passwordHash: asString(map['password_hash']),
      passwordSalt: asString(map['password_salt']),
      phone: asString(map['phone']),
      role: asString(map['role'], UserRole.customer),
      isActive: asBool(map['is_active'], true),
      createdAt: asString(map['created_at']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'phone': phone,
      'role': role,
      'is_active': boolToInt(isActive),
      'created_at': createdAt,
    };
  }

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    String? phone,
    String? role,
    bool? isActive,
    String? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
