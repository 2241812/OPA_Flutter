
import 'package:flutter/material.dart';
import 'package:tailscale/tailscale.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/connection_profile.dart';
import '../models/quick_command.dart';
import '../services/profile_storage_service.dart';
import '../services/update_service.dart';
import '../services/tailscale_provider.dart';
import '../utils/constants.dart';
import '../widgets/connection_card.dart';

/// Main home screen showing saved connections and quick commands.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _updateChecked = false;
  NodeState? _tailscaleNodeState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _menuAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _checkForUpdate();
    _initTailscaleListener();
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (!mounted || info == null) return;
    setState(() => _updateChecked = true);
    _showUpdateDialog(info);
  }

  void _initTailscaleListener() {
    ref.listen<AsyncValue<NodeState?>>(tailscaleStateProvider, (_, next) {
      final state = next.valueOrNull;
      if (!mounted) return;
      setState(() => _tailscaleNodeState = state);
      if (state == NodeState.needsLogin) {
        _showAuthUrl();
      }
    });
  }

  Future<void> _showAuthUrl() async {
    try {
      final ts = ref.read(tailscaleServiceProvider);
      final st = await ts.status();
      if (st.authUrl != null && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            backgroundColor: AppConstants.surfaceDark,
            title: const Text('Tailscale Auth Required'),
            content: Text('Open this URL in a browser to authenticate:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  launchUrl(st.authUrl!);
                  Navigator.pop(ctx);
                },
                child: const Text('Open URL'),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoRetryTailscale();
    }
  }

  Future<void> _autoRetryTailscale() async {
    try {
      final ts = ref.read(tailscaleServiceProvider);
      if (!ts.isInitialized) return;
      final st = await ts.status();
      if ((st.state == NodeState.needsLogin ||
          st.state == NodeState.needsMachineAuth) &&
          st.authUrl != null && mounted) {
        _showAuthUrl();
      } else if (st.state == NodeState.stopped ||
          st.state == NodeState.noState) {
        final key = await ts.readAuthKey();
        if (key != null && key.isNotEmpty) {
          await ts.up(authKey: key);
        }
      }
    } catch (_) {}
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

  Future<void> _showTailscaleSettings() async {
    if (!mounted) return;
    final ts = ref.read(tailscaleServiceProvider);
    TailscaleStatus? st;
    try { st = await ts.status(); } catch (_) {}
    final hasAuthKey = await ts.readAuthKey();
    if (!mounted) return;
    final nodeState = _tailscaleNodeState;
    Color stateColor;
    String stateLabel;
    if (nodeState == null || nodeState == NodeState.noState) {
      stateColor = Colors.grey;
      stateLabel = 'Not initialized';
    } else if (nodeState == NodeState.running) {
      stateColor = const Color(0xFF4CAF50);
      stateLabel = 'Connected';
    } else if (nodeState == NodeState.needsLogin ||
        nodeState == NodeState.needsMachineAuth) {
      stateColor = const Color(0xFFFF9800);
      stateLabel = nodeState == NodeState.needsLogin
          ? 'Login required'
          : 'Machine auth required';
    } else if (nodeState == NodeState.starting) {
      stateColor = const Color(0xFFFFD54F);
      stateLabel = 'Connecting';
    } else {
      stateColor = Colors.grey;
      stateLabel = 'Stopped';
    }
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:BorderSide(color:Colors.white.withOpacity(0.08))),
        backgroundColor: AppConstants.surfaceDark,
        title: Row(children: [
          Container(width:10,height:10,decoration:BoxDecoration(shape:BoxShape.circle,color:stateColor,boxShadow:[BoxShadow(color:stateColor.withOpacity(0.4),blurRadius:6)])),
          SizedBox(width:10),
          Text('Tailscale Node'),
        ]),
        content: Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          _tsInfoRow('Status',stateLabel,stateColor),
          if(st!=null) ...[
            SizedBox(height:6),
            _tsInfoRow('IPv4',st.ipv4??'-',Colors.white70),
            SizedBox(height:6),
            _tsInfoRow('DNS',st.magicDNSSuffix??'-',Colors.white70),
            SizedBox(height:6),
            _tsInfoRow('Node ID',st.stableNodeId??"-",Colors.white70),
          ],
          SizedBox(height:12),
          _tsInfoRow('Auth Key',hasAuthKey!=null?'Configured':'Not set',hasAuthKey!=null?AppConstants.primaryGreen:Colors.white38),
        ]),
        actions: [
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            try { await ts.logout(); if(mounted) setState((){}); } catch(_) {}
          }, child: Text('Logout')),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            try { await ts.up(); } catch(_) {}
          }, child: Text('Reconnect')),
          ElevatedButton(onPressed: ()=>Navigator.pop(ctx), child: Text('Close')),
        ],
      );
    });
  }

  Widget _tsInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
        Text(value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
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
                  tailscaleState: _tailscaleNodeState,
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
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ..._buildMenuActions(),
          FloatingActionButton(
            onPressed: _toggleMenu,
            child: AnimatedRotation(
              turns: _menuOpen ? 0.375 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
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

  /// Whether the FAB expansion menu is open.
  bool _menuOpen = false;

  /// Animation controller for FAB menu items.
  late final AnimationController _menuAnimCtrl;


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _menuAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
      if (_menuOpen) {
        _menuAnimCtrl.forward();
      } else {
        _menuAnimCtrl.reverse();
      }
    });
  }

  List<Widget> _buildMenuActions() {
    return [
      _MenuItem(
        animCtrl: _menuAnimCtrl,
        index: 3,
        icon: Icons.settings_ethernet_rounded,
        color: const Color(0xFF7C4DFF),
        label: 'Tailscale',
        onTap: () {
          _toggleMenu();
          _showTailscaleSettings();
        },
      ),
      _MenuItem(
        animCtrl: _menuAnimCtrl,
        index: 2,
        icon: Icons.flash_on_rounded,
        color: const Color(0xFFFFAB40),
        label: 'Quick Command',
        onTap: () => context.push('/commands'),
      ),
      _MenuItem(
        animCtrl: _menuAnimCtrl,
        index: 1,
        icon: Icons.vpn_key_rounded,
        color: const Color(0xFF448AFF),
        label: 'Generate SSH Key',
        onTap: () => context.push('/keys'),
      ),
      _MenuItem(
        animCtrl: _menuAnimCtrl,
        index: 0,
        icon: Icons.add_circle_outline_rounded,
        color: AppConstants.primaryGreen,
        label: 'New Connection',
        onTap: () => context.push('/profile/new'),
      ),
    ];
  }
}


/// A single animated FAB menu item that slides and fades in.
class _MenuItem extends StatelessWidget {
  final AnimationController animCtrl;
  final int index;
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.animCtrl,
    required this.index,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: animCtrl,
      curve: Interval(
        0.0 + index * 0.1,
        0.3 + index * 0.1,
        curve: Curves.easeOut,
      ),
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: SizedBox(
          width: 48,
          height: 48,
          child: FloatingActionButton.small(
            heroTag: 'fab_menu_' + index.toString(),
            backgroundColor: color.withOpacity(0.15),
            onPressed: onTap,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}