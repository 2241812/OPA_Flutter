# Ultrawork Notepad — Biometric Lock for OPA
Started: 2026-06-26T18:00:00+08:00

## Architecture
- Wrapper widget `_AppGate` in main.dart renders LockScreen or OpaApp based on Riverpod state
- biometric_lock_enabled bool persisted to SharedPreferences (same pattern as AMOLED toggle)
- local_auth authenticates via fingerprint/FaceID/pin

## Plan (exhaustive, atomic)
Wave 1 (parallel):
  W1.1: pubspec.yaml — add local_auth dependency
  W1.2: constants.dart — add biometricLockEnabledKey
Wave 2 (parallel, after W1):
  W2.1: lib/services/biometric_service.dart — wraps LocalAuthentication
  W2.2: lib/services/biometric_provider.dart — Riverpod StateNotifier<bool> for lock toggle
Wave 3 (depends on W2):
  W3.1: lib/screens/lock_screen.dart — full-screen auth gate widget
  W3.2: lib/main.dart — add _AppGate wrapper that conditionally shows LockScreen
  W3.3: lib/screens/settings_screen.dart — add biometric lock toggle switch
Wave 4:
  W4.1: Tests for biometric_service
  W4.2: Tests for biometric_provider
  W4.3: Verify existing tests still pass
Wave 5:
  W5.1: flutter analyze
  W5.2: Build + manual QA

## Scenarios (the contract)
S1: User enables biometric lock → app shows lock screen → auth ok → app opens
S2: Biometric lock disabled → app opens directly (no lock screen)
S3: Biometrics unavailable → toggle shows disabled state
S4: Auth fails (wrong finger) → lock screen stays, retry available

## Todo (remaining, ordered)
[ ] W1.1: pubspec.yaml — add local_auth
[ ] W1.2: constants.dart — add key
[ ] W2.1: lib/services/biometric_service.dart
[ ] W2.2: lib/services/biometric_provider.dart
[ ] W3.1: lib/screens/lock_screen.dart
[ ] W3.2: lib/main.dart — biometric gate
[ ] W3.3: lib/screens/settings_screen.dart — toggle
[ ] W4.1: Tests
[ ] W5+: Analyze + QA
