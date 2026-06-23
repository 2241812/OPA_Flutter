import 'package:flutter/material.dart';

import '../models/stored_key_pair.dart';

/// A card widget representing a stored SSH key pair.
class KeyCard extends StatelessWidget {
  const KeyCard({
    super.key,
    required this.keyPair,
    this.onTap,
    this.onCopy,
    this.onDelete,
  });

  final StoredKeyPair keyPair;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isEd25519 = keyPair.keyType == KeyType.ed25519;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Key type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isEd25519
                        ? const Color(0xFF00E676)
                        : const Color(0xFF448AFF))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isEd25519 ? Icons.vpn_key : Icons.key,
                color: isEd25519
                    ? const Color(0xFF00E676)
                    : const Color(0xFF448AFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Key info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    keyPair.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    keyPair.keyTypeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _truncatedPublicKey(keyPair.publicKey),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.35),
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Copy public key button
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: Colors.white.withOpacity(0.5),
              tooltip: 'Copy public key',
              onPressed: onCopy,
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red.withOpacity(0.6),
              tooltip: 'Delete key',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _truncatedPublicKey(String key) {
    if (key.length > 40) {
      return '${key.substring(0, 37)}...';
    }
    return key;
  }
}
