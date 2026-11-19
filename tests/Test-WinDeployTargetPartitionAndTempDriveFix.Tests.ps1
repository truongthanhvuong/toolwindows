# =========================================================================
# TDD TEST SUITE: WINDOWS DEPLOY 0x80070490 TEMPDRIVE & TARGET PARTITION FIX
# tests/Test-WinDeployTargetPartitionAndTempDriveFix.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"
$mainRs = Join-Path $repoRoot "src-tauri\src\main.rs"
$appJs = Join-Path $repoRoot "src-ui\app.js"
$indexHtml = Join-Path $repoRoot "src-ui\index.html"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN DEPLOY 0x80070490 FIX & TARGET PARTITION SELECT " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "======================================================================" -ForegroundColor Cyan

$passedCount = 0
$failedCount = 0

function Assert-Test([string]$desc, [scriptblock]$condition) {
    try {
        $result = & $condition
        if ($result) {
            Write-Host " [PASS] $desc" -ForegroundColor Green
            $script:passedCount++
        } else {
            Write-Host " [FAIL] $desc" -ForegroundColor Red
            $script:failedCount++
        }
    } catch {
        Write-Host " [FAIL] $desc - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failedCount++
    }
}

$opsContent = if (Test-Path $opsRs) { Get-Content -Path $opsRs -Raw -Encoding UTF8 } else { "" }
$mainContent = if (Test-Path $mainRs) { Get-Content -Path $mainRs -Raw -Encoding UTF8 } else { "" }
$appJsContent = if (Test-Path $appJs) { Get-Content -Path $appJs -Raw -Encoding UTF8 } else { "" }
$htmlContent = if (Test-Path $indexHtml) { Get-Content -Path $indexHtml -Raw -Encoding UTF8 } else { "" }

# 1. system_ops.rs phai truyen tham so /tempdrive de chan loi 0x80070490
Assert-Test "system_ops.rs phai truyen tham so /tempdrive khi khoi chay setup.exe" {
    $opsContent -match '/tempdrive'
}

# 2. system_ops.rs phai tu dong don dep thu muc $WINDOWS.~BT va $WINDOWS.~WS bi ket truoc khi cai Win
Assert-Test "system_ops.rs phai don dep stale `$WINDOWS.~BT va `$WINDOWS.~WS truoc khi cai Win" {
    $opsContent -match '\$WINDOWS\.~BT'
}

# 3. system_ops.rs phai ho tro action get_target_partitions de quet cac phan vung o dia cai Win
Assert-Test "system_ops.rs phai ho tro action get_target_partitions liet ke cac phan vung o dia" {
    $opsContent -match 'get_target_partitions' -or $opsContent -match 'collect_target_partitions'
}

# 4. system_ops.rs phai ho tro target_drive va che do custom (hien bang chon phan vung native cua Setup)
Assert-Test "system_ops.rs phai ho tro che do custom va tham so target_drive" {
    $opsContent -match 'custom' -and $opsContent -match 'target_drive'
}

# 5. main.rs phai chuyen huong get_target_partitions va truyen target_drive vao deploy_windows
Assert-Test "main.rs phai dispatch get_target_partitions va truyen target_drive vao deploy_windows" {
    $mainContent -match 'get_target_partitions' -and $mainContent -match 'target_drive'
}

# 6. index.html phai co the chon phan vung cai dat #select-target-drive
Assert-Test "index.html phai chua the chon o dia cai dat #select-target-drive trong view Cài Win" {
    $htmlContent -match 'id="select-target-drive"'
}

# 7. app.js phai co ham loadTargetPartitions va truyen target_drive khi goi startWinDeploy
Assert-Test "app.js phai dinh nghia loadTargetPartitions va truyen target_drive" {
    $appJsContent -match 'loadTargetPartitions' -and $appJsContent -match 'target_drive'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
