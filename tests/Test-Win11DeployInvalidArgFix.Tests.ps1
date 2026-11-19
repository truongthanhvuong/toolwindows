# =========================================================================
# TDD TEST SUITE: WIN 11 DEPLOY INVALID COMMAND LINE ARGUMENT FIX
# tests/Test-Win11DeployInvalidArgFix.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN 11 DEPLOY INVALID COMMAND LINE ARGUMENT FIX     " -ForegroundColor Yellow -BackgroundColor Black
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

# 1. Khong truyen /product server vao runtime setup_args (tranh loi The installation process was launched with an invalid command line argument tren Win 11)
Assert-Test "1. Khong truyen /product server truc tiep vao runtime setup_args cua Windows Setup" {
    $hasRuntimeProductServer = $opsContent -match 'format!\("[^"]*\/product server[^"]*"'
    (-not $hasRuntimeProductServer)
}

# 2. Tham so /tempdrive phai la ky tu o dia sach se khong chua dau gach cheo nguoc
Assert-Test "2. Tham so /tempdrive phai truyen o dia sach se (C hoac C:), khong chua dau gach cheo nguoc" {
    $hasTrailingSlashInTempdrive = $opsContent -match 'temp_drive_arg\s*=\s*format!\("\{.*?\}\:\\\\"\)'
    (-not $hasTrailingSlashInTempdrive)
}

# 3. Che do clean va custom phai su dung cu phap chuan cua Modern Setup
Assert-Test "3. Che do clean va custom su dung cu phap hop le /DynamicUpdate disable /tempdrive" {
    $opsContent -match 'format!\("/DynamicUpdate disable /tempdrive \{\}"'
}

# 4. Che do upgrade phai su dung cu phap chuan /auto upgrade /eula accept
Assert-Test "4. Che do upgrade su dung cu phap hop le /auto upgrade /eula accept" {
    $opsContent -match 'format!\("/auto upgrade /eula accept'
}

# 5. Registry LabConfig va MoSetup phai duoc bao toan de bypass TPM 2.0 / CPU an toan ma khong can /product server
Assert-Test "5. Tich hop Registry LabConfig va MoSetup de bypass TPM/CPU khong gay loi argument" {
    $opsContent -match 'LabConfig' -and $opsContent -match 'BypassTPMCheck' -and $opsContent -match 'MoSetup'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    exit 1
} else {
    exit 0
}
