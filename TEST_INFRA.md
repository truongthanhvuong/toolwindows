# VUONGTT Toolkit 2026 — Test Infrastructure Specification (TEST_INFRA)

## 1. Overview & Objectives
This document establishes the test architecture, feature inventory, 4-tier testing methodology, and quality thresholds for the VUONGTT Toolkit 2026 Core Upgrades & Defect Remediation release (v20.5.909.180).

The testing infrastructure ensures 100% opaque-box, requirement-driven verification across all 4 core pillars:
- **R1: Anti-Bypass Website/Game Blocker Engine**
- **R2: PRO & ADMIN Gatekeeper Access Control**
- **R3: Universal Real-time Execution Log Drawer**
- **R4: Windows Tối Ưu Extensions**

---

## 2. Four-Tier Testing Methodology

```
┌─────────────────────────────────────────────────────────────┐
│ Tier 4: Real-World Application Scenarios (E2E User Journeys)│
├─────────────────────────────────────────────────────────────┤
│ Tier 3: Cross-Feature Interactions & Multi-State Transition │
├─────────────────────────────────────────────────────────────┤
│ Tier 2: Boundary Conditions, Edge Cases & Negative Testing  │
├─────────────────────────────────────────────────────────────┤
│ Tier 1: Canonical Feature Coverage (Happy Path Verification) │
└─────────────────────────────────────────────────────────────┘
```

### Tier 1: Canonical Feature Coverage
- Verifies primary functionality (happy path) for each requirement.
- Asserts that UI elements, frontend controller functions, backend IPC routes, and system execution logic adhere strictly to specifications.
- Validates direct input-to-output transformations, deterministic return codes, and expected schema formats.

### Tier 2: Boundary Conditions & Negative Inputs
- Tests empty strings, null inputs, malformed JSON, unselected options, and missing registry parent keys.
- Asserts idempotent execution (calling apply twice, unblocking when already unblocked).
- Validates exception handling, error boundary protection, and safe fallback mechanisms.

### Tier 3: Cross-Feature Combinations & State Machine Transitions
- Verifies interactions between disparate subsystems:
  - R1: Blocker hosts modification combined with Registry DoH policy override and Windows Firewall Outbound filtering.
  - R2: Tier transitions between FREE, PRO, and ADMIN states; privilege revocation upon Admin logout; modal dismissals and target view redirection.
  - R3: Real-time log streaming active while executing heavy operations (Windows Update toggle, hosts rewrite, driver extraction).
  - R4: Multi-toggle states in Windows Tối Ưu (Classic Menu + Update Disabled + Extensions Shown + Bing Search Disabled) without state cross-contamination.

### Tier 4: Real-World Application Scenarios
- End-to-end user workflows matching production usage:
  - *Scenario A*: Parent blocks Facebook/Messenger -> Browsers closed, DoH policies locked, firewall rules activated, DNS flushed -> User attempts bypass -> System blocks -> Parent unblocks -> Clean restoration of browser, registry, firewall, and hosts without reboot.
  - *Scenario B*: Non-licensed user attempts accessing PRO feature -> Intercepted -> HWID displayed -> Enters valid License Key -> Instant unlock -> Target view opens.
  - *Scenario C*: Unauthorized user navigates to ADMIN feature -> Intercepted -> Admin Login Modal displayed -> Authenticates -> Instant unlock -> Target view opens -> Logout revokes access.
  - *Scenario D*: System technician executes multiple optimization tweaks -> Universal Log Drawer auto-expands -> Streams output timestamps and execution messages -> Technician copies logs to clipboard and clears console.

---

## 3. Feature Inventory & Requirement Traceability Matrix

| Req | Feature ID | Name | Test Suite | Tier Coverage |
|:---:|:---:|:---|:---|:---:|
| **R1** | F01 | DoH Registry Policies (`Google\Chrome` & `Microsoft\Edge`) | `Test-AntiBypassBlocker.Tests.ps1` | T1, T2, T3, T4 |
| **R1** | F02 | 17 Facebook & Messenger Domains Blocking | `Test-AntiBypassBlocker.Tests.ps1` | T1, T2, T3, T4 |
| **R1** | F03 | Windows Firewall Outbound Rule `VUONGTT_Block_Facebook` | `Test-AntiBypassBlocker.Tests.ps1` | T1, T2, T3, T4 |
| **R1** | F04 | Socket/Process Termination (`chrome`, `msedge`, `brave`, `opera`) | `Test-AntiBypassBlocker.Tests.ps1` | T1, T3, T4 |
| **R1** | F05 | DNS Cache Flush (`ipconfig /flushdns` & `Clear-DnsClientCache`) | `Test-AntiBypassBlocker.Tests.ps1` | T1, T3, T4 |
| **R1** | F06 | Clean Unblock Restoration (Hosts, Registry, Firewall, DNS) | `Test-AntiBypassBlocker.Tests.ps1` | T1, T2, T3, T4 |
| **R2** | F07 | Navigation Gatekeeper in `switchView` | `Test-GatekeeperPolicy.Tests.ps1` | T1, T2, T3, T4 |
| **R2** | F08 | PRO License Modal `#modal-license-activation` & HWID | `Test-GatekeeperPolicy.Tests.ps1` | T1, T2, T3, T4 |
| **R2** | F09 | Backend Endpoints `check_pro_license` & `activate_pro_key` | `Test-GatekeeperPolicy.Tests.ps1` | T1, T2, T3, T4 |
| **R2** | F10 | ADMIN Modal `#modal-admin-login` & Session Gatekeeping | `Test-GatekeeperPolicy.Tests.ps1` | T1, T2, T3, T4 |
| **R2** | F11 | Immediate Unlocking via `pendingGatekeeperTarget` | `Test-GatekeeperPolicy.Tests.ps1` | T1, T3, T4 |
| **R2** | F12 | Startup License & Policy Synchronization (`initGatekeeper`) | `Test-GatekeeperPolicy.Tests.ps1` | T1, T2, T3, T4 |
| **R3** | F13 | Universal Floating Log Drawer UI Container & Theme | `Test-UniversalLogDrawer.Tests.ps1` | T1, T2, T3, T4 |
| **R3** | F14 | Control Buttons: Toggle Expand/Collapse, Copy, Clear | `Test-UniversalLogDrawer.Tests.ps1` | T1, T2, T3, T4 |
| **R3** | F15 | Real-time Polling Bridge (`get_install_logs`, 800ms) | `Test-UniversalLogDrawer.Tests.ps1` | T1, T2, T3, T4 |
| **R3** | F16 | Auto-Scroll & Delta Log Rendering | `Test-UniversalLogDrawer.Tests.ps1` | T1, T2, T3, T4 |
| **R3** | F17 | Global Logging Helper `window.appendUniversalLog` | `Test-UniversalLogDrawer.Tests.ps1` | T1, T2, T3, T4 |
| **R3** | F18 | Auto-Expand Drawer on Action Dispatch | `Test-UniversalLogDrawer.Tests.ps1` | T1, T3, T4 |
| **R4** | F19 | Classic Context Menu Toggle on Windows 11 | `Test-WinOptimizeExtensions.Tests.ps1` | T1, T2, T3, T4 |
| **R4** | F20 | 1-Click Windows Update Toggle (`wuauserv`, `UsoSvc`, `WaaSMedicSvc`, `NoAutoUpdate`) | `Test-WinOptimizeExtensions.Tests.ps1` | T1, T2, T3, T4 |
| **R4** | F21 | Show / Hide File Extensions Toggle (`HideFileExt` & Shell Refresh) | `Test-WinOptimizeExtensions.Tests.ps1` | T1, T2, T3, T4 |
| **R4** | F22 | Disable / Enable Bing Search in Start Menu (`DisableSearchBoxSuggestions`) | `Test-WinOptimizeExtensions.Tests.ps1` | T1, T2, T3, T4 |
| **R4** | F23 | System Optimize State Query (`get_win_optimize_state`) | `Test-WinOptimizeExtensions.Tests.ps1` | T1, T2, T3, T4 |

---

## 4. Test Suite Architecture & Conventions

### 4.1 Test Suites Location & Naming
All test suites reside in `E:\toolwindows\tests\` and adhere to the project standard naming format `*.Tests.ps1`:
1. `tests/Test-AntiBypassBlocker.Tests.ps1`
2. `tests/Test-GatekeeperPolicy.Tests.ps1`
3. `tests/Test-UniversalLogDrawer.Tests.ps1`
4. `tests/Test-WinOptimizeExtensions.Tests.ps1`

### 4.2 Test Runner Integration
Every test suite is directly compatible with `Run-AllTests.ps1`.
- Executes via `powershell -NoProfile -ExecutionPolicy Bypass -File tests\<Suite>.Tests.ps1`.
- Self-contained assertion harness:
  ```powershell
  $script:testsPassed = 0
  $script:testsFailed = 0
  function Assert-Condition([string]$TestName, [bool]$Condition, [string]$Message = "") { ... }
  ```
- Exits with `0` on 100% pass, or `1` if any test fails.

### 4.3 Static AST & Opaque-Box Isolation
- Tests perform rigorous AST parsing (`[System.Management.Automation.Language.Parser]::ParseFile`) to verify syntax compliance.
- Tests verify interface contracts, HTML DOM elements, JavaScript closures, and Rust backend routes without modifying production binaries.
- Tests that verify live Windows API or Registry paths use mock-safe or non-destructive techniques when executing in testing/CI contexts.

---

## 5. Quality Gate Thresholds

Before declaring `TEST_READY.md`:
1. **Pass Rate**: 100% PASS (0 failures, 0 skipped, 0 warnings) across all 4 suites.
2. **Syntax Integrity**: 0 AST parse errors across all PowerShell test and script files.
3. **Execution Time**: Each test suite must complete within < 30 seconds.
4. **Regression Safety**: All existing 84+ test suites in `tests/` continue to report `[PASS SUITE]`.
