import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'app_router.dart';
import 'models/connection_profile.dart';
import 'models/stored_key_pair.dart';
import 'models/quick_command.dart';
import 'services/hive_adapters.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences early for onboarding detection.
  final prefs = await SharedPreferences.getInstance();

  // Initialize Hive FIRST, then register adapters (adapters require Hive to
  // be initialized so the registry can store them).
  await Hive.initFlutter();
  registerHiveAdapters();

  // Open typed boxes for profiles, keys, and commands.
  await Hive.openBox<ConnectionProfile>('connection_profiles');
  await Hive.openBox<StoredKeyPair>('ssh_keys');
  await Hive.openBox<QuickCommand>('quick_commands');

  runApp(
    ProviderScope(
      overrides: [
        // Inject the already-initialized SharedPreferences so the
        // onboarding provider doesn't need to await again.
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const OpaApp(),
    ),
  );
}

class OpaApp extends ConsumerWidget {
  const OpaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'OPA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
