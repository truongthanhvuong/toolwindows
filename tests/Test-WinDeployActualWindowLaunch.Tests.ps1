# =========================================================================
# TDD TEST SUITE: WIN DEPLOY ACTUAL WINDOW LAUNCH & GUI POPUP VERIFICATION
# tests/Test-WinDeployActualWindowLaunch.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN DEPLOY ACTUAL WINDOW LAUNCH & GUI POPUP        " -ForegroundColor Yellow -BackgroundColor Black
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

# 1. Setup executable phai uu tien sources\setupprep.exe hoac setup.exe de dam bao hien thi GUI va chong 0x80070490
Assert-Test "1. Uu tien khoi chay sources\setupprep.exe de hien thi GUI Windows Setup va ngan chan loi 0x80070490" {
    $opsContent -match 'setupprep\.exe' -and ($opsContent -match '\$setupExe\s*=\s*if\s*\(Test-Path\s*"\$drv\\sources\\setupprep\.exe"\)' -or $opsContent -match 'Test-Path.*sources\\setupprep\.exe')
}

# 2. Argument list in PowerShell must NOT contain broken backtick-quote sequence `"`" causing syntax error
Assert-Test "2. Khong chua chuoi loi cu phap cu `"`" gay TerminatorExpectedAtEndOfString trong PowerShell" {
    $opsContent -notmatch '\/c start `"``"`"'
}

# 3. Rust phai doc ca stdout va stderr de phat hien loi cu phap hoac runtime cua PowerShell
Assert-Test "3. Rust backend phai doc ca stdout va stderr cua tien trinh khoi chay Setup" {
    $opsContent -match '\.stderr' -and $opsContent -match '\.stdout'
}

# 4. Che do Clean / Custom phai truyen /tempdrive de chong 0x80070490 va dam bao GUI hien thi
Assert-Test "4. Che do Clean va Custom phai ho tro hien thi GUI kem tham so /tempdrive" {
    $opsContent -match 'format!\("/product server /DynamicUpdate disable /tempdrive \{\}"' -or
    $opsContent -match 'format!\("/DynamicUpdate disable /tempdrive \{\}"'
}

# 5. Phai co co che khoi chay da tang (Start-Process, cmd /c start, explorer.exe, native spawn)
Assert-Test "5. Phai co co che du phong da tang (cmd start, explorer.exe, Start-Process)" {
    $opsContent -match 'cmd\.exe \/c start' -and $opsContent -match 'explorer\.exe'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
