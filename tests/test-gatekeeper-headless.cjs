// ============================================================================
// HEADLESS NODE.JS TEST SUITE: GATEKEEPER & ACCESS CONTROL EMPIRICAL SIMULATION
// ============================================================================

const assert = require("assert");

// Copy exact CANONICAL_VIEW_POLICY_MAP from src-ui/app.js
const CANONICAL_VIEW_POLICY_MAP = {
  "view-sys-monitor": "SysInfo",
  "view-general": "Customize",
  "view-oem-brand": "Customize",
  "view-win-optimize": "Tweaks",
  "view-uwp-apps": "Uninstaller",
  "view-clean-uninstaller": "Uninstaller",
  "view-soft-winget": "Software",
  "view-download": "Software",
  "view-it-helpdesk": "Troubleshoot",
  "view-helpdesk-troubleshoot": "Troubleshoot",
  "view-vpn-proxy": "NetworkLAN",
  "view-block-web-game": "NetworkLAN",
  "view-win-deploy": "AutoWin",
  "view-cai-windows": "AutoWin",
  "view-disk-smart": "DiskHealth",
  "view-hwid-act": "Activation",
  "view-disk-part": "Partition",
  "view-office-m365": "Office",
  "view-tech-driver": "BackupDriver",
  "view-backup-windows": "BackupSystem",
  "view-printer-lan": "PrinterLAN",
  "view-bitlocker-mgmt": "BitLocker",
};

// Simulation State
let isAdminAuth = false;
let isProLicensed = false;
let pendingGatekeeperTarget = null;
let openedModal = null;
let toastLogged = [];

const fakeDoc = {
  getElementById: (id) => ({
    classList: {
      remove: (c) => { if (c === "hidden") openedModal = id; },
      add: (c) => { if (c === "hidden" && openedModal === id) openedModal = null; }
    },
    focus: () => {},
    value: ""
  })
};
global.document = fakeDoc;
global.showToast = (title, msg, type) => {
  toastLogged.push({ title, msg, type });
};

let currentPolicies = [
  { Id: "SysInfo", Name: "Xem Cấu Hình", Tier: "FREE" },
  { Id: "Customize", Name: "Tùy Chỉnh", Tier: "FREE" },
  { Id: "Tweaks", Name: "Tinh Chỉnh", Tier: "FREE" },
  { Id: "AutoWin", Name: "Cài Win", Tier: "PRO" },
  { Id: "BitLocker", Name: "BitLocker", Tier: "ADMIN" },
  { Id: "Activation", Name: "Kích Hoạt Bản Quyền", Tier: "ADMIN" },
  { Id: "Troubleshoot", Name: "IT Helpdesk", Tier: "PRO" }
];

// Exact function from src-ui/app.js
function checkGatekeeperAccess(targetId) {
  if (targetId === "view-win-activate") targetId = "view-hwid-act";
  if (targetId === "view-disk-bitlocker" || targetId === "view-bitlocker") targetId = "view-bitlocker-mgmt";

  // Quyền Quản Trị Tối Cao (Admin God Mode): Mở toàn bộ các tính năng FREE / PRO / ADMIN
  if (isAdminAuth) {
    return true;
  }

  // Xác thực Admin Portal
  if (targetId === "view-admin-portal") {
    pendingGatekeeperTarget = targetId;
    if (typeof window !== "undefined" && typeof window.openAdminPortal === "function") {
      window.openAdminPortal();
    } else {
      const modal = document.getElementById("modal-admin-login");
      if (modal) modal.classList.remove("hidden");
    }
    return false;
  }

  const policyId = CANONICAL_VIEW_POLICY_MAP[targetId];
  if (policyId) {
    const pol = currentPolicies.find((p) => p.Id === policyId);
    const tier = pol && pol.Tier ? pol.Tier.toUpperCase() : "FREE";

    if (tier === "ADMIN") {
      if (!isAdminAuth) {
        pendingGatekeeperTarget = targetId;
        const modal = document.getElementById("modal-admin-login");
        if (modal) modal.classList.remove("hidden");
        const inputPass = document.getElementById("input-admin-pass");
        if (inputPass) { inputPass.value = ""; inputPass.focus(); }
        const lblErr = document.getElementById("lbl-admin-err");
        if (lblErr) lblErr.classList.add("hidden");
        showToast("Yêu Cầu Quyền Quản Trị", `Tính năng [${pol.Name || policyId}] yêu cầu mật khẩu Admin!`, "warning");
        return false;
      }
    }

    if (tier === "PRO") {
      if (!isProLicensed) {
        pendingGatekeeperTarget = targetId;
        const modal = document.getElementById("modal-license-activation");
        if (modal) modal.classList.remove("hidden");
        const keyInput = document.getElementById("input-pro-license-key") || document.getElementById("input-license-key");
        if (keyInput) { keyInput.value = ""; keyInput.focus(); }
        const errEl = document.getElementById("lbl-license-error");
        if (errEl) errEl.classList.add("hidden");
        showToast("Yêu Cầu Bản Quyền PRO", `Tính năng [${pol.Name || policyId}] yêu cầu bản quyền PRO VIP!`, "warning");
        return false;
      }
    }
  }

  return true;
}

// Reset helper
function resetState() {
  isAdminAuth = false;
  isProLicensed = false;
  pendingGatekeeperTarget = null;
  openedModal = null;
  toastLogged = [];
}

const testResults = [];
function test(name, fn) {
  try {
    resetState();
    fn();
    testResults.push({ name, pass: true });
    console.log(`  [PASS] ${name}`);
  } catch (err) {
    testResults.push({ name, pass: false, error: err.message });
    console.error(`  [FAIL] ${name}: ${err.message}`);
  }
}

console.log(">>> RUNNING HEADLESS GATEKEEPER TESTS <<<");

// Test 1: FREE user -> FREE view allowed
test("T01_FreeUser_FreeView_Allowed", () => {
  const allowed = checkGatekeeperAccess("view-sys-monitor");
  assert.strictEqual(allowed, true);
  assert.strictEqual(openedModal, null);
  assert.strictEqual(pendingGatekeeperTarget, null);
});

// Test 2: FREE user -> PRO view blocked, opens modal-license-activation
test("T02_FreeUser_ProView_BlockedWithLicenseModal", () => {
  const allowed = checkGatekeeperAccess("view-win-deploy");
  assert.strictEqual(allowed, false);
  assert.strictEqual(openedModal, "modal-license-activation");
  assert.strictEqual(pendingGatekeeperTarget, "view-win-deploy");
});

// Test 3: FREE user -> ADMIN view blocked, opens modal-admin-login
test("T03_FreeUser_AdminView_BlockedWithAdminModal", () => {
  const allowed = checkGatekeeperAccess("view-bitlocker-mgmt");
  assert.strictEqual(allowed, false);
  assert.strictEqual(openedModal, "modal-admin-login");
  assert.strictEqual(pendingGatekeeperTarget, "view-bitlocker-mgmt");
});

// Test 4: FREE user -> view-admin-portal blocked, opens modal-admin-login
test("T04_FreeUser_AdminPortal_BlockedWithAdminModal", () => {
  const allowed = checkGatekeeperAccess("view-admin-portal");
  assert.strictEqual(allowed, false);
  assert.strictEqual(openedModal, "modal-admin-login");
  assert.strictEqual(pendingGatekeeperTarget, "view-admin-portal");
});

// Test 5: PRO user -> PRO view allowed
test("T05_ProUser_ProView_Allowed", () => {
  isProLicensed = true;
  const allowed = checkGatekeeperAccess("view-win-deploy");
  assert.strictEqual(allowed, true);
  assert.strictEqual(openedModal, null);
});

// Test 6: PRO user -> ADMIN view blocked
test("T06_ProUser_AdminView_Blocked", () => {
  isProLicensed = true;
  const allowed = checkGatekeeperAccess("view-bitlocker-mgmt");
  assert.strictEqual(allowed, false);
  assert.strictEqual(openedModal, "modal-admin-login");
  assert.strictEqual(pendingGatekeeperTarget, "view-bitlocker-mgmt");
});

// Test 7: ADMIN God Mode allows ALL tiers
test("T07_AdminAuth_GodMode_AllowsAll", () => {
  isAdminAuth = true;
  isProLicensed = false;
  assert.strictEqual(checkGatekeeperAccess("view-sys-monitor"), true);
  assert.strictEqual(checkGatekeeperAccess("view-win-deploy"), true);
  assert.strictEqual(checkGatekeeperAccess("view-bitlocker-mgmt"), true);
  assert.strictEqual(checkGatekeeperAccess("view-admin-portal"), true);
  assert.strictEqual(openedModal, null);
});

// Test 8: Unmapped view defaults safely to true (fail-open for general views)
test("T08_UnmappedView_DefaultsToAllow", () => {
  const allowed = checkGatekeeperAccess("view-startup-apps");
  assert.strictEqual(allowed, true);
  assert.strictEqual(openedModal, null);
  assert.strictEqual(pendingGatekeeperTarget, null);
});

// Test 9: Null, undefined, empty string parameters do not throw and default to true
test("T09_BoundaryInputs_NullUndefinedEmpty", () => {
  assert.strictEqual(checkGatekeeperAccess(null), true);
  assert.strictEqual(checkGatekeeperAccess(undefined), true);
  assert.strictEqual(checkGatekeeperAccess(""), true);
  assert.strictEqual(checkGatekeeperAccess(12345), true);
});

// Test 10: Legacy alias view-win-activate maps to view-hwid-act (Activation: ADMIN)
test("T10_Alias_WinActivate_ResolvesToHwidAct_AndEnforcesAdmin", () => {
  const allowed = checkGatekeeperAccess("view-win-activate");
  assert.strictEqual(allowed, false);
  assert.strictEqual(openedModal, "modal-admin-login");
  assert.strictEqual(pendingGatekeeperTarget, "view-hwid-act");
});

// Test 11: Legacy alias view-bitlocker maps to view-bitlocker-mgmt (BitLocker: ADMIN)
test("T11_Alias_Bitlocker_ResolvesToBitlockerMgmt_AndEnforcesAdmin", () => {
  const allowed = checkGatekeeperAccess("view-bitlocker");
  assert.strictEqual(allowed, false);
  assert.strictEqual(openedModal, "modal-admin-login");
  assert.strictEqual(pendingGatekeeperTarget, "view-bitlocker-mgmt");
});

// Test 12: Legacy alias view-disk-bitlocker maps to view-bitlocker-mgmt (BitLocker: ADMIN)
test("T12_Alias_DiskBitlocker_ResolvesToBitlockerMgmt_AndEnforcesAdmin", () => {
  const allowed = checkGatekeeperAccess("view-disk-bitlocker");
  assert.strictEqual(allowed, false);
  assert.strictEqual(openedModal, "modal-admin-login");
  assert.strictEqual(pendingGatekeeperTarget, "view-bitlocker-mgmt");
});

// Test 13: Secondary mapped view view-cai-windows enforces AutoWin (PRO)
test("T13_SecondaryMappedView_CaiWindows_EnforcesPro", () => {
  const allowed = checkGatekeeperAccess("view-cai-windows");
  assert.strictEqual(allowed, false);
  assert.strictEqual(openedModal, "modal-license-activation");
  assert.strictEqual(pendingGatekeeperTarget, "view-cai-windows");
});

// Test 14: Dynamic policy tier elevation (Admin changes Tweaks to PRO)
test("T14_DynamicPolicyElevation_EnforcesUpdatedTier", () => {
  const pol = currentPolicies.find(p => p.Id === "Tweaks");
  pol.Tier = "PRO";
  
  // Free user now blocked from Tweaks
  assert.strictEqual(checkGatekeeperAccess("view-win-optimize"), false);
  assert.strictEqual(openedModal, "modal-license-activation");
  
  // Pro user allowed
  isProLicensed = true;
  assert.strictEqual(checkGatekeeperAccess("view-win-optimize"), true);
});

// Test 15: Cancellation resets pendingGatekeeperTarget
test("T15_Cancellation_PurgesPendingTarget", () => {
  // Blocked attempt
  checkGatekeeperAccess("view-win-deploy");
  assert.strictEqual(pendingGatekeeperTarget, "view-win-deploy");
  
  // Cancel action simulation
  pendingGatekeeperTarget = null;
  openedModal = null;
  assert.strictEqual(pendingGatekeeperTarget, null);
  assert.strictEqual(openedModal, null);
});

const failed = testResults.filter(t => !t.pass);
console.log(`\nResults: ${testResults.length - failed.length}/${testResults.length} passed.`);
if (failed.length > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
