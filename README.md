<div align="center">

<img src="https://raw.githubusercontent.com/2241812/OPA_Flutter/main/assets/icon.png" alt="OPA Logo" width="120" height="120">

# ⬡ OPA — OpenSSH Pocket Agent

**Connect to any machine from your phone. Run terminals, manage keys, and launch agents — all in one pocket-sized app.**

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://github.com/2241812/OPA_Flutter/releases)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## ✨ What's New

### v0.2 — Onboarding, Presets & Polish
- 🎨 **Refined Dark Aesthetic** — Glassmorphism cards with frosted-glass blur, green accent glow borders, and rounded corners throughout
- 🚀 **Onboarding Flow** — 4-slide welcome experience for first-time users
- 🤖 **Agent Presets** — 20+ built-in quick-launch presets for AI agents, dev tools, and system commands
- 📱 **Terminal Auto-Optimization** — Font auto-adjusts for 80+ cols portrait / 120+ landscape
- 🖥️ **Landscape Immersive Mode** — Full-screen terminal with hidden app bar
- 💫 **Animations** — Smooth fade-in, slide-up, scale, and shimmer animations everywhere
- 🔤 **Google Fonts** — Inter for UI, JetBrains Mono for terminal
- 🔔 **In-App Update Checker** — Automatically notifies you when a new version is available

---

## Features

| Category | Highlights |
|----------|-----------|
| 🔌 **Connections** | Save host/port/credentials for one-tap SSH connections with per-connection color coding |
| 💻 **Terminal** | Interactive shell with VT100/256-color, scrollback, auto-fit font, and mobile special keys |
| 🔐 **Key Management** | Generate Ed25519 keys or import existing ones, stored in Android Keystore |
| ⚡ **Quick Commands** | Save frequently-run commands for one-tap execution |
| 🤖 **Agent Presets** | Claude Code, opencode, aider, Gemini CLI, Codex, htop, lazygit, tmux, nvim, and more |

---

## Install

Grab the latest release APK from [GitHub Releases](https://github.com/2241812/OPA_Flutter/releases/latest).

> **Auto-updates:** OPA checks for new versions on every launch. If an update is available, you'll get a prompt to download the latest APK directly.

<details>
<summary>📦 Build from Source</summary>

```bash
# Prerequisites: Flutter SDK ≥3.0

# 1. Clone & install deps
git clone https://github.com/2241812/OPA_Flutter.git
cd OPA_Flutter
flutter pub get

# 2. Run on a connected device
flutter devices
flutter run

# 3. Build a release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

</details>

---

## Screenshots

<div align="center">
  <table>
    <tr>
      <td><b>Home Screen</b></td>
      <td><b>Terminal</b></td>
      <td><b>Key Management</b></td>
    </tr>
    <tr>
      <td width="33%"><i>Connection profiles & quick commands</i></td>
      <td width="33%"><i>Full SSH terminal with auto-fit</i></td>
      <td width="33%"><i>Generate & manage SSH keys</i></td>
    </tr>
  </table>
</div>

---

## Project Structure

```
lib/
├── main.dart                          # App entry, Hive init, theme, routing
├── app_theme.dart                     # Dark theme with glassmorphism
├── app_router.dart                    # GoRouter with onboarding guard
├── models/
│   ├── connection_profile.dart        # SSH connection profile model
│   ├── ssh_key_pair.dart              # SSH key metadata model
│   └── quick_command.dart             # Saved command model
├── services/
│   ├── ssh_service.dart               # dartssh2 wrapper
│   ├── key_service.dart               # Key gen + secure storage
│   ├── onboarding_service.dart        # First-launch detection
│   ├── update_service.dart            # GitHub Releases update checker
│   ├── profile_storage_service.dart   # Hive persistence
│   └── hive_adapters.dart             # Manual Hive type adapters
├── screens/
│   ├── home_screen.dart               # Connections list + quick commands
│   ├── onboarding_screen.dart         # 4-slide welcome flow
│   ├── terminal_screen.dart           # xterm.dart with auto-fit
│   ├── profile_editor_screen.dart     # Add/edit connections
│   ├── key_management_screen.dart     # Generate/import/delete keys
│   └── quick_commands_screen.dart     # Manage commands + agent presets
├── widgets/
│   ├── connection_card.dart            # Glassmorphism profile card
│   └── key_card.dart                   # Glassmorphism key card
└── utils/
    ├── constants.dart                  # App-wide constants & colors
    ├── agent_presets.dart              # 20+ agent/tool preset catalog
    └── ssh_key_encoder.dart            # Ed25519 key encoding
```

---

## How to Use

### 1. First Launch
A 4-slide onboarding walkthrough introduces the app. Tap **Skip** or swipe through.

### 2. Add a Connection
Tap the **+** FAB → enter host, port (default 22), and username → choose auth:
- **Password** — quick and easy
- **Key** — more secure (generate or import a key first)
- **Both** — password + key

### 3. Set Up Key-Based Auth
1. Go to **SSH Keys** (key icon) → tap **+** → **Generate Ed25519 Key**
2. Copy the public key
3. On your server, append it to `~/.ssh/authorized_keys`:
   ```bash
   echo "ssh-ed25519 AAAA... opa" >> ~/.ssh/authorized_keys
   ```

### 4. Connect & Use Terminal
- Tap a connection card to open the terminal
- Font auto-adjusts — 80+ cols portrait, 120+ landscape
- Rotate to landscape for immersive full-screen mode
- Use the keyboard bar for TAB, ESC, arrows, Ctrl+C

### 5. Launch Agent Presets
- Go to **Quick Commands** (lightning icon)
- Browse built-in presets by category
- Tap a preset → pick a server → command launches in terminal

---

## Target PC SSH Setup

<details>
<summary><b>🖥️ Windows (OpenSSH Server)</b></summary>

```powershell
# Install OpenSSH Server (run as admin)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Find your IP
ipconfig
```

</details>

<details>
<summary><b>🐧 Linux / macOS</b></summary>

```bash
# Linux (Debian/Ubuntu)
sudo apt install openssh-server
sudo systemctl enable --now ssh

# macOS: System Settings → General → Sharing → Remote Login
```

</details>

---

## Key Dependencies

| Package | Purpose |
|---------|---------|
| [`dartssh2`](https://pub.dev/packages/dartssh2) | SSH client (auth, shell, exec, SFTP) |
| [`xterm`](https://pub.dev/packages/xterm) | Terminal emulator widget |
| [`pinenacl`](https://pub.dev/packages/pinenacl) | Ed25519 key generation |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Encrypted private key storage |
| [`hive`](https://pub.dev/packages/hive) | Local NoSQL storage |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | State management |
| [`go_router`](https://pub.dev/packages/go_router) | Navigation with transitions |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | Inter + JetBrains Mono |
| [`flutter_animate`](https://pub.dev/packages/flutter_animate) | Declarative animations |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | Open APK download links |

---

## Roadmap

- [ ] SFTP file browser (upload/download/manage remote files)
- [ ] Port forwarding UI (local/remote/dynamic SOCKS5)
- [ ] Jump host / bastion connection chaining
- [ ] SSH agent forwarding
- [ ] Session recording & replay
- [ ] Snippet/profile import/export
- [ ] iOS support
- [ ] Custom preset editor

---

## Security Notes

- **Private keys** are stored in the device's encrypted keystore (Android Keystore / iOS Keychain)
- **Passwords** are stored in the local Hive database — prefer key-based auth for higher security
- All SSH connections use direct socket connections (no proxy)
- Fully offline — no telemetry, no cloud sync

---

<div align="center">

## License

[MIT](LICENSE) · Built with ❤️ by [Renzo Javier](https://github.com/2241812)

</div>
