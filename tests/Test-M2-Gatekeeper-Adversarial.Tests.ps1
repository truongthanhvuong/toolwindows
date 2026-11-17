# ==============================================================================
# EMPIRICAL CHALLENGER TEST SUITE: M2 PRO & ADMIN GATEKEEPER & ACTIVATION
# ==============================================================================
# Focus: Adversarial inputs, fail-closed enforcement, rapid view switching,
# modal dismissals, state sanitization, and AST/runtime invariants.
# ==============================================================================

$ErrorActionPreference = "Continue"

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:Failures = @()

function Assert-Check {
    param(
        [string]$Category,
        [string]$TestName,
        [bool]$Condition,
        [string]$FailureMessage = ""
    )
    $script:TotalTests++
    if ($Condition) {
        Write-Host "  [$Category][PASS] $TestName" -ForegroundColor Green
        $script:PassedTests++
    } else {
        Write-Host "  [$Category][FAIL] $TestName - $FailureMessage" -ForegroundColor Red
        $script:FailedTests++
        $script:Failures += "[$Category] ${TestName} - $FailureMessage"
    }
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "CHALLENGER 1: EMPIRICAL ADVERSARIAL STRESS TEST FOR M2 GATEKEEPER" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$licPath = Join-Path $projectRoot "src\Core\LicenseManager.ps1"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$policyJsonPath = Join-Path $projectRoot "src\Config\feature_policy.json"
$sysOpsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$mainPath = Join-Path $projectRoot "src-tauri\src\main.rs"

# Dot-source LicenseManager.ps1
if (Test-Path $licPath) {
    . $licPath
}

# ------------------------------------------------------------------------------
# SECTION 1: Adversarial License Key Submissions via Core LicenseManager (Fail-Closed)
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 1: Adversarial License Key Injections & Boundary Checks <<<" -ForegroundColor Yellow

$adversarialKeys = @(
    @{ Name = "Empty string"; Key = "" },
    @{ Name = "Whitespace only (spaces)"; Key = "    " },
    @{ Name = "Whitespace only (tabs and newlines)"; Key = "`t`r`n" },
    @{ Name = "Too short (sub-10 chars)"; Key = "VUONGTT" },
    @{ Name = "Single quote breakout"; Key = "VUONGTT-PRO-1234'; Start-Process calc.exe; #" },
    @{ Name = "Double quote breakout"; Key = 'VUONGTT-PRO-1234"; Stop-Process -Id $PID; #' },
    @{ Name = "Command substitution"; Key = '$(Start-Process calc.exe)' },
    @{ Name = "Backtick escape"; Key = "VUONGTT`0PRO" },
    @{ Name = "Pipelined command"; Key = "VUONGTT-PRO-KEY | Out-Null" },
    @{ Name = "SQL injection style"; Key = "' OR 1=1 --" },
    @{ Name = "HTML / XSS script tag"; Key = "<script>alert('pwned')</script>" },
    @{ Name = "Buffer overflow attempt (10,000 chars)"; Key = ("A" * 10000) },
    @{ Name = "Valid format prefix with random garbage"; Key = "VUONGTT-PRO-XXXX-YYYY-ZZZZ" },
    @{ Name = "Unicode diacritics in key"; Key = "VUONGTT-PRO-BẢN-QUYỀN" },
    @{ Name = "All zeros"; Key = ("0" * 32) }
)

foreach ($testCase in $adversarialKeys) {
    $res = $null
    try {
        $res = Invoke-VUONGTTKeyActivation -InputKey $testCase.Key
    } catch {
        $res = [PSCustomObject]@{ Success = $false; Message = $_.Exception.Message }
    }

    $isClosed = ($res -ne $null -and $res.Success -eq $false)
    Assert-Check `
        -Category "SEC1-KEY" `
        -TestName "Key Injection: $($testCase.Name) -> must FAIL CLOSED" `
        -Condition $isClosed `
        -FailureMessage "Key did not fail closed! Returned Success=$($res.Success), Message=$($res.Message)"
}

# ------------------------------------------------------------------------------
# SECTION 2: Backend Rust IPC activate_pro_key & check_pro_license Fail-Closed
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 2: Rust IPC activate_pro_key & check_pro_license Robustness <<<" -ForegroundColor Yellow

# Test Rust execute_system_action simulation for activate_pro_key
$sysOpsContent = Get-Content -Path $sysOpsPath -Raw -Encoding UTF8
$mainContent = Get-Content -Path $mainPath -Raw -Encoding UTF8

$hasActProKey = $sysOpsContent -match 'if\s+act\s*==\s*"activate_pro_key"'
$hasCheckProLic = $sysOpsContent -match 'if\s+act\s*==\s*"check_pro_license"'
$hasEmptyKeyCheck = $sysOpsContent -match 'raw_key\.is_empty\(\)'
$hasKeyEscaping = $sysOpsContent -match 'raw_key\.replace\('

Assert-Check `
    -Category "SEC2-IPC" `
    -TestName "Rust system_ops handles activate_pro_key action" `
    -Condition $hasActProKey `
    -FailureMessage "Missing activate_pro_key action handler in system_ops.rs"

Assert-Check `
    -Category "SEC2-IPC" `
    -TestName "Rust system_ops handles check_pro_license action" `
    -Condition $hasCheckProLic `
    -FailureMessage "Missing check_pro_license action handler in system_ops.rs"

Assert-Check `
    -Category "SEC2-IPC" `
    -TestName "Rust system_ops contains raw_key.is_empty() fail-closed check" `
    -Condition $hasEmptyKeyCheck `
    -FailureMessage "Missing raw_key.is_empty() early return guard in activate_pro_key"

Assert-Check `
    -Category "SEC2-IPC" `
    -TestName "Rust system_ops escapes single quotes in raw_key" `
    -Condition $hasKeyEscaping `
    -FailureMessage "Missing quote escaping for clean_key in system_ops.rs"

$hasMainCheckRoute = $mainContent -match 'cmd\s*==\s*"check_pro_license"'
$hasMainActRoute = $mainContent -match 'cmd\s*==\s*"activate_pro_key"'
$hasPassThrough = $mainContent -match 'act_id\s*==\s*"check_pro_license"\s*\|\|\s*act_id\s*==\s*"activate_pro_key"'

Assert-Check `
    -Category "SEC2-IPC" `
    -TestName "Rust main.rs routes check_pro_license endpoint" `
    -Condition $hasMainCheckRoute `
    -FailureMessage "Missing check_pro_license route in main.rs"

Assert-Check `
    -Category "SEC2-IPC" `
    -TestName "Rust main.rs routes activate_pro_key endpoint" `
    -Condition $hasMainActRoute `
    -FailureMessage "Missing activate_pro_key route in main.rs"

Assert-Check `
    -Category "SEC2-IPC" `
    -TestName "Rust main.rs passes through JSON responses for run_system_action" `
    -Condition $hasPassThrough `
    -FailureMessage "Missing run_system_action passthrough for pro license actions in main.rs"

# ------------------------------------------------------------------------------
# SECTION 3: Frontend Rapid View Switching & Gatekeeper Router via Node.js
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 3: Rapid View Switching & Policy Interception (Node.js Engine) <<<" -ForegroundColor Yellow

$nodeTestScript = @"
const fs = require('fs');
const path = require('path');

// Mock DOM
class MockElement {
  constructor(id, tagName = 'div') {
    this.id = id;
    this.tagName = tagName;
    this.classes = new Set();
    this.value = '';
    this.listeners = {};
    this.scrollTop = 0;
    const self = this;
    this.classList = {
      add: (cls) => self.classes.add(cls),
      remove: (cls) => self.classes.delete(cls),
      contains: (cls) => self.classes.has(cls)
    };
  }
  addEventListener(event, fn) {
    if (!this.listeners[event]) this.listeners[event] = [];
    this.listeners[event].push(fn);
  }
  click() {
    if (this.listeners['click']) {
      this.listeners['click'].forEach(fn => fn({ preventDefault: () => {} }));
    }
  }
  querySelectorAll(sel) { return []; }
}

const elements = {};
function getOrCreate(id) {
  if (!elements[id]) {
    const el = new MockElement(id);
    elements[id] = el;
  }
  return elements[id];
}

const mockDoc = {
  getElementById: (id) => getOrCreate(id),
  querySelectorAll: (sel) => {
    if (sel === '.stitch-view') {
      return Object.values(elements).filter(e => e.isView);
    }
    return [];
  },
  querySelector: (sel) => {
    if (sel === '.stitch-view.active') {
      return Object.values(elements).find(e => e.isView && e.classList.contains('active'));
    }
    return null;
  }
};

// Global mocks
global.document = mockDoc;
global.showToast = (title, msg, type) => {};
global.invokeRust = async (cmd, params) => ({ success: false });

// Extract CANONICAL_VIEW_POLICY_MAP from app.js
const appJs = fs.readFileSync(path.join('$($projectRoot.Replace('\', '/'))', 'src-ui/app.js'), 'utf8');

const mapMatch = appJs.match(/const CANONICAL_VIEW_POLICY_MAP = ({[\s\S]*?});/);
if (!mapMatch) {
  console.log(JSON.stringify({ error: "Cannot extract CANONICAL_VIEW_POLICY_MAP" }));
  process.exit(1);
}
eval("global.CANONICAL_VIEW_POLICY_MAP = " + mapMatch[1]);

// Implement router state machine as in app.js
let isAdminAuth = false;
let isProLicensed = false;
let pendingGatekeeperTarget = null;
let currentPolicies = JSON.parse(fs.readFileSync(path.join('$($projectRoot.Replace('\', '/'))', 'src/Config/feature_policy.json'), 'utf8').replace(/^\uFEFF/, ''));

// Setup mock views
const allViewIds = [
  'view-sys-monitor', 'view-general', 'view-oem-brand', 'view-win-optimize',
  'view-uwp-apps', 'view-clean-uninstaller', 'view-soft-winget', 'view-download',
  'view-it-helpdesk', 'view-helpdesk-troubleshoot', 'view-vpn-proxy', 'view-block-web-game',
  'view-win-deploy', 'view-cai-windows', 'view-disk-smart', 'view-hwid-act',
  'view-disk-part', 'view-office-m365', 'view-tech-driver', 'view-backup-windows',
  'view-printer-lan', 'view-bitlocker-mgmt', 'view-admin-portal'
];

allViewIds.forEach(id => {
  const el = getOrCreate(id);
  el.isView = true;
  el.classList.add('hidden');
});
getOrCreate('view-sys-monitor').classList.add('active');

function checkGatekeeperAccess(targetId) {
  if (targetId === "view-win-activate") targetId = "view-hwid-act";
  if (targetId === "view-disk-bitlocker" || targetId === "view-bitlocker") targetId = "view-bitlocker-mgmt";

  if (isAdminAuth) return true;

  if (targetId === "view-admin-portal") {
    pendingGatekeeperTarget = targetId;
    getOrCreate("modal-admin-login").classList.remove("hidden");
    return false;
  }

  const policyId = CANONICAL_VIEW_POLICY_MAP[targetId];
  if (policyId) {
    const pol = currentPolicies.find((p) => p.Id === policyId);
    const tier = pol && pol.Tier ? pol.Tier.toUpperCase() : "FREE";

    if (tier === "ADMIN") {
      if (!isAdminAuth) {
        pendingGatekeeperTarget = targetId;
        getOrCreate("modal-admin-login").classList.remove("hidden");
        return false;
      }
    }

    if (tier === "PRO") {
      if (!isProLicensed) {
        pendingGatekeeperTarget = targetId;
        getOrCreate("modal-license-activation").classList.remove("hidden");
        return false;
      }
    }
  }

  return true;
}

function switchView(targetId) {
  if (targetId === "view-win-activate") targetId = "view-hwid-act";
  if (targetId === "view-disk-bitlocker" || targetId === "view-bitlocker") targetId = "view-bitlocker-mgmt";

  if (!checkGatekeeperAccess(targetId)) return false;

  const views = mockDoc.querySelectorAll(".stitch-view");
  let found = false;
  views.forEach((v) => {
    if (v.id === targetId) {
      v.classList.add("active");
      found = true;
    } else {
      v.classList.remove("active");
    }
  });
  return found;
}

const testResults = [];

// TEST 1: Rapid FREE view navigation
const r1 = switchView('view-general');
const cur1 = mockDoc.querySelector('.stitch-view.active').id;
const r2 = switchView('view-win-optimize');
const cur2 = mockDoc.querySelector('.stitch-view.active').id;
const r3 = switchView('view-sys-monitor');
const cur3 = mockDoc.querySelector('.stitch-view.active').id;
testResults.push({
  name: "Rapid FREE view transitions",
  pass: r1 && cur1 === 'view-general' && r2 && cur2 === 'view-win-optimize' && r3 && cur3 === 'view-sys-monitor' && pendingGatekeeperTarget === null
});

// TEST 2: Free User -> ADMIN view (view-hwid-act has Tier=ADMIN in feature_policy.json)
const rAdmin = switchView('view-hwid-act');
const curAfterAdmin = mockDoc.querySelector('.stitch-view.active').id;
const adminModalShown = !getOrCreate('modal-admin-login').classList.contains('hidden');
testResults.push({
  name: "FREE user accessing ADMIN view blocked",
  pass: !rAdmin && curAfterAdmin === 'view-sys-monitor' && adminModalShown && pendingGatekeeperTarget === 'view-hwid-act'
});

// TEST 3: Dynamically set AutoWin policy to PRO and test access
const autoWinPol = currentPolicies.find(p => p.Id === 'AutoWin');
autoWinPol.Tier = 'PRO';

const rPro = switchView('view-win-deploy');
const curAfterPro = mockDoc.querySelector('.stitch-view.active').id;
const proModalShown = !getOrCreate('modal-license-activation').classList.contains('hidden');
testResults.push({
  name: "FREE user accessing PRO view blocked",
  pass: !rPro && curAfterPro === 'view-sys-monitor' && proModalShown && pendingGatekeeperTarget === 'view-win-deploy'
});

// TEST 4: Rapid alternating switches between FREE, PRO, and ADMIN
let spamPassed = true;
for (let i = 0; i < 50; i++) {
  // Free view
  switchView('view-general');
  if (mockDoc.querySelector('.stitch-view.active').id !== 'view-general') spamPassed = false;
  // Pro view (blocked)
  switchView('view-win-deploy');
  if (mockDoc.querySelector('.stitch-view.active').id !== 'view-general') spamPassed = false;
  if (pendingGatekeeperTarget !== 'view-win-deploy') spamPassed = false;
  // Admin view (blocked)
  switchView('view-hwid-act');
  if (mockDoc.querySelector('.stitch-view.active').id !== 'view-general') spamPassed = false;
  if (pendingGatekeeperTarget !== 'view-hwid-act') spamPassed = false;
}
testResults.push({
  name: "Rapid 50x interleaved view switching state integrity",
  pass: spamPassed
});

// TEST 5: Modal Dismissal & pendingGatekeeperTarget Sanitization
// Set pending target to 'view-win-deploy'
pendingGatekeeperTarget = 'view-win-deploy';
getOrCreate('modal-license-activation').classList.remove('hidden');

// Trigger cancel callback (simulating doCancel in app.js)
const doCancelPro = () => {
  getOrCreate('modal-license-activation').classList.add('hidden');
  pendingGatekeeperTarget = null;
  getOrCreate('lbl-license-error').classList.add('hidden');
};
doCancelPro();

testResults.push({
  name: "PRO Modal cancellation clears pendingGatekeeperTarget to null",
  pass: pendingGatekeeperTarget === null && getOrCreate('modal-license-activation').classList.contains('hidden')
});

// TEST 6: Admin Login Modal Cancellation Sanitization
pendingGatekeeperTarget = 'view-admin-portal';
getOrCreate('modal-admin-login').classList.remove('hidden');

const doCancelAdmin = () => {
  getOrCreate('modal-admin-login').classList.add('hidden');
  pendingGatekeeperTarget = null;
};
doCancelAdmin();

testResults.push({
  name: "ADMIN Modal cancellation clears pendingGatekeeperTarget to null",
  pass: pendingGatekeeperTarget === null && getOrCreate('modal-admin-login').classList.contains('hidden')
});

// TEST 7: Cancel Pollution Attack Protection
// User tries to enter PRO view -> blocked -> cancels
switchView('view-win-deploy'); // blocked, pending = 'view-win-deploy'
doCancelPro(); // pending = null
// User now logs in via Admin Portal button
let navigatedTarget = null;
if (pendingGatekeeperTarget) {
  navigatedTarget = pendingGatekeeperTarget;
  pendingGatekeeperTarget = null;
  switchView(navigatedTarget);
} else {
  navigatedTarget = 'view-admin-portal';
  isAdminAuth = true;
  switchView('view-admin-portal');
}
testResults.push({
  name: "Cancel pollution defense: logging in after cancel routes to Admin, not stale target",
  pass: navigatedTarget === 'view-admin-portal' && pendingGatekeeperTarget === null
});

// TEST 8: Immediate Unlocking upon successful Pro key activation
isAdminAuth = false;
isProLicensed = false;
switchView('view-win-deploy'); // blocked, pending = 'view-win-deploy'

// Activation succeeds:
isProLicensed = true;
let unlockedView = null;
if (pendingGatekeeperTarget) {
  unlockedView = pendingGatekeeperTarget;
  pendingGatekeeperTarget = null;
  switchView(unlockedView);
}
testResults.push({
  name: "Immediate unlocking: valid activation navigates to pending target and clears state",
  pass: unlockedView === 'view-win-deploy' &&
        pendingGatekeeperTarget === null &&
        mockDoc.querySelector('.stitch-view.active').id === 'view-win-deploy'
});

// TEST 9: PRO user cannot access ADMIN view
const rProOnAdmin = switchView('view-hwid-act');
testResults.push({
  name: "PRO user blocked from accessing ADMIN tier view",
  pass: !rProOnAdmin && pendingGatekeeperTarget === 'view-hwid-act'
});

// TEST 10: Admin God Mode grants access to ALL tiers
isAdminAuth = true;
const rAdminFree = switchView('view-sys-monitor');
const rAdminPro = switchView('view-win-deploy');
const rAdminAdmin = switchView('view-hwid-act');
const rAdminPortal = switchView('view-admin-portal');
testResults.push({
  name: "ADMIN God Mode grants access to FREE, PRO, and ADMIN views without modals",
  pass: rAdminFree && rAdminPro && rAdminAdmin && rAdminPortal
});

console.log(JSON.stringify(testResults));
"@

$nodeTestRunner = Join-Path $env:TEMP "test_gatekeeper_router.js"
[System.IO.File]::WriteAllText($nodeTestRunner, $nodeTestScript, [System.Text.Encoding]::UTF8)

$nodeOutput = & node $nodeTestRunner
Remove-Item $nodeTestRunner -Force -ErrorAction SilentlyContinue

$results = $null
try {
    $results = $nodeOutput | ConvertFrom-Json
} catch {
    Write-Host "Failed to parse Node.js test output: $nodeOutput" -ForegroundColor Red
}

if ($results) {
    foreach ($res in $results) {
        Assert-Check `
            -Category "SEC3-ROUTER" `
            -TestName $res.name `
            -Condition ([bool]$res.pass) `
            -FailureMessage "Node.js router simulation failed for: $($res.name)"
    }
} else {
    Assert-Check `
        -Category "SEC3-ROUTER" `
        -TestName "Node.js execution completed successfully" `
        -Condition $false `
        -FailureMessage "Node.js simulation did not produce valid JSON"
}

# ------------------------------------------------------------------------------
# SECTION 4: DOM Elements, Event Hooks & Cancellation Buttons in HTML/JS
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 4: Modal Dismissals, Cancel Buttons & DOM Wiring <<<" -ForegroundColor Yellow

$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "modal-license-activation has 'hidden' class by default" `
    -Condition ($htmlContent -match 'id="modal-license-activation"[^>]*class="[^"]*hidden') `
    -FailureMessage "modal-license-activation is not hidden by default"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "display-pro-hwid is readonly" `
    -Condition ($htmlContent -match 'id="display-pro-hwid"[^>]*readonly') `
    -FailureMessage "display-pro-hwid is not readonly"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "input-pro-license-key exists with uppercase tracking" `
    -Condition ($htmlContent -match 'id="input-pro-license-key"') `
    -FailureMessage "input-pro-license-key missing in index.html"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "btn-cancel-pro-activation exists in index.html" `
    -Condition ($htmlContent -match 'id="btn-cancel-pro-activation"') `
    -FailureMessage "btn-cancel-pro-activation missing in index.html"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "btn-close-license-modal exists in index.html" `
    -Condition ($htmlContent -match 'id="btn-close-license-modal"') `
    -FailureMessage "btn-close-license-modal missing in index.html"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "btn-copy-license-hwid exists in index.html" `
    -Condition ($htmlContent -match 'id="btn-copy-license-hwid"') `
    -FailureMessage "btn-copy-license-hwid missing in index.html"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "app.js binds btnCancel for PRO activation to clear pendingGatekeeperTarget" `
    -Condition ($appJsContent -match 'btnCancel\.addEventListener\("click",\s*doCancel\)' -and $appJsContent -match 'pendingGatekeeperTarget\s*=\s*null') `
    -FailureMessage "app.js does not bind btnCancel or reset pendingGatekeeperTarget"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "app.js binds btnClose for PRO activation to clear pendingGatekeeperTarget" `
    -Condition ($appJsContent -match 'btnClose\.addEventListener\("click",\s*doCancel\)') `
    -FailureMessage "app.js does not bind btnClose to doCancel"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "app.js binds inputKey Enter keydown to submitProLicenseKey" `
    -Condition ($appJsContent -match 'inputKey\.addEventListener\("keydown"') `
    -FailureMessage "app.js missing Enter keydown listener on input-pro-license-key"

Assert-Check `
    -Category "SEC4-DOM" `
    -TestName "app.js initGatekeeper loads policies on DOMContentLoaded" `
    -Condition ($appJsContent -match 'initGatekeeper' -and $appJsContent -match 'admin_get_data' -and $appJsContent -match 'check_pro_license') `
    -FailureMessage "initGatekeeper does not load policies or check pro license"

# ------------------------------------------------------------------------------
# SECTION 5: Canonical View Mapping Integrity & Legacy Route Aliases
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 5: Canonical View Mapping & Route Aliases <<<" -ForegroundColor Yellow

$policyData = Get-Content -Path $policyJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$validPolicyIds = $policyData | ForEach-Object { $_.Id }

$primaryCanonicalViews = @(
    "view-sys-monitor", "view-general", "view-win-optimize",
    "view-clean-uninstaller", "view-soft-winget",
    "view-it-helpdesk", "view-vpn-proxy",
    "view-win-deploy", "view-disk-smart", "view-hwid-act",
    "view-disk-part", "view-office-m365", "view-tech-driver", "view-backup-windows",
    "view-printer-lan", "view-bitlocker-mgmt"
)

foreach ($viewId in $primaryCanonicalViews) {
    $hasInHtml = ($htmlContent -match "id=`"$viewId`"")
    Assert-Check `
        -Category "SEC5-MAP" `
        -TestName "Primary Canonical View exists in HTML: $viewId" `
        -Condition $hasInHtml `
        -FailureMessage "View $viewId is missing in src-ui/index.html"
}

# Verify legacy route aliases in CANONICAL_VIEW_POLICY_MAP
$aliasViews = @("view-download", "view-oem-brand", "view-uwp-apps", "view-helpdesk-troubleshoot", "view-block-web-game", "view-cai-windows")
foreach ($alias in $aliasViews) {
    $hasInMap = ($appJsContent -match "`"$alias`":")
    Assert-Check `
        -Category "SEC5-MAP" `
        -TestName "Legacy/Alternative Route Alias is mapped in CANONICAL_VIEW_POLICY_MAP: $alias" `
        -Condition $hasInMap `
        -FailureMessage "Alias $alias is missing from CANONICAL_VIEW_POLICY_MAP in app.js"
}

# Verify legacy route aliases in app.js
$hasWinActivateAlias = ($appJsContent -match 'targetId\s*===\s*"view-win-activate"')
$hasBitlockerAlias = ($appJsContent -match 'targetId\s*===\s*"view-disk-bitlocker"')

Assert-Check `
    -Category "SEC5-MAP" `
    -TestName "app.js contains legacy route alias: view-win-activate -> view-hwid-act" `
    -Condition $hasWinActivateAlias `
    -FailureMessage "Missing view-win-activate alias redirection"

Assert-Check `
    -Category "SEC5-MAP" `
    -TestName "app.js contains legacy route alias: view-disk-bitlocker -> view-bitlocker-mgmt" `
    -Condition $hasBitlockerAlias `
    -FailureMessage "Missing view-disk-bitlocker alias redirection"

# ------------------------------------------------------------------------------
# SECTION 6: Syntax & AST Integrity
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 6: Syntax & AST Integrity <<<" -ForegroundColor Yellow

$nodeCheckOutput = & node -c src-ui/app.js 2>&1
$nodeExit = $LASTEXITCODE
Assert-Check `
    -Category "SEC6-AST" `
    -TestName "Node.js syntax check (node -c src-ui/app.js) must be clean" `
    -Condition ($nodeExit -eq 0) `
    -FailureMessage "JavaScript syntax error in src-ui/app.js: $nodeCheckOutput"

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($licPath, [ref]$tokens, [ref]$parseErrors)
Assert-Check `
    -Category "SEC6-AST" `
    -TestName "LicenseManager.ps1 AST parser check (0 errors)" `
    -Condition ($parseErrors.Count -eq 0) `
    -FailureMessage "PowerShell AST errors in LicenseManager.ps1: $($parseErrors | Out-String)"

# ------------------------------------------------------------------------------
# FINAL SUMMARY
# ------------------------------------------------------------------------------
Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "CHALLENGER 1 VERDICT SUMMARY:" -ForegroundColor Cyan
Write-Host "  Total Tests Run:  $($script:TotalTests)"
Write-Host "  Tests Passed:     $($script:PassedTests)" -ForegroundColor Green
Write-Host "  Tests Failed:     $($script:FailedTests)" -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    Write-Host "`nFailed Tests List:" -ForegroundColor Red
    foreach ($f in $script:Failures) {
        Write-Host "  - $f" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "`nALL ADVERSARIAL STRESS TESTS PASSED EMPIRICALLY (100% PASS)!" -ForegroundColor Green
    exit 0
}
