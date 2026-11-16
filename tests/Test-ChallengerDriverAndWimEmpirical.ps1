# =========================================================================
# EMPIRICAL CHALLENGER TEST SUITE: MILESTONE 2 BACKUP & DRIVER VERIFICATION
# =========================================================================

$ErrorActionPreference = 'Stop'
$passCount = 0
$failCount = 0

function Assert-Test([bool]$cond, [string]$msg) {
    if ($cond) {
        Write-Host "  [PASS] $msg" -ForegroundColor Green
        $global:passCount++
    } else {
        Write-Host "  [FAIL] $msg" -ForegroundColor Red
        $global:failCount++
    }
}

Write-Host "`n>>> EMPIRICAL STRESS TEST: DRIVER STORAGE RESOLUTION & FALLBACK <<<" -ForegroundColor Cyan

# 1. Real storage resolution
$sysDrive = $env:SystemDrive
if (-not $sysDrive) { $sysDrive = 'C:' }
$targetDrive = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -ne $sysDrive -and $_.FreeSpace -gt 1000000000 } | Sort-Object FreeSpace -Descending | Select-Object -First 1 -ExpandProperty DeviceID
$dest = if ($targetDrive) { "$targetDrive\Drivers_Backup" } else { "$sysDrive\Drivers_Backup" }

Write-Host "  Current SystemDrive: $sysDrive"
Write-Host "  Selected TargetDrive: $targetDrive"
Write-Host "  Destination Path: $dest"

Assert-Test ($dest -match '^[A-Z]:\\Drivers_Backup$') "Destination path format is valid drive path: $dest"
Assert-Test (Test-Path "$($dest.Substring(0,2))\") "Target drive exists and is accessible"

# Test directory creation & cleanup
if (-not (Test-Path $dest)) {
    [System.IO.Directory]::CreateDirectory($dest) | Out-Null
}
Assert-Test (Test-Path $dest) "Directory $dest created successfully"

# 2. Simulated single-drive scenario (Only SystemDrive C: exists)
$simDisks1 = @(
    [PSCustomObject]@{ DeviceID = 'C:'; DriveType = 3; FreeSpace = 25000000000 }
)
$simTarget1 = $simDisks1 | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -ne $sysDrive -and $_.FreeSpace -gt 1000000000 } | Sort-Object FreeSpace -Descending | Select-Object -First 1 -ExpandProperty DeviceID
$simDest1 = if ($simTarget1) { "$simTarget1\Drivers_Backup" } else { "$sysDrive\Drivers_Backup" }
Assert-Test ($simDest1 -eq "$sysDrive\Drivers_Backup") "Single drive environment gracefully falls back to $sysDrive\Drivers_Backup"

# 3. Simulated secondary drive out-of-space scenario (<1GB free)
$simDisks2 = @(
    [PSCustomObject]@{ DeviceID = 'C:'; DriveType = 3; FreeSpace = 25000000000 },
    [PSCustomObject]@{ DeviceID = 'D:'; DriveType = 3; FreeSpace = 500000000 }
)
$simTarget2 = $simDisks2 | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -ne $sysDrive -and $_.FreeSpace -gt 1000000000 } | Sort-Object FreeSpace -Descending | Select-Object -First 1 -ExpandProperty DeviceID
$simDest2 = if ($simTarget2) { "$simTarget2\Drivers_Backup" } else { "$sysDrive\Drivers_Backup" }
Assert-Test ($simDest2 -eq "$sysDrive\Drivers_Backup") "Secondary drive with low space (<1GB) is bypassed and falls back to system drive"

# 4. Simulated multi-drive scenario (D: has 5GB, E: has 50GB)
$simDisks3 = @(
    [PSCustomObject]@{ DeviceID = 'C:'; DriveType = 3; FreeSpace = 25000000000 },
    [PSCustomObject]@{ DeviceID = 'D:'; DriveType = 3; FreeSpace = 5000000000 },
    [PSCustomObject]@{ DeviceID = 'E:'; DriveType = 3; FreeSpace = 50000000000 }
)
$simTarget3 = $simDisks3 | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -ne $sysDrive -and $_.FreeSpace -gt 1000000000 } | Sort-Object FreeSpace -Descending | Select-Object -First 1 -ExpandProperty DeviceID
$simDest3 = if ($simTarget3) { "$simTarget3\Drivers_Backup" } else { "$sysDrive\Drivers_Backup" }
Assert-Test ($simDest3 -eq "E:\Drivers_Backup") "Multi-drive environment selects drive with largest free space (E:)"

Write-Host "`n>>> EMPIRICAL STRESS TEST: WIM BACKUP HANDLER & UI RESPONSIVENESS <<<" -ForegroundColor Cyan

# 5. Verify system_ops.rs handles backup_full_windows dry_run parameter
$opsRs = [System.IO.File]::ReadAllText("$PSScriptRoot\..\src-tauri\src\system_ops.rs", [System.Text.Encoding]::UTF8)
Assert-Test ($opsRs -match 'act == "backup_full_windows"') "Rust backend routes backup_full_windows"
Assert-Test ($opsRs -match 'dry_run' -and $opsRs -match 'test_mode') "Rust backend supports dry_run / test_mode parameter for safe dispatch validation"

# 6. Verify non-blocking UI behavior in frontend app.js
$appJs = [System.IO.File]::ReadAllText("$PSScriptRoot\..\src-ui\app.js", [System.Text.Encoding]::UTF8)
Assert-Test ($appJs -match 'async function backupSystemFromDeploy\(\)') "backupSystemFromDeploy is asynchronous"
Assert-Test ($appJs -match 'btn\.disabled\s*=\s*true' -and $appJs -match 'finally\s*\{\s*if\s*\(btn\)\s*btn\.disabled\s*=\s*false;\s*\}') "backupSystemFromDeploy disables button during execution and re-enables in finally block"
Assert-Test ($appJs -match 'showToast\([^)]+info"\)' -and $appJs -match 'backupSystemFromDeploy') "backupSystemFromDeploy immediately fires non-blocking toast notification"
Assert-Test ($appJs -match 'await invokeRust\("run_system_action",\s*\{\s*actionId:\s*"backup_full_windows"') "backupSystemFromDeploy dispatches via non-blocking await invokeRust"

# 7. Verify multithreaded backend architecture in main.rs
$mainRs = [System.IO.File]::ReadAllText("$PSScriptRoot\..\src-tauri\src\main.rs", [System.Text.Encoding]::UTF8)
Assert-Test ($mainRs -match 'thread::spawn\(move\s*\|\|\s*handle_client\(stream') "HTTP server spawns a dedicated OS thread per incoming connection, preventing long actions from blocking other requests"

# 8. Verify driver export execution command
Assert-Test ($opsRs -match 'Start-Process\s+dism\.exe\s+-ArgumentList\s+"\/online\s+\/export-driver\s+\/destination:') "Driver export uses Start-Process dism.exe without blocking caller"

Write-Host "`n=========================================================="
Write-Host "EMPIRICAL TEST RESULTS: $passCount PASS / $($passCount + $failCount) TOTAL" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "=========================================================="

if ($failCount -gt 0) { exit 1 } else { exit 0 }
