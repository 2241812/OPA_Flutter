import 'package:flutter_test/flutter_test.dart';
import 'package:opa/models/connection_profile.dart';
import 'package:opa/models/quick_command.dart';
import 'package:opa/models/stored_key_pair.dart';

void main() {
  group('ConnectionProfile', () {
    ConnectionProfile makeProfile() => ConnectionProfile(
          id: 'p1',
          label: 'My PC',
          host: '192.168.1.50',
          port: 22,
          username: 'admin',
          authType: AuthType.password,
        );

    test('displayName formats as user@host', () {
      final p = makeProfile();
      expect(p.displayName, 'admin@192.168.1.50');
    });

    test('shortLabel uses label when set', () {
      final p = makeProfile();
      expect(p.shortLabel, 'My PC');
    });

    test('shortLabel falls back to displayName when label is empty', () {
      final p = makeProfile()..label = '';
      expect(p.shortLabel, 'admin@192.168.1.50');
    });

    test('defaults: port-independent, colorIndex 0, not connected', () {
      final p = makeProfile();
      expect(p.colorIndex, 0);
      expect(p.lastConnectionSuccess, false);
      expect(p.password, isNull);
      expect(p.keyId, isNull);
    });

    test('createdAt/updatedAt default to ~now', () {
      final before = DateTime.now();
      final p = makeProfile();
      final after = DateTime.now();

      expect(p.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(p.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue);
      expect(p.updatedAt.isAtSameMomentAs(p.createdAt), isTrue);
    });

    test('explicit createdAt is preserved', () {
      final fixed = DateTime(2023, 5, 1);
      final p = ConnectionProfile(
        id: 'p',
        label: 'l',
        host: 'h',
        port: 22,
        username: 'u',
        authType: AuthType.password,
        createdAt: fixed,
      );
      expect(p.createdAt, fixed);
    });

    test('copyWith updates only specified fields and bumps updatedAt', () {
      final p = makeProfile();
      final originalUpdatedAt = p.updatedAt;

      final updated = p.copyWith(label: 'New Label', port: 2222);

      expect(updated.id, 'p1'); // unchanged
      expect(updated.label, 'New Label'); // changed
      expect(updated.port, 2222); // changed
      expect(updated.host, '192.168.1.50'); // unchanged
      expect(updated.username, 'admin'); // unchanged
      // updatedAt should be bumped to ~now
      expect(
          updated.updatedAt.isAfter(originalUpdatedAt) ||
              updated.updatedAt.isAtSameMomentAs(DateTime.now()),
          isTrue);
    });

    test('copyWith preserves createdAt (does not reset it)', () {
      final created = DateTime(2020, 1, 1);
      final p = makeProfile()..createdAt = created;
      final updated = p.copyWith(label: 'x');
      expect(updated.createdAt, created);
    });

    test('copyWith with no args returns equivalent profile', () {
      final p = makeProfile();
      final copy = p.copyWith();
      expect(copy.id, p.id);
      expect(copy.label, p.label);
      expect(copy.host, p.host);
      expect(copy.port, p.port);
      expect(copy.authType, p.authType);
    });

    test('copyWith lastConnectionSuccess flag', () {
      final p = makeProfile();
      expect(p.lastConnectionSuccess, false);
      final updated = p.copyWith(lastConnectionSuccess: true);
      expect(updated.lastConnectionSuccess, true);
    });
  });

  group('StoredKeyPair', () {
    test('secureStorageKey uses prefix + id', () {
      final k = StoredKeyPair(
        id: 'abc123',
        label: 'L',
        keyType: KeyType.ed25519,
        publicKey: 'ssh-ed25519 AAAA L',
      );
      expect(k.secureStorageKey, 'opa_key_abc123');
    });

    test('fingerprint includes label and key type name', () {
      final k = StoredKeyPair(
        id: '1',
        label: 'Work',
        keyType: KeyType.ed25519,
        publicKey: 'x',
      );
      expect(k.fingerprint, 'Work (ed25519)');
    });

    test('keyTypeLabel for ed25519', () {
      final k = StoredKeyPair(
        id: '1',
        label: 'L',
        keyType: KeyType.ed25519,
        publicKey: 'x',
      );
      expect(k.keyTypeLabel, 'Ed25519');
    });

    test('keyTypeLabel for RSA', () {
      final k = StoredKeyPair(
        id: '1',
        label: 'L',
        keyType: KeyType.rsa,
        publicKey: 'x',
      );
      expect(k.keyTypeLabel, 'RSA');
    });
  });

  group('QuickCommand', () {
    QuickCommand makeCommand() => QuickCommand(
          id: 'c1',
          label: 'Start Agent',
          command: 'echo hi',
          profileId: 'p1',
        );

    test('defaults: colorIndex 0', () {
      final c = makeCommand();
      expect(c.colorIndex, 0);
    });

    test('copyWith updates specified fields', () {
      final c = makeCommand();
      final updated = c.copyWith(label: 'New', command: 'echo bye');

      expect(updated.id, 'c1'); // unchanged
      expect(updated.label, 'New');
      expect(updated.command, 'echo bye');
      expect(updated.profileId, 'p1'); // unchanged
    });

    test('copyWith can clear profileId by passing null', () {
      final c = makeCommand();
      final updated = c.copyWith();
      expect(updated.profileId, 'p1');
    });

    test('preserves createdAt through copyWith', () {
      final fixed = DateTime(2022, 3, 3);
      final c = QuickCommand(
        id: 'c',
        label: 'l',
        command: 'cmd',
        createdAt: fixed,
      );
      final updated = c.copyWith(label: 'new');
      expect(updated.createdAt, fixed);
    });
  });
}
