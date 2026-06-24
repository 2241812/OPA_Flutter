import 'package:hive/hive.dart';

import '../models/connection_profile.dart';
import '../models/stored_key_pair.dart';
import '../models/quick_command.dart';

/// Registers all Hive type adapters.
///
/// Call this before opening any boxes.
void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ConnectionProfileAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(StoredKeyPairAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(QuickCommandAdapter());
  }
}

// --- ConnectionProfile TypeAdapter ---

class ConnectionProfileAdapter extends TypeAdapter<ConnectionProfile> {
  @override
  final typeId = 0;

  @override
  ConnectionProfile read(BinaryReader reader) {
    return ConnectionProfile(
      id: reader.read(),
      label: reader.read(),
      host: reader.read(),
      port: reader.read(),
      username: reader.read(),
      authType: AuthType.values[reader.readByte()],
      password: reader.read() as String?,
      keyId: reader.read() as String?,
      colorIndex: reader.read(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      lastConnectionSuccess: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ConnectionProfile obj) {
    writer.write(obj.id);
    writer.write(obj.label);
    writer.write(obj.host);
    writer.write(obj.port);
    writer.write(obj.username);
    writer.writeByte(obj.authType.index);
    writer.write(obj.password);
    writer.write(obj.keyId);
    writer.write(obj.colorIndex);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.lastConnectionSuccess);
  }
}

// --- StoredKeyPair TypeAdapter ---

class StoredKeyPairAdapter extends TypeAdapter<StoredKeyPair> {
  @override
  final typeId = 1;

  @override
  StoredKeyPair read(BinaryReader reader) {
    return StoredKeyPair(
      id: reader.read(),
      label: reader.read(),
      keyType: KeyType.values[reader.readByte()],
      publicKey: reader.read(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, StoredKeyPair obj) {
    writer.write(obj.id);
    writer.write(obj.label);
    writer.writeByte(obj.keyType.index);
    writer.write(obj.publicKey);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}

// --- QuickCommand TypeAdapter ---

class QuickCommandAdapter extends TypeAdapter<QuickCommand> {
  @override
  final typeId = 2;

  @override
  QuickCommand read(BinaryReader reader) {
    final id = reader.read() as String;
    final label = reader.read() as String;
    final command = reader.read() as String;
    final profileId = reader.read() as String?;
    final colorIndex = reader.read() as int;
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    // presetId was added later — guard against older entries that don't
    // contain it so existing data still deserializes cleanly.
    String? presetId;
    try {
      if (reader.availableBytes > 0) {
        presetId = reader.read() as String?;
      }
    } catch (_) {
      presetId = null;
    }

    return QuickCommand(
      id: id,
      label: label,
      command: command,
      profileId: profileId,
      colorIndex: colorIndex,
      createdAt: createdAt,
      presetId: presetId,
    );
  }

  @override
  void write(BinaryWriter writer, QuickCommand obj) {
    writer.write(obj.id);
    writer.write(obj.label);
    writer.write(obj.command);
    writer.write(obj.profileId);
    writer.write(obj.colorIndex);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.write(obj.presetId);
  }
}
