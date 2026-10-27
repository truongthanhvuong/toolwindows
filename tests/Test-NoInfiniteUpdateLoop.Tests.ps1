# =========================================================================
# TDD TEST SUITE: NGAN CHAN TRIET DE VONG LAP CAP NHAT VO TAN & SPAWN CUA SO
# tests/Test-NoInfiniteUpdateLoop.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$mainRs = Join-Path $repoRoot "src-tauri\src\main.rs"
$appJs = Join-Path $repoRoot "src-ui\app.js"
$winPs1 = Join-Path $repoRoot "win.ps1"
$vuongttPs1 = Join-Path $repoRoot "vuongtt.ps1"

Write-Host "`n=== BAT DAU KIEM THU TDD: CHONG VONG LAP CAP NHAT & CHONG MO NHIEU CUA SO ===" -ForegroundColor Cyan

$allPassed = $true

function Assert-Test([string]$name, [scriptblock]$condition) {
    try {
        $result = & $condition
        if ($result) {
            Write-Host " [PASS] $name" -ForegroundColor Green
        } else {
            Write-Host " [FAIL] $name" -ForegroundColor Red
            $script:allPassed = $false
        }
    } catch {
        Write-Host " [FAIL] $name - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:allPassed = $false
    }
}

$mainRsContent = Get-Content -Path $mainRs -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJs -Raw -Encoding UTF8
$winPs1Content = Get-Content -Path $winPs1 -Raw -Encoding UTF8
$vuongttPs1Content = Get-Content -Path $vuongttPs1 -Raw -Encoding UTF8

Write-Host "`n--- Nhom 1: Kiem Tra Rust Native (src-tauri/src/main.rs) ---" -ForegroundColor Yellow

Assert-Test "main.rs khong chua luong ngam chay vuongtt_bootstrapper_runner.cmd tu diet tien trinh" {
    $mainRsContent -notmatch "vuongtt_bootstrapper_runner\.cmd"
}

Assert-Test "main.rs khong tu y spawn cmd.exe RunAs irm tinyurl.com/vuongwin tren startup" {
    $mainRsContent -notmatch 'Start-Process.*cmd\.exe.*vuongwin' -and $mainRsContent -notmatch 'cmd\.exe.*runnerBat'
}

Assert-Test "main.rs co co che Single-Instance Mutex chong chay trung lap nhieu cua so" {
    $mainRsContent -match 'CreateMutexW' -or $mainRsContent -match 'SingleInstance'
}

Write-Host "`n--- Nhom 2: Kiem Tra Bootstrapper (win.ps1 & vuongtt.ps1) ---" -ForegroundColor Yellow

foreach ($psFile in @($winPs1, $vuongttPs1)) {
    $fName = Split-Path $psFile -Leaf

    $c = Get-Content -Path $psFile -Raw -Encoding UTF8

    Assert-Test "$fName khong dung phep so sanh lech ($localVersion -ne $latestVer) de tai de" {
        $c -notmatch '\$localVersion\s*-ne\s*\$latestVer'
    }

    Assert-Test "$fName co ham so sanh SemVer phien ban chinh xac" {
        $c -match 'Compare-SemVer' -or $c -match '\[version\]'
    }

    Assert-Test "$fName kiem tra tien trinh dang chay chong mo de cua so moi" {
        $c -match 'Get-Process.*VUONGTT_Toolkit'
    }
}

Write-Host "`n--- Nhom 3: Kiem Tra UI Client (src-ui/app.js) ---" -ForegroundColor Yellow

Assert-Test "app.js checkForUpdate(false) luc khoi dong khong tu y goi apply_update" {
    $fnBody = ""
    if ($appJsContent -match 'async function checkForUpdate\([^\)]*\)\s*\{([\s\S]*?)\n  \}') {
        $fnBody = $matches[1]
    }
    # Trong phan isManual == false, khong duoc goi apply_update
    $fnBody -notmatch 'if\s*\(!isManual\)[^}]+apply_update' -and $fnBody -notmatch 'updateInfo\.has_update[\s\S]*?apply_update'
}

Write-Host "`n=== KET QUA TONG THE ===" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host ">>> TOAN BO KIEM THU CHONG VONG LAP CAP NHAT DAT 100% PASS! <<<`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host ">>> PHAT HIEN LOI TRONG CAC BAI KIEM THU CHONG VONG LAP! <<<`n" -ForegroundColor Red
    exit 1
}
