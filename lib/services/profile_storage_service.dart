import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/connection_profile.dart';
import '../models/quick_command.dart';
import '../utils/constants.dart';

/// Service for persisting connection profiles and quick commands to Hive.
class ProfileStorageService {
  final Box<ConnectionProfile> _profilesBox;
  final Box<QuickCommand> _commandsBox;

  ProfileStorageService(this._profilesBox, this._commandsBox);

  // --- Connection Profiles ---

  /// Get all saved connection profiles.
  List<ConnectionProfile> listProfiles() {
    return _profilesBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Get a profile by ID.
  ConnectionProfile? getProfile(String id) => _profilesBox.get(id);

  /// Save a new or updated connection profile.
  Future<void> saveProfile(ConnectionProfile profile) async {
    await _profilesBox.put(profile.id, profile);
  }

  /// Delete a connection profile.
  Future<void> deleteProfile(String id) async {
    await _profilesBox.delete(id);
  }

  /// Update the last connection success flag.
  Future<void> updateConnectionStatus(String id, bool success) async {
    final profile = _profilesBox.get(id);
    if (profile == null) return;
    final updated = profile.copyWith(lastConnectionSuccess: success);
    await _profilesBox.put(id, updated);
  }

  // --- Quick Commands ---

  /// Get all saved quick commands.
  List<QuickCommand> listCommands() {
    return _commandsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get commands associated with a specific profile.
  List<QuickCommand> listCommandsForProfile(String profileId) {
    return _commandsBox.values
        .where((c) => c.profileId == profileId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a command by ID.
  QuickCommand? getCommand(String id) => _commandsBox.get(id);

  /// Save a new or updated quick command.
  Future<void> saveCommand(QuickCommand command) async {
    await _commandsBox.put(command.id, command);
  }

  /// Delete a quick command.
  Future<void> deleteCommand(String id) async {
    await _commandsBox.delete(id);
  }
}

/// Provider for the profile storage service.
final profileStorageProvider = Provider<ProfileStorageService>((ref) {
  final profilesBox = Hive.box<ConnectionProfile>(AppConstants.profilesBox);
  final commandsBox = Hive.box<QuickCommand>(AppConstants.commandsBox);
  return ProfileStorageService(profilesBox, commandsBox);
});
