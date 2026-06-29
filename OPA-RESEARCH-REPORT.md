# OPA — Full Codebase Research Report

Generated: 2026-06-26
Scope: Complete audit of lib/ — screens, services, models, widgets, utils, pubspec.yaml

---

## 1. Complete File Inventory (29 Dart files)

### Screens (8)
| File | Lines | Purpose |
|------|-------|---------|
| lib/screens/home_screen.dart | 650 | Main screen — connections + quick commands + update |
| lib/screens/terminal_screen.dart | 701 | SSH terminal with xterm, auto-fit, keyboard bar |
| lib/screens/quick_commands_screen.dart | 913 | Quick commands + 20+ built-in agent presets |
| lib/screens/profile_editor_screen.dart | 529 | Create/edit connection profile form |
| lib/screens/key_management_screen.dart | 530 | Generate/import/delete SSH keys |
| lib/screens/onboarding_screen.dart | 561 | 4-slide first-launch onboarding |
| lib/screens/settings_screen.dart | 232 | AMOLED Black, Biometric Lock, About card |
| lib/screens/lock_screen.dart | 476 | Biometric lock gate (fingerprint/face) |

### Services (8)
| File | Lines | Purpose |
|------|-------|---------|
| lib/services/ssh_service.dart | 201 | SSH connect, shell, execute, resize, disconnect |
| lib/services/key_service.dart | 159 | Generate/import/delete SSH keys |
| lib/services/profile_storage_service.dart | 79 | Hive CRUD for profiles and commands |
| lib/services/biometric_service.dart | 48 | Local auth wrapper |
| lib/services/biometric_provider.dart | 52 | Biometric lock state + auth session |
| lib/services/onboarding_service.dart | 50 | First-launch detection |
| lib/services/update_service.dart | 180 | GitHub Releases update checker |
| lib/services/hive_adapters.dart | ~120 | Manual Hive TypeAdapters |

### Models (3)
| File | Purpose |
|------|---------|
| lib/models/connection_profile.dart | SSH connection profile |
| lib/models/stored_key_pair.dart | SSH key metadata |
| lib/models/quick_command.dart | Saved command with optional presetId |

### Widgets (2) + Utils (5) + Core (3)
connection_card.dart, key_card.dart, constants.dart, agent_presets.dart (20+ presets), app_version.dart, ssh_key_encoder.dart, theme_provider.dart, main.dart, app_router.dart (7 routes), app_theme.dart

---

## 2. UNREALIZED dartssh2 CAPABILITIES (Critical Gap)

dartssh2 2.18.0 provides these. OPA uses NONE of them.

| Feature | API | Wired? | Effort |
|---------|-----|--------|--------|
| **SFTP** | client.sftp() ? SftpClient.listdir/open/read/write/download/upload/remove/mkdir/rmdir/rename/stat/link | ? NOT AT ALL | Medium (UI) |
| **Local Port Forward** | client.directTcpip() | ? | Medium |
| **Remote Port Forward** | client.forwardRemote() | ? | Medium |
| **Dynamic Forward** | DynamicForwardServer | ? | Medium |
| **SSH Agent Forward** | client.onAgentForwardRequest | ? | Low |
| **HTTP Tunnel** | dartssh2/src/http/ | ? | Low |

Current OPA uses only 6 of ~30+ dartssh2 API surfaces: SSHSocket.connect, SSHClient, SSHKeyPair.fromPem, client.shell, client.execute, SSHAuthError.

---

## 3. MISSING FEATURES (Ranked)

### P0 — SFTP File Browser (RECOMMENDED NEXT)
Why: SSH without file transfer is incomplete. dartssh2 ships full SftpClient.
What: ~500-800 lines across 3-4 files.
Files: New sftp_service.dart, sftp_screen.dart. Modify ssh_service.dart, app_router.dart.

### P0 — Custom Preset Editor
Why: Model (presetId) and 20+ presets exist. No form to create custom ones.
What: ~300-400 lines. New preset_editor_screen.dart or bottom sheet. Modify quick_commands_screen.dart.

### P0 — Profile/Key Import/Export
Why: Zero data portability. All data locked to device Hive.
What: ~200-300 lines. JSON serialization + share sheet. Modify settings_screen.dart, profile_storage_service.dart.

### P1 — Port Forwarding UI
Roadmap item. ~600 lines. Service + UI for local/remote port management.

### P1 — Terminal Settings
Settings screen is bare. Need: font size slider, scrollback lines, keepalive, terminal type.
~150 lines. Modify settings_screen.dart, constants.dart.

### P2 — Jump Host, Agent Forwarding, Session Recording, iOS, HTTP Tunnel
Various effort levels. All roadmap items with zero code.

---

## 4. TECHNICAL DEBT

### ?? 2 Pre-Existing Test Failures
test/ssh_key_encoder_test.dart:
1. Line 89 — openssh-key-v1 magic string check off-by-one
2. Line 154 — RangeError reading past buffer (cascading offset error)

### ?? ~200 withOpacity Deprecation Warnings
Every UI file uses withOpacity() — deprecated in favor of withValues(alpha:).
Affects: lock_screen (~18), home_screen (~30), settings_screen (~20), quick_commands (~30), terminal (~10), onboarding (~25), key_management (~15), profile_editor (~5), connection_card (~10), key_card (~10), app_theme (~20), others.

### ?? 4 Lint Warnings
- unused_field _updateChecked (home_screen.dart:26)
- unused_import flutter_animate (profile_editor_screen.dart:2)
- unused_import go_router (quick_commands_screen.dart:6)
- use_build_context_synchronously (key_management_screen.dart:268)

### ?? No TODO/FIXME/HACK comments. Clean codebase otherwise.

---

## 5. RECOMMENDATION

**SFTP File Browser** is #1: highest user value, lowest backend effort (dartssh2 already has it), natural UX from terminal.
