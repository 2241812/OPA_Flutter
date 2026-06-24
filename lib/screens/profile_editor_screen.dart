import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text(
          _isEditing ? 'Edit Connection' : 'New Connection',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              tooltip: 'Delete',
              onPressed: _deleteProfile,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Color picker
            _buildColorPicker(),
            const SizedBox(height: 24),

            _buildSectionLabel('Connection'),
            const SizedBox(height: 12),

            // Label
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'My PC',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Host
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.dns_rounded),
              ),
              keyboardType: TextInputType.text,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Port + Username row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '22',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final port = int.tryParse(v ?? '');
                      if (port == null || port < 1 || port > 65535) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'root',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            _buildSectionLabel('Authentication'),
            const SizedBox(height: 12),

            // Auth type selector
            SegmentedButton<AuthType>(
              segments: const [
                ButtonSegment(
                  value: AuthType.password,
                  label: Text('Password'),
                  icon: Icon(Icons.password_rounded, size: 16),
                ),
                ButtonSegment(
                  value: AuthType.publicKey,
                  label: Text('Key'),
                  icon: Icon(Icons.vpn_key_rounded, size: 16),
                ),
                ButtonSegment(
                  value: AuthType.passwordAndPublicKey,
                  label: Text('Both'),
                  icon: Icon(Icons.lock_rounded, size: 16),
                ),
              ],
              selected: {_authType},
              onSelectionChanged: (selection) {
                setState(() => _authType = selection.first);
              },
            ),
            const SizedBox(height: 16),

            // Password field
            if (_authType == AuthType.password ||
                _authType == AuthType.passwordAndPublicKey)
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

            // Key picker
            if (_authType == AuthType.publicKey ||
                _authType == AuthType.passwordAndPublicKey) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedKeyId,
                decoration: InputDecoration(
                  labelText: 'SSH Key',
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                  suffixIcon: keys.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.add_rounded, size: 18),
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
                      child: Text(key.fingerprint,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                isExpanded: true,
                onChanged: (value) {
                  setState(() => _selectedKeyId = value);
                },
              ),
              if (_authType == AuthType.publicKey && keys.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () => context.push('/keys'),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Generate or import a key'),
                  ),
                ),
            ],

            const SizedBox(height: 36),

            // Test connection button
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find_rounded),
              label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
            ),
            const SizedBox(height: 14),

            // Save button
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppConstants.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ProfileColors.palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final color = ProfileColors.palette[index];
              final isSelected = index == _colorIndex;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: isSelected ? 44 : 32,
                  height: isSelected ? 44 : 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2.5)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.black, size: 20)
                      : null,
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppConstants.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Connection successful!',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(e.toString())),
              ],
            ),
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
            style: GoogleFonts.inter(),
          ),
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
