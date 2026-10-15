# ==============================================================================
# BỘ TEST TỰ ĐỘNG: FLEET TELEMETRY REAL STATE & DRIVER BACKUP ENGINE
# ==============================================================================

$testsPassed = 0
$testsFailed = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
        $script:testsFailed++
    }
}

Write-Host ">>> KIEM THU FLEET TELEMETRY & DRIVER BACKUP/RESTORE <<<" -ForegroundColor Cyan

$sysOpsRsPath = Join-Path $PSScriptRoot "..\src-tauri\src\system_ops.rs"
$indexHtmlPath = Join-Path $PSScriptRoot "..\src-ui\index.html"
$appJsPath = Join-Path $PSScriptRoot "..\src-ui\app.js"

$sysOpsRs = [System.IO.File]::ReadAllText($sysOpsRsPath, [System.Text.Encoding]::UTF8)
$indexHtml = [System.IO.File]::ReadAllText($indexHtmlPath, [System.Text.Encoding]::UTF8)
$appJs = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)

# --- Test 1: Real Telemetry in Rust system_ops.rs ---
Write-Host "`n--- Nhom 1: Real Telemetry Collection ---"
Assert-Condition -TestName "system_ops.rs phai co ham collect_real_system_identity" `
    -Condition ($sysOpsRs -match 'collect_real_system_identity') `
    -Message "Thieu ham collect_real_system_identity de lay thong tin that cua may"

Assert-Condition -TestName "system_ops.rs khong duoc hardcode BIOS-PRIMARY-001 vo dieu kien" `
    -Condition (-not ($sysOpsRs -match '"BIOS-PRIMARY-001"')) `
    -Message "Van con hardcode BIOS-PRIMARY-001 lam ghi de cac may khac"

# --- Test 2: Driver Backup & Restore Actions ---
Write-Host "`n--- Nhom 2: Driver Backup & Restore Actions ---"
Assert-Condition -TestName "system_ops.rs phai xu ly action backup_drivers" `
    -Condition ($sysOpsRs -match '"backup_drivers"' -or $sysOpsRs -match 'act == "backup_drivers"') `
    -Message "Thieu action backup_drivers trong system_ops.rs"

Assert-Condition -TestName "system_ops.rs phai xu ly action restore_drivers" `
    -Condition ($sysOpsRs -match '"restore_drivers"' -or $sysOpsRs -match 'act == "restore_drivers"') `
    -Message "Thieu action restore_drivers trong system_ops.rs"

Assert-Condition -TestName "index.html phai co nut bam hoac onclick goi backup driver" `
    -Condition ($indexHtml -match 'exportDrivers\(\)' -or $indexHtml -match 'backupDrivers\(\)' -or $indexHtml -match 'id="btn-export-drivers"') `
    -Message "index.html chua gan su kien cho nut Export Driver"

Assert-Condition -TestName "index.html phai co nut bam hoac onclick goi restore driver" `
    -Condition ($indexHtml -match 'restoreDrivers\(\)' -or $indexHtml -match 'id="btn-restore-drivers"') `
    -Message "index.html chua gan su kien cho nut Restore Driver"

# --- Test 3: Office Install Action ---
Write-Host "`n--- Nhom 3: Office Install Action ---"
Assert-Condition -TestName "system_ops.rs phai xu ly action install_office" `
    -Condition ($sysOpsRs -match '"install_office"' -or $sysOpsRs -match 'act == "install_office"') `
    -Message "Thieu action install_office trong system_ops.rs"

Assert-Condition -TestName "index.html khong duoc chua chuoi simulation gia lap deploy office" `
    -Condition (-not ($indexHtml -match 'Deployment simulate stream')) `
    -Message "index.html van con listener gia lap Deployment simulate stream"

# --- Test 4: Preset Selection vs Apply in Win Optimize ---
Write-Host "`n--- Nhom 4: Preset Selection vs Apply ---"
Assert-Condition -TestName "index.html phai co nut ap dung tweaks ro rang" `
    -Condition ($indexHtml -match 'id="btn-apply-tweaks"') `
    -Message "Thieu nut id=btn-apply-tweaks"

Assert-Condition -TestName "index.html phai co label hien thi preset dang chon" `
    -Condition ($indexHtml -match 'id="active-preset-label"') `
    -Message "Thieu badge hien thi preset dang duoc chon"

$total = $testsPassed + $testsFailed
Write-Host "`n=========================================================="
Write-Host "KET QUA: $testsPassed PASS / $total TOTAL"
Write-Host "=========================================================="

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
