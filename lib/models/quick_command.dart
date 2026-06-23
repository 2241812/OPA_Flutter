import 'package:hive/hive.dart';

/// A saved shell command for quick execution.
///
/// Serialized by [QuickCommandAdapter] (manual Hive TypeAdapter).
class QuickCommand extends HiveObject {
  String id;
  String label;
  String command;
  String? profileId; // Optional — if null, user picks at runtime
  int colorIndex;
  DateTime createdAt;

  QuickCommand({
    required this.id,
    required this.label,
    required this.command,
    this.profileId,
    this.colorIndex = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  QuickCommand copyWith({
    String? label,
    String? command,
    String? profileId,
    int? colorIndex,
  }) {
    return QuickCommand(
      id: id,
      label: label ?? this.label,
      command: command ?? this.command,
      profileId: profileId ?? this.profileId,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
    );
  }
}
