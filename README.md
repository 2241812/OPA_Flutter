# OPA — OpenSSH Pocket Agent

A Flutter app that makes SSH connectivity effortless — connect to your PC and other remote machines, run terminal commands, manage SSH keys, and launch/monitor AI agent processes from your phone.

Built with **Flutter**, **dartssh2** (SSH client), and **xterm.dart** (terminal emulator).

---

## Features (MVP v0.1)

- **🔌 Connection Profiles** — Save host/port/credentials for one-tap connections
- **💻 Terminal Emulator** — Interactive shell with VT100/256-color support, scrollback, mobile-friendly special keys
- **🔐 Key Management** — Generate Ed25519 keys or import existing ones, stored in Android Keystore
- **⚡ Quick Commands** — Save frequently-run commands (e.g. launching agent harnesses) for one-tap execution
- **🎨 Dark theme** — Terminal-inspired UI with per-connection color coding

---

## Getting Started

### Prerequisites

- **Flutter SDK** (latest stable, ≥3.0) — [install guide](https://docs.flutter.dev/get-started/install)
- **Android Studio** or VS Code with the Flutter extension
- An **Android device** (recommended) or emulator
- A **target machine** running an SSH server (OpenSSH on Windows/Linux/macOS)

### Install & Run

```bash
# 1. Install dependencies
flutter pub get

# 2. (Optional) Generate Hive adapters — but we ship manual adapters,
#    so code generation is not required for the MVP.
# dart run build_runner build --delete-conflicting-outputs

# 3. Run on a connected device
flutter devices        # verify your device is listed
flutter run

# 4. Build a release APK
flutter build apk --release
```

The built APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Project Structure

```
lib/
├── main.dart                          # App entry, Hive init, theme, routing
├── app_theme.dart                     # Dark terminal-inspired theme
├── app_router.dart                    # GoRouter configuration
├── models/
│   ├── connection_profile.dart         # SSH connection profile model
│   ├── ssh_key_pair.dart               # SSH key metadata model
│   └── quick_command.dart              # Saved command model
├── services/
│   ├── ssh_service.dart               # dartssh2 wrapper (connect/shell/exec)
│   ├── key_service.dart               # Key gen (pinenacl) + secure storage
│   ├── profile_storage_service.dart   # Hive persistence for profiles/commands
│   └── hive_adapters.dart             # Manual Hive type adapters
├── screens/
│   ├── home_screen.dart               # Connection list + quick commands
│   ├── terminal_screen.dart           # xterm.dart terminal view
│   ├── profile_editor_screen.dart     # Add/edit connections
│   ├── key_management_screen.dart     # Generate/import/delete keys
│   └── quick_commands_screen.dart     # Manage saved commands
├── widgets/
│   ├── connection_card.dart           # Profile card + color palette
│   └── key_card.dart                  # Key card with copy/delete
└── utils/
    └── constants.dart                 # App-wide constants
```

---

## How to Use

### 1. Add a Connection
- Tap the **+** FAB on the home screen
- Enter your server's host, port (default 22), and username
- Choose an authentication method:
  - **Password** — quick and easy
  - **Key** — more secure (generate or import a key first)
  - **Both** — password + key

### 2. Set Up Key-Based Auth
- Go to **SSH Keys** (key icon in app bar)
- Tap **+** → **Generate Ed25519 Key**
- Tap the copy icon on the key card to copy the public key
- On your server, append the public key to `~/.ssh/authorized_keys`:
  ```bash
  echo "ssh-ed25519 AAAA... opa" >> ~/.ssh/authorized_keys
  ```

### 3. Connect & Run Commands
- Tap a connection card to open the terminal
- Use the **mobile keyboard bar** at the bottom for TAB, ESC, arrows, Ctrl+C, etc.
- Pinch to zoom the font size

### 4. Save Quick Commands
- Go to **Quick Commands** (lightning icon)
- Save commands you run often, optionally linked to a profile
- Example commands for AI agents:
  ```
  cd ~/projects/my-agent && python -m agent --start
  zcode --version
  tmux new -s agents
  ```

---

## Target PC SSH Setup

### Windows (OpenSSH Server)
```powershell
# Install OpenSSH Server (run as admin)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Find your IP
ipconfig
```

### Linux / macOS
```bash
# Linux (Debian/Ubuntu)
sudo apt install openssh-server
sudo systemctl enable --now ssh

# macOS: System Settings → General → Sharing → Remote Login
```

---

## Key Dependencies

| Package | Purpose |
|---|---|
| [`dartssh2`](https://pub.dev/packages/dartssh2) | SSH client (auth, shell, exec, SFTP) |
| [`xterm`](https://pub.dev/packages/xterm) | Terminal emulator widget |
| [`pinenacl`](https://pub.dev/packages/pinenacl) | Ed25519 key generation |
| [`ssh_key`](https://pub.dev/packages/ssh_key) | OpenSSH key format encode/decode |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Encrypted private key storage |
| [`hive`](https://pub.dev/packages/hive) | Local NoSQL storage for profiles |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | State management |
| [`go_router`](https://pub.dev/packages/go_router) | Navigation |

---

## Roadmap (Post-MVP)

- [ ] SFTP file browser (upload/download/manage remote files)
- [ ] Port forwarding UI (local/remote/dynamic SOCKS5)
- [ ] Jump host / bastion connection chaining
- [ ] SSH agent forwarding (requires custom implementation)
- [ ] Session recording & replay
- [ ] Snippet/profile import/export
- [ ] iOS support

---

## Security Notes

- **Private keys** are stored in the device's encrypted keystore (Android Keystore / iOS Keychain) via `flutter_secure_storage`.
- **Passwords** are stored in the local Hive database. For higher security, prefer key-based authentication.
- All SSH connections use the system's `Socket` API directly (no web proxy).
- The app is fully offline — no telemetry, no cloud sync.

---

## License

MIT
