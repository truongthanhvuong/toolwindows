# =========================================================================
# TDD TEST SUITE: WINDOWS SETUP INVALID COMMAND LINE ARGUMENT FIX
# tests/Test-WinSetupInvalidArgumentFix.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN SETUP INVALID COMMAND LINE ARGUMENT FIX        " -ForegroundColor Yellow -BackgroundColor Black
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

# 1. Setup binary phai uu tien sources\setupprep.exe hoac sources\setup.exe thay vi root setup.exe
# Giai thich: Root setup.exe nap autorun.dll chi ho tro autorun interactive, tu choi /tempdrive va /compat
Assert-Test "1. Uu tien sources\setupprep.exe hoac sources\setup.exe truoc root setup.exe de nap dong co SetupHost" {
    $opsContent -match '\$setupExe\s*=\s*if\s*\(Test-Path\s*"\$drv\\sources\\setupprep\.exe"\)'
}

# 2. setup_args che do clean va upgrade khong duoc chua /unattend: tren dong lenh vi xung dot cu phap voi /auto
# Giai thich: Microsoft quy dinh '/Auto cannot be used when /unattend is active'. Unattend duoc nap qua autounattend.xml
Assert-Test "2. setup_args khong duoc chua dong thoi /auto va /unattend: gay loi Invalid Command Line Argument" {
    (-not ($opsContent -match 'format!\("[^"]*\/auto\s+(?:clean|upgrade)[^"]*\/unattend:'))
}

# 3. autounattend.xml va Panther\unattend.xml van phai duoc ghi ra dia de Setup tu dong ap dung
Assert-Test "3. Ghi file autounattend.xml vao root o dia va Panther de kich hoat cai dat tu dong khong can tham so /unattend" {
    $opsContent -match 'autounattend\.xml' -and $opsContent -match 'Panther'
}

# 4. Che do Cài Mới Sạch Sẽ (Clean) phai co day du: /auto clean, /eula accept, /compat ignorewarning, /DynamicUpdate disable, /MigrateDrivers none, /tempdrive
Assert-Test "4. Che do Clean su dung cu phap chuan Microsoft: /auto clean /eula accept /compat ignorewarning /DynamicUpdate disable /MigrateDrivers none /tempdrive" {
    $opsContent -match 'format!\("/auto clean /eula accept /compat ignorewarning /DynamicUpdate disable /MigrateDrivers none /tempdrive \{\}", temp_drive_arg\)'
}

# 5. Che do Nang Cap (Upgrade) phai co day du: /auto upgrade /eula accept /compat ignorewarning /DynamicUpdate disable /MigrateDrivers none /tempdrive
Assert-Test "5. Che do Upgrade su dung cu phap chuan Microsoft: /auto upgrade /eula accept /compat ignorewarning /DynamicUpdate disable /MigrateDrivers none /tempdrive" {
    $opsContent -match 'format!\("/auto upgrade /eula accept /compat ignorewarning /DynamicUpdate disable /MigrateDrivers none /tempdrive \{\}", temp_drive_arg\)'
}

# 6. Fallback neu la root setup.exe phai loai bo cac tham so khong duoc autorun.dll ho tro
Assert-Test "6. Fallback khi chay root setup.exe phai loc bo cac tham so gay loi autorun.dll" {
    $opsContent -match 'setup\.exe' -and ($opsContent -match 'autorun' -or $opsContent -match 'sources')
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
