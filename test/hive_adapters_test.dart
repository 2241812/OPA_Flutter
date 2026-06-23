import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opa/models/connection_profile.dart';
import 'package:opa/models/quick_command.dart';
import 'package:opa/models/stored_key_pair.dart';
import 'package:opa/services/hive_adapters.dart';

void main() {
  setUpAll(() {
    registerHiveAdapters();
  });

  group('ConnectionProfileAdapter', () {
    test('round-trips a complete profile', () {
      final original = ConnectionProfile(
        id: 'profile-1',
        label: 'My PC',
        host: '192.168.1.100',
        port: 2222,
        username: 'admin',
        authType: AuthType.publicKey,
        password: 's3cret',
        keyId: 'key-1',
        colorIndex: 3,
        lastConnectionSuccess: true,
      );

      final restored = _roundTrip(original, ConnectionProfileAdapter());

      expect(restored.id, 'profile-1');
      expect(restored.label, 'My PC');
      expect(restored.host, '192.168.1.100');
      expect(restored.port, 2222);
      expect(restored.username, 'admin');
      expect(restored.authType, AuthType.publicKey);
      expect(restored.password, 's3cret');
      expect(restored.keyId, 'key-1');
      expect(restored.colorIndex, 3);
      expect(restored.lastConnectionSuccess, true);
    });

    test('round-trips null optional fields (password-only auth)', () {
      final original = ConnectionProfile(
        id: 'p2',
        label: 'Server',
        host: 'example.com',
        port: 22,
        username: 'root',
        authType: AuthType.password,
      );

      final restored = _roundTrip(original, ConnectionProfileAdapter());

      expect(restored.password, isNull);
      expect(restored.keyId, isNull);
      expect(restored.authType, AuthType.password);
    });

    test('round-trips all AuthType enum values', () {
      for (final authType in AuthType.values) {
        final original = ConnectionProfile(
          id: 'auth-test',
          label: 'L',
          host: 'h',
          port: 22,
          username: 'u',
          authType: authType,
        );
        final restored = _roundTrip(original, ConnectionProfileAdapter());
        expect(restored.authType, authType);
      }
    });

    test('preserves timestamps', () {
      final created = DateTime(2024, 1, 15, 10, 30);
      final updated = DateTime(2024, 6, 20, 14, 45);
      final original = ConnectionProfile(
        id: 'ts',
        label: 'l',
        host: 'h',
        port: 22,
        username: 'u',
        authType: AuthType.password,
        createdAt: created,
        updatedAt: updated,
      );

      final restored = _roundTrip(original, ConnectionProfileAdapter());

      expect(restored.createdAt, created);
      expect(restored.updatedAt, updated);
    });

    test('typeId is 0', () {
      expect(ConnectionProfileAdapter().typeId, 0);
    });
  });

  group('StoredKeyPairAdapter', () {
    test('round-trips an ed25519 key', () {
      final original = StoredKeyPair(
        id: 'key-1',
        label: 'Work Key',
        keyType: KeyType.ed25519,
        publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIexample work',
      );

      final restored = _roundTrip(original, StoredKeyPairAdapter());

      expect(restored.id, 'key-1');
      expect(restored.label, 'Work Key');
      expect(restored.keyType, KeyType.ed25519);
      expect(restored.publicKey, startsWith('ssh-ed25519 '));
    });

    test('round-trips an RSA key', () {
      final original = StoredKeyPair(
        id: 'key-2',
        label: 'Legacy RSA',
        keyType: KeyType.rsa,
        publicKey: 'ssh-rsa AAAAB3NzaC1yc2E... rsa',
      );

      final restored = _roundTrip(original, StoredKeyPairAdapter());

      expect(restored.keyType, KeyType.rsa);
      expect(restored.label, 'Legacy RSA');
    });

    test('typeId is 1', () {
      expect(StoredKeyPairAdapter().typeId, 1);
    });
  });

  group('QuickCommandAdapter', () {
    test('round-trips a command linked to a profile', () {
      final original = QuickCommand(
        id: 'cmd-1',
        label: 'Start Agent',
        command: 'python ~/agents/start.py',
        profileId: 'profile-1',
        colorIndex: 2,
      );

      final restored = _roundTrip(original, QuickCommandAdapter());

      expect(restored.id, 'cmd-1');
      expect(restored.label, 'Start Agent');
      expect(restored.command, 'python ~/agents/start.py');
      expect(restored.profileId, 'profile-1');
      expect(restored.colorIndex, 2);
    });

    test('round-trips a command with no profile link', () {
      final original = QuickCommand(
        id: 'cmd-2',
        label: 'Free Agent',
        command: 'uptime',
      );

      final restored = _roundTrip(original, QuickCommandAdapter());

      expect(restored.profileId, isNull);
    });

    test('round-trips multi-line commands', () {
      const multiLine = 'cd ~/project\n&& git pull\n&& ./deploy.sh';
      final original = QuickCommand(
        id: 'cmd-3',
        label: 'Deploy',
        command: multiLine,
      );

      final restored = _roundTrip(original, QuickCommandAdapter());

      expect(restored.command, multiLine);
    });

    test('typeId is 2', () {
      expect(QuickCommandAdapter().typeId, 2);
    });
  });

  group('registerHiveAdapters', () {
    test('registers all three adapters (idempotent)', () {
      registerHiveAdapters();
      expect(Hive.isAdapterRegistered(0), isTrue);
      expect(Hive.isAdapterRegistered(1), isTrue);
      expect(Hive.isAdapterRegistered(2), isTrue);
    });
  });
}

/// Serialize [value] through a Hive [TypeAdapter] and read it back.
T _roundTrip<T>(T value, TypeAdapter<T> adapter) {
  final writer = BinaryWriter();
  writer.writeByte(adapter.typeId);
  adapter.write(writer, value);
  final bytes = writer.toBytes();

  final reader = BinaryReader(bytes);
  reader.readByte(); // consume the typeId
  return adapter.read(reader);
}
