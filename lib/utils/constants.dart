import 'package:flutter/material.dart';

/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'OPA';
  static const String appFullTitle = 'OpenSSH Pocket Agent';
  static const String appVersion = '0.1.0';

  // Hive box names
  static const String profilesBox = 'connection_profiles';
  static const String keysBox = 'ssh_keys';
  static const String commandsBox = 'quick_commands';

  // Secure storage keys prefix
  static const String secureStoragePrefix = 'opa_key_';

  // SSH defaults
  static const int defaultSshPort = 22;
  static const Duration defaultKeepAlive = Duration(seconds: 30);
  static const int defaultScrollbackLines = 10000;
  static const Duration connectionTimeout = Duration(seconds: 15);

  // Terminal defaults
  static const String defaultTermEnv = 'xterm-256color';
  static const double defaultFontSize = 14.0;
  static const double minFontSize = 8.0;
  static const double maxFontSize = 32.0;
}
