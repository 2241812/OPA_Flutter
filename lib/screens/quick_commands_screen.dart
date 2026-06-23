import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/connection_profile.dart';
import '../models/quick_command.dart';
import '../services/key_service.dart';
import '../services/profile_storage_service.dart';
import '../services/ssh_service.dart';
import '../utils/constants.dart';

/// Screen for managing and executing quick commands.
class QuickCommandsScreen extends ConsumerStatefulWidget {
  const QuickCommandsScreen({super.key});

  @override
  ConsumerState<QuickCommandsScreen> createState() =>
      _QuickCommandsScreenState();
}

class _QuickCommandsScreenState extends ConsumerState<QuickCommandsScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(profileStorageProvider);
    final commands = storage.listCommands();
    final profiles = storage.listProfiles();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Commands'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAB40).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFFAB40).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  size: 18,
                  color: const Color(0xFFFFAB40).withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Save frequently-used commands for one-tap execution on your remote machines. '
                    'Great for launching agent harnesses or running scripts.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (commands.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 64,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No quick commands yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save commands you run often for quick access',
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
            ...commands.map((cmd) => _buildCommandCard(cmd, profiles)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCommandEditor(),
        tooltip: 'Add Command',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCommandCard(QuickCommand cmd, List<ConnectionProfile> profiles) {
    final profile = cmd.profileId != null
        ? profiles.where((p) => p.id == cmd.profileId).firstOrNull
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _executeCommand(cmd),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Execute icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFAB40).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Color(0xFFFFAB40),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Command info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cmd.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cmd.command,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (profile != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '→ ${profile.shortLabel}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') {
                    _showCommandEditor(command: cmd);
                  } else if (action == 'delete') {
                    _deleteCommand(cmd);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeCommand(QuickCommand cmd) async {
    // If command has a profile, connect and execute
    if (cmd.profileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This command is not linked to a profile. Edit to link it.'),
          backgroundColor: Color(0xFF1A1A2E),
        ),
      );
      return;
    }

    final storage = ref.read(profileStorageProvider);
    final profile = storage.getProfile(cmd.profileId!);
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Linked profile not found.'),
          backgroundColor: Color(0xFF1A1A2E),
        ),
      );
      return;
    }

    // Show output in a bottom sheet
    _showCommandOutput(cmd, profile);
  }

  Future<void> _showCommandOutput(
    QuickCommand cmd,
    ConnectionProfile profile,
  ) async {
    final output = StringBuffer();
    Terminal? terminal;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1A2E),
              child: Row(
                children: [
                  Icon(
                    Icons.terminal,
                    color: const Color(0xFF00E676).withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '\$ ${cmd.command}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'on ${profile.shortLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Output area (use a FutureBuilder for simplicity in the MVP)
            Expanded(
              child: FutureBuilder<String>(
                future: _runCommand(cmd, profile),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF00E676),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Running command...',
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final result = snapshot.data ?? snapshot.error.toString();

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SelectableText(
                        result,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _runCommand(
    QuickCommand cmd,
    ConnectionProfile profile,
  ) async {
    final sshService = ref.read(sshServiceProvider);
    String? privateKey;
    if (profile.keyId != null) {
      privateKey =
          await ref.read(keyServiceProvider).getPrivateKey(profile.keyId!);
    }

    try {
      await sshService.connect(
        profile: profile,
        privateKey: privateKey,
        password: profile.password,
      );
      final output = await sshService.executeCommand(cmd.command);
      await sshService.disconnect();
      return output;
    } catch (e) {
      try {
        await sshService.disconnect();
      } catch (_) {}
      return 'Error: $e';
    }
  }

  Future<void> _showCommandEditor({QuickCommand? command}) async {
    final labelController = TextEditingController(text: command?.label ?? '');
    final commandController =
        TextEditingController(text: command?.command ?? '');

    final storage = ref.read(profileStorageProvider);
    final profiles = storage.listProfiles();
    String? selectedProfileId = command?.profileId;

    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                command != null ? 'Edit Command' : 'New Quick Command',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: labelController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'Start my agent',
                  prefixIcon: Icon(Icons.label),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commandController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Command',
                  hintText: 'python ~/agents/start.py --auto',
                  prefixIcon: Icon(Icons.terminal),
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: selectedProfileId,
                decoration: const InputDecoration(
                  labelText: 'Target Profile',
                  prefixIcon: Icon(Icons.router),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Ask at runtime'),
                  ),
                  ...profiles.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.shortLabel),
                    ),
                  ),
                ],
                onChanged: (v) => setModalState(() => selectedProfileId = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, {
                    'label': labelController.text.trim(),
                    'command': commandController.text.trim(),
                    'profileId': selectedProfileId,
                  });
                },
                icon: const Icon(Icons.save),
                label: Text(command != null ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    final label = result['label']!;
    final cmdText = result['command']!;
    if (label.isEmpty || cmdText.isEmpty) return;

    final quickCommand = QuickCommand(
      id: command?.id ?? const Uuid().v4(),
      label: label,
      command: cmdText,
      profileId: result['profileId'],
      createdAt: command?.createdAt,
    );

    await ref.read(profileStorageProvider).saveCommand(quickCommand);

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(command != null ? 'Command updated' : 'Command saved'),
          backgroundColor: const Color(0xFF1A1A2E),
        ),
      );
    }
  }

  Future<void> _deleteCommand(QuickCommand cmd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Command'),
        content: Text('Delete "${cmd.label}"?'),
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
      await ref.read(profileStorageProvider).deleteCommand(cmd.id);
      setState(() {});
    }
  }
}
