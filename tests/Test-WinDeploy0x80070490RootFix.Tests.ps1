# =========================================================================
# TDD TEST SUITE: WIN DEPLOY 0x80070490 ROOT FIX
# tests/Test-WinDeploy0x80070490RootFix.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN DEPLOY 0x80070490 ROOT CAUSE FIX               " -ForegroundColor Yellow -BackgroundColor Black
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

# 1. /tempdrive phai truyen dang o dia kem dau hai cham va xuyet nguoc (vi du C:\ hoac C:), khong duoc truyen bare "C"
Assert-Test "1. /tempdrive phai duoc truyen dinh dang chuan co dau hai cham va xuyet ({}:\\ hoac {}:)" {
    $opsContent -match 'tempdrive.*\{.*?\}\:\\' -or $opsContent -match 'temp_drive_arg'
}

# 2. He thong phai uu tien goi sources\setupprep.exe thay vi root setup.exe de bypass loi 0x80070490
Assert-Test "2. He thong phai phat hien va uu tien chay sources\setupprep.exe de tranh loi BCD 0x80070490" {
    $opsContent -match 'setupprep\.exe' -and $opsContent -match 'Test-Path.*sources\\setupprep\.exe'
}

# 3. Thu muc lam viec phai duoc tro ve thu muc chuong trinh cai dat ($workDir hoac sources)
Assert-Test "3. WorkingDirectory phai duoc tro ve dung thu muc cua binary (sources hoac root)" {
    $opsContent -match 'Split-Path.*Parent' -or $opsContent -match '\$workDir'
}

# 4. Phai khoi tao truoc thu muc staging $WINDOWS.~BT tren o dich de setup.exe nhan dien ngay
Assert-Test "4. Phai khoi tao truoc thu muc staging $WINDOWS.~BT tren o dich de ngan chan loi khong tim thay o tam" {
    $opsContent -match 'New-Item.*\$WINDOWS\.~BT' -or $opsContent -match 'create_dir_all.*\$WINDOWS\.~BT' -or $opsContent -match 'mkdir.*\$WINDOWS\.~BT'
}

# 5. Phai don dep cache $WINDOWS.~BT va $Windows.~WS tren ca o C va o dich duoc chon
Assert-Test "5. Phai don dep sach cache stale tren ca o C va o dich duoc chon" {
    $opsContent -match '\$stalePaths' -and $opsContent -match 'target_drive|temp_drive'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
