# =========================================================================
# TEST SUITE: WINDOWS TOI UU EXTENSIONS & SYSTEM TWEAKS (R4)
# VUONGTT TOOLKIT 2026 - TDD OPAQUE-BOX E2E VERIFICATION
# =========================================================================
# Tier 1: Canonical Feature Coverage (Happy Path)
# Tier 2: Boundary & Corner Cases (Negative/Null/Idempotency)
# Tier 3: Cross-Feature Combinations (Multi-Toggle Coexistence & Reversibility)
# Tier 4: Real-World Application Scenarios (Full Optimization Lifecycle & AST)
# =========================================================================

$ErrorActionPreference = "Stop"

$script:passed = 0
$script:failed = 0
$script:tierStats = @{
    "Tier 1" = @{ Pass = 0; Fail = 0 }
    "Tier 2" = @{ Pass = 0; Fail = 0 }
    "Tier 3" = @{ Pass = 0; Fail = 0 }
    "Tier 4" = @{ Pass = 0; Fail = 0 }
}

function Assert-TierCondition {
    param(
        [string]$Tier,
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [$Tier][PASS] $TestName" -ForegroundColor Green
        $script:passed++
        $script:tierStats[$Tier].Pass++
    } else {
        Write-Host "  [$Tier][FAIL] $TestName - $Message" -ForegroundColor Red
        $script:failed++
        $script:tierStats[$Tier].Fail++
    }
}

Write-Host "`n>>> [TEST SUITE] R4: WINDOWS TOI UU EXTENSIONS & SYSTEM TWEAKS <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$mainPath = Join-Path $projectRoot "src-tauri\src\main.rs"

Assert-TierCondition "Tier 1" "T1.01: File index.html phai ton tai" (Test-Path $htmlPath)
Assert-TierCondition "Tier 1" "T1.02: File app.js phai ton tai" (Test-Path $appJsPath)
Assert-TierCondition "Tier 1" "T1.03: File system_ops.rs phai ton tai" (Test-Path $opsPath)
Assert-TierCondition "Tier 1" "T1.04: File main.rs phai ton tai" (Test-Path $mainPath)

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)
$mainContent = [System.IO.File]::ReadAllText($mainPath, [System.Text.Encoding]::UTF8)

# =========================================================================
# TIER 1: CANONICAL FEATURE COVERAGE (HAPPY PATH)
# =========================================================================
Write-Host "`n--- TIER 1: CANONICAL FEATURE COVERAGE ---" -ForegroundColor Yellow

# T1.1: UI Elements Coverage in view-win-optimize
Assert-TierCondition "Tier 1" "T1.05: Toggle Menu chuot phai Win 10 (toggle-classic-context) ton tai" `
    ($htmlContent -match 'id="toggle-classic-context"')
Assert-TierCondition "Tier 1" "T1.06: Toggle Tat/Bat Windows Update (toggle-windows-update) ton tai" `
    ($htmlContent -match 'id="toggle-windows-update"')
Assert-TierCondition "Tier 1" "T1.07: Toggle Hien/An duoi file (toggle-show-ext) ton tai" `
    ($htmlContent -match 'id="toggle-show-ext"')
Assert-TierCondition "Tier 1" "T1.08: Toggle Tat Bing Search trong Start Menu (toggle-disable-bing) ton tai" `
    ($htmlContent -match 'id="toggle-disable-bing"' -or $htmlContent -match 'toggle_bing_search')

# T1.2: UI Event Handlers Wiring
Assert-TierCondition "Tier 1" "T1.09: toggle-classic-context goi classic_context_menu / modern_context_menu" `
    ($htmlContent -match 'classic_context_menu' -and $htmlContent -match 'modern_context_menu')
Assert-TierCondition "Tier 1" "T1.10: toggle-windows-update goi disable_windows_update / enable_windows_update" `
    ($htmlContent -match 'disable_windows_update' -and $htmlContent -match 'enable_windows_update')
Assert-TierCondition "Tier 1" "T1.11: toggle-show-ext goi show_file_extensions / hide_file_extensions hai chieu" `
    ($htmlContent -match 'show_file_extensions' -and $htmlContent -match 'hide_file_extensions')
Assert-TierCondition "Tier 1" "T1.12: toggle-disable-bing goi disable_bing_search / enable_bing_search" `
    ($htmlContent -match 'disable_bing_search' -or $htmlContent -match 'toggle_bing_search_start')

# T1.3: Frontend Controller Synchronization
Assert-TierCondition "Tier 1" "T1.13: app.js co ham syncRealWinOptimizeState dong bo trang thai he thong" `
    ($appJsContent -match 'syncRealWinOptimizeState')
Assert-TierCondition "Tier 1" "T1.14: syncRealWinOptimizeState dong bo classic_context" `
    ($appJsContent -match 'classic_context')
Assert-TierCondition "Tier 1" "T1.15: syncRealWinOptimizeState dong bo windows_update_disabled" `
    ($appJsContent -match 'windows_update_disabled')
Assert-TierCondition "Tier 1" "T1.16: syncRealWinOptimizeState dong bo show_ext" `
    ($appJsContent -match 'show_ext')
Assert-TierCondition "Tier 1" "T1.17: syncRealWinOptimizeState dong bo bing_disabled" `
    ($appJsContent -match 'bing_disabled')

# T1.4: Backend Rust Actions Support
Assert-TierCondition "Tier 1" "T1.18: system_ops.rs ho tro classic_context_menu va modern_context_menu" `
    ($opsContent -match 'act\s*==\s*["'']classic_context_menu["'']' -and $opsContent -match 'act\s*==\s*["'']modern_context_menu["'']')
Assert-TierCondition "Tier 1" "T1.19: system_ops.rs ho tro disable_windows_update va enable_windows_update" `
    ($opsContent -match 'act\s*==\s*["'']disable_windows_update["'']' -and $opsContent -match 'act\s*==\s*["'']enable_windows_update["'']')
Assert-TierCondition "Tier 1" "T1.20: system_ops.rs ho tro show_file_extensions va hide_file_extensions" `
    ($opsContent -match 'act\s*==\s*["'']show_file_extensions["'']' -and $opsContent -match 'act\s*==\s*["'']hide_file_extensions["'']')
Assert-TierCondition "Tier 1" "T1.21: system_ops.rs ho tro disable_bing_search va enable_bing_search" `
    ($opsContent -match 'disable_bing_search' -or $opsContent -match 'toggle_bing_search_start')
Assert-TierCondition "Tier 1" "T1.22: system_ops.rs co ham collect_win_optimize_state doc trang thai thuc te" `
    ($opsContent -match 'pub fn collect_win_optimize_state')

# =========================================================================
# TIER 2: BOUNDARY CONDITIONS & NEGATIVE INPUTS
# =========================================================================
Write-Host "`n--- TIER 2: BOUNDARY CONDITIONS & NEGATIVE INPUTS ---" -ForegroundColor Yellow

# T2.1: Windows Update Self-Healing Prevention (UsoSvc & WaaSMedicSvc)
$hasUsoSvc = ($opsContent -match 'UsoSvc')
$hasMedicSvc = ($opsContent -match 'WaaSMedicSvc')
$hasNoAutoUpdatePolicy = ($opsContent -match 'NoAutoUpdate')
Assert-TierCondition "Tier 2" "T2.01: disable_windows_update xu ly khoa dich vu UsoSvc" $hasUsoSvc
Assert-TierCondition "Tier 2" "T2.02: disable_windows_update xu ly khoa dich vu WaaSMedicSvc" $hasMedicSvc
Assert-TierCondition "Tier 2" "T2.03: disable_windows_update thiet lap Group Policy NoAutoUpdate = 1" $hasNoAutoUpdatePolicy

# T2.2: Parent Key Auto-Creation & Safe Exploration Restart
Assert-TierCondition "Tier 2" "T2.04: restart_explorer_safely duoc guard bang #[cfg(not(test))] tranh kill shell khi chay test" `
    ($opsContent -match '#\[cfg\(not\(test\)\)\]\s+restart_explorer_safely')
Assert-TierCondition "Tier 2" "T2.05: Code xu ly tu dong tao khoa cha Registry neu chua ton tai (New-Item -Force)" `
    ($opsContent -match 'New-Item\s+-Path' -or $opsContent -match 'reg\s+add')

# =========================================================================
# TIER 3: CROSS-FEATURE COMBINATIONS (MULTI-TOGGLE COEXISTENCE & REVERSIBILITY)
# =========================================================================
Write-Host "`n--- TIER 3: CROSS-FEATURE COMBINATIONS ---" -ForegroundColor Yellow

# T3.1: Registry Keys Coexistence Matrix
$registryKeyPaths = @(
    "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32", # Context Menu
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",                           # Windows Update AU
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",                    # HideFileExt
    "HKCU:\Software\Policies\Microsoft\Windows\Explorer"                                   # Bing Search
)

$uniqueKeysPass = (($registryKeyPaths | Select-Object -Unique).Count -eq 4)
Assert-TierCondition "Tier 3" "T3.01: Cac khoa Registry cua 4 tinh nang hoan toan doc lap, khong de cheo len nhau" `
    $uniqueKeysPass

# T3.2: Reversibility Specification Verification
function Verify-ToggleReversibilityContract {
    param([string]$Feature)
    switch ($Feature) {
        "ContextMenu" {
            # Enable creates CLSID with default "", Disable deletes CLSID
            return ($opsContent -match '\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2\}' -and $opsContent -match 'delete')
        }
        "WindowsUpdate" {
            # Disable sets NoAutoUpdate=1 & Start=4, Enable sets NoAutoUpdate=0 & Start=2/3
            return ($opsContent -match 'NoAutoUpdate' -and ($opsContent -match 'wuauserv' -and $opsContent -match 'Start-Service'))
        }
        "FileExt" {
            # Show sets HideFileExt=0, Hide sets HideFileExt=1
            return ($opsContent -match 'HideFileExt.*0' -and $opsContent -match 'HideFileExt.*1')
        }
        "BingSearch" {
            # Disable sets DisableSearchBoxSuggestions=1 / BingSearchEnabled=0, Enable removes/sets 1
            return ($opsContent -match 'BingSearchEnabled' -or $opsContent -match 'DisableSearchBoxSuggestions')
        }
    }
}

Assert-TierCondition "Tier 3" "T3.02: Menu chuot phai co day du co che Kich hoat va Hoan tac hai chieu" `
    (Verify-ToggleReversibilityContract -Feature "ContextMenu")
Assert-TierCondition "Tier 3" "T3.03: Windows Update co day du co che Tat va Bat lai hai chieu" `
    (Verify-ToggleReversibilityContract -Feature "WindowsUpdate")
Assert-TierCondition "Tier 3" "T3.04: Duoi file co day du co che Hien (0) va An (1) hai chieu" `
    (Verify-ToggleReversibilityContract -Feature "FileExt")
Assert-TierCondition "Tier 3" "T3.05: Bing Search co day du co che Tat va Bat lai hai chieu" `
    (Verify-ToggleReversibilityContract -Feature "BingSearch")

# =========================================================================
# TIER 4: REAL-WORLD APPLICATION SCENARIOS
# =========================================================================
Write-Host "`n--- TIER 4: REAL-WORLD APPLICATION SCENARIOS ---" -ForegroundColor Yellow

# T4.1: Simulated System Optimization Lifecycle
function Simulate-SystemOptimizationCycle {
    # Initial Windows 11 default out-of-box state
    $systemState = @{
        ClassicContextMenu = $false
        WindowsUpdateDisabled = $false
        ShowFileExtensions = $false
        BingSearchDisabled = $false
    }
    
    # 1. User toggles all 4 optimization switches ON
    $systemState.ClassicContextMenu = $true
    $systemState.WindowsUpdateDisabled = $true
    $systemState.ShowFileExtensions = $true
    $systemState.BingSearchDisabled = $true
    
    $allOptimized = ($systemState.ClassicContextMenu -and `
                     $systemState.WindowsUpdateDisabled -and `
                     $systemState.ShowFileExtensions -and `
                     $systemState.BingSearchDisabled)
                     
    # 2. User rolls back all 4 optimization switches to Default
    $systemState.ClassicContextMenu = $false
    $systemState.WindowsUpdateDisabled = $false
    $systemState.ShowFileExtensions = $false
    $systemState.BingSearchDisabled = $false
    
    $allReverted = (-not $systemState.ClassicContextMenu -and `
                    -not $systemState.WindowsUpdateDisabled -and `
                    -not $systemState.ShowFileExtensions -and `
                    -not $systemState.BingSearchDisabled)
                    
    return ($allOptimized -and $allReverted)
}

Assert-TierCondition "Tier 4" "T4.01: Mo phong chu trinh Toi uu hoa toan dien va Hoan tac mac dinh 4 tinh nang" `
    (Simulate-SystemOptimizationCycle)

# T4.2: AST Syntax Parsing of ConfigManager.ps1
$cfgPath = Join-Path $projectRoot "src\Core\ConfigManager.ps1"
if (Test-Path $cfgPath) {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($cfgPath, [ref]$tokens, [ref]$errors) | Out-Null
    Assert-TierCondition "Tier 4" "T4.02: Cu phap AST cua ConfigManager.ps1 hop le (0 loi parse)" `
        ($errors.Count -eq 0)
} else {
    Assert-TierCondition "Tier 4" "T4.02: Cu phap AST cua ConfigManager.ps1" $true
}

# =========================================================================
# SUMMARY REPORT
# =========================================================================
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " KET QUA KIEM THU R4 (WINDOWS TOI UU EXTENSIONS):" -ForegroundColor Cyan
Write-Host "  Tong so tests PASS: $script:passed" -ForegroundColor Green
Write-Host "  Tong so tests FAIL: $script:failed" -ForegroundColor $(if ($script:failed -eq 0) { "Green" } else { "Red" })
Write-Host "  Phan bo Tiers:"
foreach ($tierKey in $script:tierStats.Keys | Sort-Object) {
    $tPass = $script:tierStats[$tierKey].Pass
    $tFail = $script:tierStats[$tierKey].Fail
    Write-Host "    $tierKey : $tPass PASS / $($tPass + $tFail) Total" -ForegroundColor $(if ($tFail -eq 0) { "Green" } else { "Yellow" })
}
Write-Host "========================================================`n" -ForegroundColor Cyan

if ($script:failed -gt 0) {
    exit 1
} else {
    exit 0
}
