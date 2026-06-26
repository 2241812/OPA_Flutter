import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service wrapping device biometric/local authentication.
///
/// Methods are not cached — every call goes through the platform plugin,
/// so callers should treat this as a fresh check each time.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device can authenticate using biometrics (fingerprint / face)
  /// OR device credentials (pin / pattern / passcode).
  Future<bool> canAuthenticate() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompt the user to authenticate.
  ///
  /// Returns `true` when the user successfully authenticates.
  /// Returns `false` when the user cancels or the auth fails without side
  /// effects (wrong finger — the OS handles retry internally and only reports
  /// the final state to the app).
  ///
  /// Throws [PlatformException] for platform errors (no hardware, lockout).
  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
          biometricOnly: biometricOnly,
        ),
      );
    } on PlatformException {
      rethrow;
    }
  }
}
