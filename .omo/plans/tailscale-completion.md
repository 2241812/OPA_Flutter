# OPA Tailscale - Completion Plan

How to use: continue phase N to execute.

---

## Phase 1 - Auth Key UI and Critical Runtime Fixes (~55 min)

1.1: Auth key TextField in profile editor (masked, Tailscale-only)
1.2: Mutex + timeout in _ensureUp()
1.3: try/catch around Tailscale dial in terminal, quick commands, test
1.4: Proactive up() after auth key save, ephemeral: false
1.5: Key-once semantics (disk credentials for reconnects)

## Phase 2 - Status Indicators and User Feedback (~40 min)

2.1: Tailscale node status indicator on connection cards
2.2: Auth URL surfacing when needsLogin
2.3: Connection method badge (Tailscale vs Direct)
2.4: Host validation hint for Tailscale addresses

## Phase 3 - Node Lifecycle Management (~45 min)

3.1: Tailscale settings section with logout and re-auth
3.2: Riverpod state provider for onStateChange
3.3: Auto-retry on network recovery / app foreground

## Phase 4 - Hardening and Edge Cases (~40 min)

4.1: Specific error messages per failure type
4.2: Unit tests for TailscaleService
4.3: Background lifecycle decision
