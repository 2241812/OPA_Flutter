import 'package:hive/hive.dart';

/// Authentication method for an SSH connection.
///
/// Indexed values are used by the manual Hive adapter in
/// `lib/services/hive_adapters.dart` (do NOT use code-gen annotations here —
/// those would require build_runner and a generated .g.dart part file).
enum AuthType {
  password,
  publicKey,
  passwordAndPublicKey,
}

/// A saved SSH connection profile.
///
/// Serialized by [ConnectionProfileAdapter] (manual Hive TypeAdapter).
/// Extending [HiveObject] gives us `save()`/`delete()` helpers, but no
/// code-gen annotations are used.
class ConnectionProfile extends HiveObject {
  String id;
  String label;
  String host;
  int port;
  String username;
  AuthType authType;
  String? password; // null for key-only auth
  String? keyId; // Reference to SSHKeyPair.id; null for password-only auth
  int colorIndex; // Index into a predefined color palette
  DateTime createdAt;
  DateTime updatedAt;
  bool lastConnectionSuccess; // Green/red indicator on home screen

  ConnectionProfile({
    required this.id,
    required this.label,
    required this.host,
    required this.port,
    required this.username,
    required this.authType,
    this.password,
    this.keyId,
    this.colorIndex = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastConnectionSuccess = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ConnectionProfile copyWith({
    String? label,
    String? host,
    int? port,
    String? username,
    AuthType? authType,
    String? password,
    String? keyId,
    int? colorIndex,
    bool? lastConnectionSuccess,
  }) {
    return ConnectionProfile(
      id: id,
      label: label ?? this.label,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      password: password ?? this.password,
      keyId: keyId ?? this.keyId,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastConnectionSuccess:
          lastConnectionSuccess ?? this.lastConnectionSuccess,
    );
  }

  /// Display-friendly representation, e.g. "user@host:22"
  String get displayName => '$username@$host';

  /// Short label for chips/cards, e.g. "My PC"
  String get shortLabel => label.isNotEmpty ? label : displayName;
}
