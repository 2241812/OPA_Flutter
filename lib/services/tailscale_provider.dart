import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'tailscale_service.dart';

/// Provider for the secure storage instance used by the Tailscale service.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider for the [TailscaleService] singleton.
///
/// The service must be initialized before use by calling
/// `ref.read(tailscaleServiceProvider).initialize(stateDir)` from somewhere
/// in the app startup (e.g., `main()` or a top-level widget's `initState`).
final tailscaleServiceProvider = Provider<TailscaleService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TailscaleService(secureStorage: storage);
});
