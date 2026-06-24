import 'package:flutter/material.dart';

/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'OPA';
  static const String appFullTitle = 'OpenSSH Pocket Agent';
  static const String appVersion = '0.2.0';

  // Hive box names
  static const String profilesBox = 'connection_profiles';
  static const String keysBox = 'ssh_keys';
  static const String commandsBox = 'quick_commands';

  // Secure storage keys prefix
  static const String secureStoragePrefix = 'opa_key_';

  // Onboarding
  static const String onboardingCompleteKey = 'opa_onboarding_complete';

  // SSH defaults
  static const int defaultSshPort = 22;
  static const Duration defaultKeepAlive = Duration(seconds: 30);
  static const int defaultScrollbackLines = 10000;
  static const Duration connectionTimeout = Duration(seconds: 15);

  // Terminal defaults
  static const String defaultTermEnv = 'xterm-256color';
  static const double defaultFontSize = 14.0;
  static const double minFontSize = 6.0;
  static const double maxFontSize = 32.0;

  // Terminal auto-fit targets (for TUI apps like opencode)
  static const int targetMinColsPortrait = 80;
  static const int targetMinColsLandscape = 120;

  // Terminal char width approx multiplier (monospace char ≈ fontSize * ratio)
  static const double charWidthRatio = 0.6;

  // Status bar heights
  static const double statusBarHeightPortrait = 28.0;
  static const double statusBarHeightLandscape = 22.0;

  // Keyboard bar height
  static const double keyboardBarHeightPortrait = 44.0;
  static const double keyboardBarHeightLandscape = 36.0;

  // App color palette
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color inputFill = Color(0xFF16213E);
}
