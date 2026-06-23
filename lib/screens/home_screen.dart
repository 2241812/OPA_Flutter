import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/connection_profile.dart';
import '../models/quick_command.dart';
import '../services/profile_storage_service.dart';
import '../utils/constants.dart';
import '../widgets/connection_card.dart';

/// Main home screen showing saved connections and quick commands.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(profileStorageProvider);
    final profiles = storage.listProfiles();
    final commands = storage.listCommands();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OPA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'SSH Keys',
            onPressed: () => context.push('/keys'),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Quick Commands',
            onPressed: () => context.push('/commands'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Trigger rebuild to refresh list
        },
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Connections',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${profiles.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Connection profiles list
            if (profiles.isEmpty)
              _buildEmptyState(
                icon: Icons.router_outlined,
                title: 'No connections yet',
                subtitle: 'Tap + to add your first SSH connection',
              )
            else
              ...profiles.map(
                (profile) => ConnectionCard(
                  profile: profile,
                  onTap: () => _connectTo(profile),
                  onLongPress: () => _editProfile(profile),
                ),
              ),

            // Quick commands section
            if (commands.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Quick Commands',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              ...commands.take(3).map(
                (cmd) => _buildQuickCommandChip(cmd),
              ),
              if (commands.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextButton(
                    onPressed: () => context.push('/commands'),
                    child: Text(
                      'View all ${commands.length} commands →',
                      style: const TextStyle(color: Color(0xFF00E676)),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.35),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommandChip(QuickCommand cmd) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: InkWell(
        onTap: () => context.push('/commands'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.flash_on,
                size: 16,
                color: const Color(0xFF00E676).withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cmd.label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '\$ ${cmd.command}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _connectTo(ConnectionProfile profile) {
    context.push('/terminal/${profile.id}');
  }

  void _editProfile(ConnectionProfile profile) {
    context.push('/profile/${profile.id}');
  }

  void _showAddMenu() {
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
                title: const Text('New Connection'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key,
                    color: Color(0xFF448AFF)),
                title: const Text('Generate SSH Key'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/keys');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.flash_on, color: Color(0xFFFFAB40)),
                title: const Text('Quick Command'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/commands');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
