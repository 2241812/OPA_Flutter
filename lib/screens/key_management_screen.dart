import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stored_key_pair.dart';
import '../services/key_service.dart';
import '../widgets/key_card.dart';

/// Screen for managing SSH key pairs — generate, import, and delete.
class KeyManagementScreen extends ConsumerStatefulWidget {
  const KeyManagementScreen({super.key});

  @override
  ConsumerState<KeyManagementScreen> createState() => _KeyManagementScreenState();
}

class _KeyManagementScreenState extends ConsumerState<KeyManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(keyServiceProvider).listKeys();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Keys'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00E676).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: const Color(0xFF00E676).withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Private keys are stored in your device\'s encrypted keystore. '
                    'Copy the public key and add it to your server\'s authorized_keys file.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (keys.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.vpn_key,
                      size: 64,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No SSH keys yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate or import a key to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...keys.map(
              (key) => KeyCard(
                keyPair: key,
                onCopy: () => _copyPublicKey(key),
                onDelete: () => _deleteKey(key),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddKeyMenu,
        tooltip: 'Add Key',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _generateEd25519() async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _LabelInputDialog(
        title: 'Generate Ed25519 Key',
        hintText: 'My Key',
        defaultValue: 'Ed25519 Key ${DateTime.now().year}',
      ),
    );

    if (label == null || label.trim().isEmpty) return;

    try {
      await ref.read(keyServiceProvider).generateEd25519(label: label.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E676)),
                SizedBox(width: 8),
                Text('Ed25519 key generated'),
              ],
            ),
            backgroundColor: Color(0xFF1A1A2E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate key: $e'),
            backgroundColor: const Color(0xFF1A1A2E),
          ),
        );
      }
    }
  }

  Future<void> _importKey() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _LabelInputDialog(
        title: 'Import SSH Key',
        hintText: 'Imported Key',
        defaultValue: 'Imported Key ${DateTime.now().year}',
      ),
    );

    if (label == null || label.trim().isEmpty) return;

    // Show text input for the private key PEM
    final pemContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Paste Private Key'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: '-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----',
            hintMaxLines: 3,
          ),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (pemContent == null || pemContent.trim().isEmpty) return;

    try {
      await ref.read(keyServiceProvider).importKey(
            label: label.trim(),
            privateKeyPem: pemContent.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E676)),
                SizedBox(width: 8),
                Text('Key imported successfully'),
              ],
            ),
            backgroundColor: Color(0xFF1A1A2E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import key: $e'),
            backgroundColor: const Color(0xFF1A1A2E),
          ),
        );
      }
    }
  }

  Future<void> _copyPublicKey(StoredKeyPair key) async {
    await Clipboard.setData(ClipboardData(text: key.publicKey));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.copy, color: Color(0xFF00E676)),
              SizedBox(width: 8),
              Text('Public key copied to clipboard'),
            ],
          ),
          backgroundColor: Color(0xFF1A1A2E),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteKey(StoredKeyPair key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Key'),
        content: Text('Delete "${key.label}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(keyServiceProvider).deleteKey(key.id);
    }
  }

  void _showAddKeyMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF00E676)),
                title: const Text('Generate Ed25519 Key (Recommended)'),
                onTap: () {
                  Navigator.pop(context);
                  _generateEd25519();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.upload_file, color: Color(0xFF448AFF)),
                title: const Text('Import Existing Key'),
                onTap: () {
                  Navigator.pop(context);
                  _importKey();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple dialog for entering a label.
class _LabelInputDialog extends StatefulWidget {
  const _LabelInputDialog({
    required this.title,
    required this.hintText,
    this.defaultValue,
  });

  final String title;
  final String hintText;
  final String? defaultValue;

  @override
  State<_LabelInputDialog> createState() => _LabelInputDialogState();
}

class _LabelInputDialogState extends State<_LabelInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
