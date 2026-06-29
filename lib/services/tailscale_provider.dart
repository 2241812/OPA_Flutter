import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tailscale/tailscale.dart';

import 'tailscale_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tailscaleServiceProvider = Provider<TailscaleService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TailscaleService(secureStorage: storage);
});

final tailscaleStateProvider = StreamProvider<NodeState?>((ref) {
  final ts = ref.watch(tailscaleServiceProvider);
  if (!ts.isInitialized) return Stream.value(null);
  return ts.onStateChange.map((s) => s as NodeState?);
});
