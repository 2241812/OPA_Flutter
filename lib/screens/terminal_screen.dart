import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../services/key_service.dart';
import '../services/profile_storage_service.dart';
import '../services/ssh_service.dart';
import '../utils/constants.dart';

/// Full-screen terminal screen connected to an SSH session.
class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key, required this.profileId});

  /// ID of the connection profile to use.
  final String profileId;

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  late final Terminal _terminal;
  late final TerminalController _terminalController;

  StreamSubscription? _stdoutSub;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _error;
  double _fontSize = AppConstants.defaultFontSize;

  @override
  void initState() {
    super.initState();

    _terminal = Terminal(
      maxScrollbackLines: AppConstants.defaultScrollbackLines,
    );

    _terminalController = TerminalController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connect();
    });
  }

  @override
  void dispose() {
    _stdoutSub?.cancel();
    _terminal.dispose();
    ref.read(sshServiceProvider).disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    // Write connection banner to terminal
    _terminal.write(
      '\x1b[1;32m⬡ OPA — OpenSSH Pocket Agent v${AppConstants.appVersion}\x1b[0m\r\n\r\n'
      '\x1b[33mConnecting...\x1b[0m\r\n',
    );

    try {
      final storage = ref.read(profileStorageProvider);
      final profile = storage.getProfile(widget.profileId);
      if (profile == null) {
        throw StateError('Profile not found: ${widget.profileId}');
      }

      final sshService = ref.read(sshServiceProvider);

      // Get private key if needed
      String? privateKey;
      if (profile.keyId != null) {
        privateKey = await ref.read(keyServiceProvider).getPrivateKey(profile.keyId!);
      }

      // Connect
      await sshService.connect(
        profile: profile,
        privateKey: privateKey,
        password: profile.password,
      );

      _terminal.write(
          '\x1b[32m✓ Connected to ${profile.displayName}\x1b[0m\r\n\r\n');

      // Open interactive shell (async in dartssh2 v2.x)
      final session = await sshService.startShell();

      // Wire stdout → terminal
      _stdoutSub = session.stdout.listen(
        (data) {
          if (mounted) {
            _terminal.write(String.fromCharCodes(data));
          }
        },
        onDone: () {
          if (mounted) {
            _terminal.write('\r\n\x1b[33m⚡ Connection closed\x1b[0m\r\n');
            setState(() => _isConnected = false);
          }
        },
        onError: (e) {
          if (mounted) {
            _terminal.write('\r\n\x1b[31m✗ Error: $e\x1b[0m\r\n');
            setState(() => _isConnected = false);
          }
        },
      );

      // Wire terminal input → stdin
      _terminal.onOutput = (String data) {
        session.stdinSink.add(Uint8List.fromList(data.codeUnits));
      };

      // Handle terminal resize (cols/rows — pixel dims ignored)
      _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        sshService.resizeShell(cols: width, rows: height);
      };

      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });

      // Update connection status in profile
      await storage.updateConnectionStatus(profile.id, true);
    } catch (e) {
      if (mounted) {
        _terminal.write('\r\n\x1b[31m✗ Connection failed:\x1b[0m $e\r\n\r\n');

        // Update connection status in profile
        final storage = ref.read(profileStorageProvider);
        await storage.updateConnectionStatus(widget.profileId, false);

        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
    }
  }

  void _disconnect() async {
    await ref.read(sshServiceProvider).disconnect();
    _stdoutSub?.cancel();
    setState(() => _isConnected = false);
  }

  void _sendCtrlC() {
    _terminal.keyInput(TerminalKey.controlC);
  }

  void _sendCtrlD() {
    _terminal.keyInput(TerminalKey.controlD);
  }

  void _copySelection() {
    final text = _terminal.selectedText;
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No selection to copy'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _zoomIn() {
    setState(() {
      _fontSize = (_fontSize + 1).clamp(
        AppConstants.minFontSize,
        AppConstants.maxFontSize,
      );
    });
  }

  void _zoomOut() {
    setState(() {
      _fontSize = (_fontSize - 1).clamp(
        AppConstants.minFontSize,
        AppConstants.maxFontSize,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this is a wide screen (tablet/landscape)
    final isWide = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ref
                  .read(profileStorageProvider)
                  .getProfile(widget.profileId)
                  ?.shortLabel ??
              'Terminal',
        ),
        actions: [
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 20),
            tooltip: 'Zoom out',
            onPressed: _zoomOut,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '${_fontSize.toInt()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            tooltip: 'Zoom in',
            onPressed: _zoomIn,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (action) {
              switch (action) {
                case 'ctrl_c':
                  _sendCtrlC();
                  break;
                case 'ctrl_d':
                  _sendCtrlD();
                  break;
                case 'copy':
                  _copySelection();
                  break;
                case 'disconnect':
                  _disconnect();
                  break;
                case 'reconnect':
                  _disconnect();
                  _connect();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ctrl_c',
                child: Row(
                  children: [
                    Icon(Icons.stop_circle_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Ctrl+C'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ctrl_d',
                child: Row(
                  children: [
                    Icon(Icons.door_front_door, size: 18),
                    SizedBox(width: 12),
                    Text('Ctrl+D (EOF)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 18),
                    SizedBox(width: 12),
                    Text('Copy selection'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (_isConnected)
                const PopupMenuItem(
                  value: 'disconnect',
                  child: Row(
                    children: [
                      Icon(Icons.link_off, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Disconnect'),
                    ],
                  ),
                ),
              if (!_isConnected)
                const PopupMenuItem(
                  value: 'reconnect',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 18, color: Color(0xFF00E676)),
                      SizedBox(width: 12),
                      Text('Reconnect'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status bar
          _buildStatusBar(),
          // Terminal view
          Expanded(
            child: GestureDetector(
              onScaleUpdate: (details) {
                // Pinch-to-zoom
                if (details.scale != 1.0) {
                  setState(() {
                    _fontSize = (_fontSize * details.scale).clamp(
                      AppConstants.minFontSize,
                      AppConstants.maxFontSize,
                    );
                  });
                }
              },
              child: TerminalView(
                _terminal,
                controller: _terminalController,
                autofocus: true,
                backgroundOpacity: 1.0,
                textStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: _fontSize,
                  height: 1.2,
                  color: Colors.white,
                  backgroundColor: Colors.transparent,
                ),
                cursorType: TerminalCursorType.block,
                padding: const EdgeInsets.all(8),
                theme: TerminalTheme(
                  cursor: const Color(0xFF00E676),
                  selection: const Color(0x7F00E676),
                  foreground: Colors.white,
                  background: const Color(0xFF0F0F1A),
                  black: const Color(0xFF000000),
                  red: const Color(0xFFFF5252),
                  green: const Color(0xFF00E676),
                  yellow: const Color(0xFFFFAB40),
                  blue: const Color(0xFF448AFF),
                  magenta: const Color(0xFFE040FB),
                  cyan: const Color(0xFF18FFFF),
                  white: const Color(0xFFFFFFFF),
                  brightBlack: const Color(0xFF546E7A),
                  brightRed: const Color(0xFFFF8A80),
                  brightGreen: const Color(0xFF69F0AE),
                  brightYellow: const Color(0xFFFFD740),
                  brightBlue: const Color(0xFF82B1FF),
                  brightMagenta: const Color(0xFFFF80AB),
                  brightCyan: const Color(0xFF84FFFF),
                  brightWhite: const Color(0xFFFFFFFF),
                  searchHitBackground: const Color(0x7FFFFFFF),
                  searchHitBackgroundCurrent: const Color(0x7F00E676),
                  searchHitForeground: const Color(0xFF000000),
                ),
              ),
            ),
          ),

          // Extra keyboard row for special keys (useful on mobile)
          if (!isWide) _buildMobileKeyboardBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    Color statusColor;
    String statusText;

    if (_isConnecting) {
      statusColor = const Color(0xFFFFAB40);
      statusText = '⏳ Connecting...';
    } else if (_isConnected) {
      statusColor = const Color(0xFF00E676);
      statusText = '● Connected';
    } else if (_error != null) {
      statusColor = Colors.red;
      statusText = '✗ Disconnected';
    } else {
      statusColor = Colors.grey;
      statusText = '○ Disconnected';
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF1A1A2E),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          Text(
            '${_terminal.viewWidth}×${_terminal.viewHeight}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.3),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileKeyboardBar() {
    return Container(
      height: 44,
      color: const Color(0xFF1A1A2E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SpecialKeyButton(
            label: 'TAB',
            onPressed: () => _terminal.keyInput(TerminalKey.tab),
          ),
          _SpecialKeyButton(
            label: 'ESC',
            onPressed: () => _terminal.keyInput(TerminalKey.escape),
          ),
          _SpecialKeyButton(
            label: '↑',
            onPressed: () => _terminal.keyInput(TerminalKey.arrowUp),
          ),
          _SpecialKeyButton(
            label: '↓',
            onPressed: () => _terminal.keyInput(TerminalKey.arrowDown),
          ),
          _SpecialKeyButton(
            label: '←',
            onPressed: () => _terminal.keyInput(TerminalKey.arrowLeft),
          ),
          _SpecialKeyButton(
            label: '→',
            onPressed: () => _terminal.keyInput(TerminalKey.arrowRight),
          ),
          _SpecialKeyButton(
            label: 'CTRL',
            onPressed: _sendCtrlC,
            color: const Color(0xFFFF5252),
          ),
          _SpecialKeyButton(
            label: '/',
            onPressed: () => _terminal.textInput('/'),
          ),
          _SpecialKeyButton(
            label: '|',
            onPressed: () => _terminal.textInput('|'),
          ),
          _SpecialKeyButton(
            label: '-',
            onPressed: () => _terminal.textInput('-'),
          ),
        ],
      ),
    );
  }
}

/// Special key button for the mobile keyboard bar.
class _SpecialKeyButton extends StatelessWidget {
  const _SpecialKeyButton({
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: (color ?? Colors.white).withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white.withOpacity(0.7),
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
