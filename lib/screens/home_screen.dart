import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/connection_profile.dart';
import '../models/quick_command.dart';
import '../services/profile_storage_service.dart';
import '../services/update_service.dart';
import '../utils/constants.dart';
import '../widgets/connection_card.dart';

/// Main home screen showing saved connections and quick commands.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (!mounted || info == null) return;
    setState(() => _updateChecked = true);
    _showUpdateDialog(info);
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        backgroundColor: AppConstants.surfaceDark,
        title: Row(
          children: [
            Icon(
              Icons.system_update_rounded,
              color: AppConstants.primaryGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Update Available',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPA v${info.latestVersion} is ready to install.',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            if (info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF448AFF),
              side: const BorderSide(color: Color(0xFF448AFF), width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Later',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(info.downloadUrl),
                  mode: LaunchMode.externalApplication);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Download APK',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(profileStorageProvider);
    final profiles = storage.listProfiles();
    final commands = storage.listCommands();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primaryGreen.withOpacity(0.1),
                border:
                    Border.all(color: AppConstants.primaryGreen.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.terminal_rounded,
                size: 16,
                color: AppConstants.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'OPA',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.vpn_key_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            tooltip: 'SSH Keys',
            onPressed: () => context.push('/keys'),
          ),
          IconButton(
            icon: Icon(
              Icons.flash_on_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            tooltip: 'Quick Commands',
            onPressed: () => context.push('/commands'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        color: AppConstants.primaryGreen,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          children: [
            // ── Header section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Your Servers',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                          .animate()
                          .fadeIn(
                              duration: 400.ms, curve: Curves.easeOut)
                          .slideX(
                              begin: -0.05,
                              end: 0,
                              duration: 350.ms,
                              curve: Curves.easeOut),
                      const SizedBox(width: 10),
                      if (profiles.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppConstants.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppConstants.primaryGreen
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            '${profiles.length}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppConstants.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                                duration: 300.ms,
                                delay: 200.ms,
                                curve: Curves.easeOut)
                            .scale(
                                begin: const Offset(0.8, 0.8),
                                duration: 300.ms,
                                delay: 200.ms,
                                curve: Curves.easeOutBack),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to connect to your remote machines',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  )
                      .animate()
                      .fadeIn(
                          duration: 400.ms,
                          delay: 100.ms,
                          curve: Curves.easeOut),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Connection profiles list ──
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

            // ── Quick commands section ──
            if (commands.isNotEmpty) ...[
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Quick Commands',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFAB40).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFAB40).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '${commands.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFFFAB40),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...commands.take(3).map(
                (cmd) => _buildQuickCommandChip(cmd),
              ),
              if (commands.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: TextButton(
                    onPressed: () => context.push('/commands'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all ${commands.length} commands',
                          style: GoogleFonts.inter(
                            color: AppConstants.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppConstants.primaryGreen.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryGreen.withOpacity(0.25),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddMenu,
          tooltip: 'Add',
          child: const Icon(Icons.add_rounded),
        ),
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
          Icon(
            icon,
            size: 64,
            color: Colors.white.withOpacity(0.1),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                  duration: 2500.ms,
                  color: AppConstants.primaryGreen.withOpacity(0.08))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.02, 1.02),
                duration: 2500.ms,
                curve: Curves.easeInOutSine,
              ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.25),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommandChip(QuickCommand cmd) {
    final accent = const Color(0xFFFFAB40);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Container(
            decoration: BoxDecoration(
              color: AppConstants.surfaceDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.02),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/commands'),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: accent.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cmd.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$ ${cmd.command}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.surfaceDark.withOpacity(0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(
                  color: AppConstants.primaryGreen.withOpacity(0.15),
                  width: 1,
                ),
                left: BorderSide(
                  color: Colors.white.withOpacity(0.04),
                ),
                right: BorderSide(
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              AppConstants.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppConstants.primaryGreen,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'New Connection',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile/new');
                      },
                    ),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF448AFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          color: Color(0xFF448AFF),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Generate SSH Key',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/keys');
                      },
                    ),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFAB40).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.flash_on_rounded,
                          color: Color(0xFFFFAB40),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Quick Command',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/commands');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
