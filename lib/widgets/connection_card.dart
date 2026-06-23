import 'package:flutter/material.dart';

import '../models/connection_profile.dart';

/// Color palette for connection profile cards.
class ProfileColors {
  ProfileColors._();

  static const List<Color> palette = [
    Color(0xFF00E676), // green
    Color(0xFF448AFF), // blue
    Color(0xFFFF5252), // red
    Color(0xFFFFAB40), // amber
    Color(0xFFE040FB), // purple
    Color(0xFF18FFFF), // cyan
    Color(0xFFFF6E40), // deep orange
    Color(0xFF69F0AE), // light green
  ];

  static Color get(int index) => palette[index % palette.length];
}

/// A card widget representing a saved SSH connection profile.
class ConnectionCard extends StatelessWidget {
  const ConnectionCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onLongPress,
  });

  final ConnectionProfile profile;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final accent = ProfileColors.get(profile.colorIndex);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator dot + accent bar
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Connection status indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: profile.lastConnectionSuccess
                                ? const Color(0xFF00E676)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.shortLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.username}@${profile.host}:${profile.port}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _authTypeLabel(profile.authType),
                      style: TextStyle(
                        fontSize: 11,
                        color: accent.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Tap to connect arrow
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _authTypeLabel(AuthType type) {
    switch (type) {
      case AuthType.password:
        return '🔑 Password';
      case AuthType.publicKey:
        return '🔐 Public Key';
      case AuthType.passwordAndPublicKey:
        return '🔑🔐 Password + Key';
    }
  }
}
