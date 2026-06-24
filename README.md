# OPA — OpenSSH Pocket Agent

A Flutter app that makes SSH connectivity effortless — connect to your PC and other remote machines, run terminal commands, manage SSH keys, and launch/monitor AI agent processes from your phone.

Built with **Flutter**, **dartssh2** (SSH client), and **xterm.dart** (terminal emulator).

---

## ✨ What's New in v0.2

- **🎨 Refined Dark Aesthetic** — Glassmorphism cards with frosted-glass blur, green accent glow borders, and rounded corners throughout the entire UI
- **🚀 Onboarding Flow** — 4-slide welcome experience for first-time users covering app introduction, connection setup, SSH key generation, and quick commands
- **🤖 Agent Presets Quick-Launch** — 20+ built-in presets for AI agents (Claude Code, opencode, aider, Gemini CLI, Codex…), dev tools (htop, lazygit, tmux, nvim…), and system commands — all with color-coded icons and one-tap launch
- **📱 Terminal Auto-Optimization** — Font size auto-adjusts based on screen width to fit 80+ columns in portrait and 120+ in landscape; manual pinch-to-zoom is preserved
- **🖥️ Landscape Immersive Mode** — Full-screen terminal in landscape with hidden app bar, compact keyboard bar, and immersive sticky system UI
- **💫 Animations** — Smooth fade-in, slide-up, scale, and shimmer animations on cards, screens, and interactive elements via `flutter_animate`
- **🔤 Google Fonts** — Inter for UI text, JetBrains Mono for the terminal emulator

---

## Features

### Core
- **🔌 Connection Profiles** — Save host/port/credentials for one-tap connections with per-connection color coding
- **💻 Terminal Emulator** — Interactive shell with VT100/256-color support, scrollback, auto-fit font sizing, and mobile-friendly special keys
- **🔐 Key Management** — Generate Ed25519 keys or import existing ones, stored in Android Keystore
- **⚡ Quick Commands** — Save frequently-run commands for one-tap execution, or launch from 20+ built-in agent presets

### Agent Presets (built-in)

| Category | Presets |
|---|---|
| 🤖 AI Agents | Claude Code, opencode, aider, Cursor Agent, Gemini CLI, Qwen Code, Codex, Goose |
| 🛠️ Dev Tools | htop, btop, lazygit, lazydocker, tmux, nvim, yazi |
| ⚙️ System | neofetch, systemctl status, disk usage, recent logs, uptime |

### Design
- **Glassmorphism UI** — Frosted-glass cards with backdrop blur, colored accent bars, and subtle glow shadows
- **Spring/fade animations** — Every screen transition and card appearance is smoothly animated
- **Dark theme** — Deep charcoal background with terminal-inspired green accents
- **Onboarding** — First-launch 4-slide walkthrough with Skip/Next navigation

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

# 2. Run on a connected device
flutter devices        # verify your device is listed
flutter run

# 3. Build a release APK
flutter build apk --release
```

The built APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Project Structure

```
lib/
├── main.dart                          # App entry, Hive init, SharedPreferences, theme, routing
├── app_theme.dart                     # Refined dark theme with glassmorphism (Google Fonts)
├── app_router.dart                    # GoRouter with onboarding guard + slide/fade transitions
├── models/
│   ├── connection_profile.dart         # SSH connection profile model
│   ├── ssh_key_pair.dart               # SSH key metadata model
│   └── quick_command.dart              # Saved command model (with presetId support)
├── services/
│   ├── ssh_service.dart               # dartssh2 wrapper (connect/shell/exec with resize)
│   ├── key_service.dart               # Key gen (pinenacl) + secure storage
│   ├── onboarding_service.dart         # First-launch detection (SharedPreferences)
│   ├── profile_storage_service.dart   # Hive persistence for profiles/commands
│   └── hive_adapters.dart             # Manual Hive type adapters (backward-compatible)
├── screens/
│   ├── home_screen.dart               # Connection list + quick commands + glassmorphism
│   ├── onboarding_screen.dart         # 4-slide welcome flow with animations
│   ├── terminal_screen.dart           # xterm.dart with auto-fit + landscape immersive
│   ├── profile_editor_screen.dart     # Add/edit connections (refined styling)
│   ├── key_management_screen.dart     # Generate/import/delete keys (glassmorphism)
│   └── quick_commands_screen.dart     # Manage commands + agent presets quick-launch
├── widgets/
│   ├── connection_card.dart           # Glassmorphism profile card with glow accent
│   └── key_card.dart                  # Glassmorphism key card with icon container
└── utils/
    ├── constants.dart                 # App-wide constants, colors, terminal sizing
    └── agent_presets.dart             # 20+ agent/tool preset catalog
```

---

## How to Use

### 1. Onboarding (First Launch)
- When you first open OPA, a 4-slide walkthrough introduces the app
- Tap **Skip** to go straight to the home screen, or swipe through all slides

### 2. Add a Connection
- Tap the **+** FAB on the home screen
- Enter your server's host, port (default 22), and username
- Choose an authentication method:
  - **Password** — quick and easy
  - **Key** — more secure (generate or import a key first)
  - **Both** — password + key

### 3. Set Up Key-Based Auth
- Go to **SSH Keys** (key icon in app bar)
- Tap **+** → **Generate Ed25519 Key**
- Tap the copy icon on the key card to copy the public key
- On your server, append the public key to `~/.ssh/authorized_keys`:
  ```bash
  echo "ssh-ed25519 AAAA... opa" >> ~/.ssh/authorized_keys
  ```

### 4. Connect & Use the Terminal
- Tap a connection card to open the terminal
- Font size auto-adjusts to fit your screen — 80+ columns in portrait, 120+ in landscape
- **Rotate to landscape** for immersive full-screen terminal mode
- Use the **mobile keyboard bar** at the bottom for TAB, ESC, arrows, Ctrl+C, etc.
- Pinch to zoom — auto-fit will respect your manual adjustment

### 5. Launch Agent Presets
- Go to **Quick Commands** (lightning icon)
- Browse built-in presets by category (AI Agents, Dev Tools, System)
- Tap a preset → pick a server → command launches in terminal
- Presets auto-save as quick commands on first use

### 6. Save Custom Quick Commands
- Go to **Quick Commands** → tap **+**
- Save commands you run often, optionally linked to a profile
- Example commands for AI agents:
  ```
  cd ~/projects/my-agent && python -m agent --start
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
| [`go_router`](https://pub.dev/packages/go_router) | Navigation with transitions |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | Inter + JetBrains Mono fonts |
| [`flutter_animate`](https://pub.dev/packages/flutter_animate) | Declarative animations |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Onboarding first-launch detection |

---

## Roadmap (Post-MVP)

- [ ] SFTP file browser (upload/download/manage remote files)
- [ ] Port forwarding UI (local/remote/dynamic SOCKS5)
- [ ] Jump host / bastion connection chaining
- [ ] SSH agent forwarding (requires custom implementation)
- [ ] Session recording & replay
- [ ] Snippet/profile import/export
- [ ] iOS support
- [ ] Custom preset editor (add your own agent presets)

---

## Security Notes

- **Private keys** are stored in the device's encrypted keystore (Android Keystore / iOS Keychain) via `flutter_secure_storage`.
- **Passwords** are stored in the local Hive database. For higher security, prefer key-based authentication.
- All SSH connections use the system's `Socket` API directly (no web proxy).
- The app is fully offline — no telemetry, no cloud sync.

---

## License

MIT
