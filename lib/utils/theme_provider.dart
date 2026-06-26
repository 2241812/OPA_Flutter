import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/onboarding_service.dart';

/// Key used to persist the AMOLED black mode preference.
const _amoledKey = 'opa_amoled_black';

/// Whether AMOLED pure-black mode is enabled.
final amoledBlackProvider = StateNotifierProvider<AmoledBlackNotifier, bool>(
  (ref) => AmoledBlackNotifier(ref),
);

class AmoledBlackNotifier extends StateNotifier<bool> {
  final Ref _ref;

  AmoledBlackNotifier(this._ref) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = _ref.read(sharedPrefsProvider);
    state = prefs.getBool(_amoledKey) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = _ref.read(sharedPrefsProvider);
    await prefs.setBool(_amoledKey, state);
  }
}
