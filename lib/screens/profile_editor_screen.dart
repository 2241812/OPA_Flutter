import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../models/connection_profile.dart';
import '../services/key_service.dart';
import '../services/profile_storage_service.dart';
import '../services/ssh_service.dart';
import '../utils/constants.dart';
import '../widgets/connection_card.dart';

/// Screen for creating or editing a connection profile.
class ProfileEditorScreen extends ConsumerStatefulWidget {
  const ProfileEditorScreen({super.key, this.profileId});

  /// If null, this is a new profile; otherwise editing an existing one.
  final String? profileId;

  @override
  ConsumerState<ProfileEditorScreen> createState() =>
      _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends ConsumerState<ProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthType _authType = AuthType.password;
  String? _selectedKeyId;
  int _colorIndex = 0;
  bool _isTesting = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.profileId != null;
  ConnectionProfile? _existingProfile;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Load existing profile
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingProfile();
      });
    }
  }

  void _loadExistingProfile() {
    final storage = ref.read(profileStorageProvider);
    _existingProfile = storage.getProfile(widget.profileId!);
    if (_existingProfile == null) {
      context.pop();
      return;
    }

    setState(() {
      _labelController.text = _existingProfile!.label;
      _hostController.text = _existingProfile!.host;
      _portController.text = _existingProfile!.port.toString();
      _usernameController.text = _existingProfile!.username;
      _authType = _existingProfile!.authType;
      _selectedKeyId = _existingProfile!.keyId;
      _colorIndex = _existingProfile!.colorIndex;
      if (_existingProfile!.password != null) {
        _passwordController.text = _existingProfile!.password!;
      }
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(keyServiceProvider).listKeys();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Connection' : 'New Connection'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: _deleteProfile,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Color picker row
            _buildColorPicker(),
            const SizedBox(height: 20),

            // Label
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'My PC',
                prefixIcon: Icon(Icons.label),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Host
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.dns),
              ),
              keyboardType: TextInputType.text,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Port
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '22',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final port = int.tryParse(v ?? '');
                if (port == null || port < 1 || port > 65535) {
                  return 'Invalid port (1-65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'root',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Auth type selector
            Text(
              'Authentication',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AuthType>(
              segments: const [
                ButtonSegment(
                  value: AuthType.password,
                  label: Text('Password'),
                  icon: Icon(Icons.password, size: 18),
                ),
                ButtonSegment(
                  value: AuthType.publicKey,
                  label: Text('Key'),
                  icon: Icon(Icons.vpn_key, size: 18),
                ),
                ButtonSegment(
                  value: AuthType.passwordAndPublicKey,
                  label: Text('Both'),
                  icon: Icon(Icons.lock, size: 18),
                ),
              ],
              selected: {_authType},
              onSelectionChanged: (selection) {
                setState(() => _authType = selection.first);
              },
            ),
            const SizedBox(height: 16),

            // Password field (shown for password-based auth)
            if (_authType == AuthType.password ||
                _authType == AuthType.passwordAndPublicKey)
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

            // Key picker (shown for key-based auth)
            if (_authType == AuthType.publicKey ||
                _authType == AuthType.passwordAndPublicKey) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedKeyId,
                decoration: InputDecoration(
                  labelText: 'SSH Key',
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: keys.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          tooltip: 'Generate a key',
                          onPressed: () => context.push('/keys'),
                        ),
                ),
                items: [
                  if (keys.isEmpty)
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No keys — generate one first'),
                    ),
                  ...keys.map(
                    (key) => DropdownMenuItem(
                      value: key.id,
                      child: Text(key.fingerprint),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedKeyId = value);
                },
              ),
              if (_authType == AuthType.publicKey && keys.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () => context.push('/keys'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Generate or import a key'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00E676),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 32),

            // Test connection button
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF448AFF),
                side: const BorderSide(color: Color(0xFF448AFF)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Update' : 'Save'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ProfileColors.palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = ProfileColors.palette[index];
              final isSelected = index == _colorIndex;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = index),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final profile = _buildProfile();
      final sshService = ref.read(sshServiceProvider);

      // Get private key if needed
      String? privateKey;
      if (_authType != AuthType.password && _selectedKeyId != null) {
        privateKey = await ref
            .read(keyServiceProvider)
            .getPrivateKey(_selectedKeyId!);
      }

      await sshService.testConnection(
        profile: profile,
        privateKey: privateKey,
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E676)),
                SizedBox(width: 8),
                Text('Connection successful!'),
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
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: const Color(0xFF1A1A2E),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = _buildProfile();
    final storage = ref.read(profileStorageProvider);
    await storage.saveProfile(profile);

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Connection updated' : 'Connection saved',
          ),
          backgroundColor: const Color(0xFF1A1A2E),
        ),
      );
    }
  }

  ConnectionProfile _buildProfile() {
    return ConnectionProfile(
      id: _existingProfile?.id ?? const Uuid().v4(),
      label: _labelController.text.trim(),
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim(),
      authType: _authType,
      password: _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
      keyId: _selectedKeyId,
      colorIndex: _colorIndex,
      createdAt: _existingProfile?.createdAt,
    );
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Connection'),
        content: Text(
          'Delete "${_labelController.text.trim()}"? This cannot be undone.',
        ),
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
      final storage = ref.read(profileStorageProvider);
      await storage.deleteProfile(widget.profileId!);
      if (mounted) context.pop();
    }
  }
}
