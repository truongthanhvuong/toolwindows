# =========================================================================
# TDD TEST SUITE: WINDOWS 11 100% SILENT PRO DEPLOYMENT & UNATTEND OOBE BYPASS
# tests/Test-Win11SilentProDeployment.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN11 100% SILENT PRO DEPLOYMENT & OOBE BYPASS    " -ForegroundColor Yellow -BackgroundColor Black
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

# 1. system_ops.rs phai tao tep unattend.xml chua Generic Setup Key cua Windows Pro (VK7JG-NPHTM-C97JM-9MPGT-3V66T)
Assert-Test "1. Sinh cau hinh unattend.xml voi Generic Product Key cua Windows Pro (VK7JG-NPHTM-C97JM-9MPGT-3V66T) va WillShow Never" {
    $opsContent -match 'VK7JG-NPHTM-C97JM-9MPGT-3V66T' -and $opsContent -match '<WillShow>Never<\/WillShow>'
}

# 2. unattend.xml phai chua OOBE Bypass day du: HideEULAPage, HideLocalAccountScreen, HideOnlineAccountScreens, HideWirelessSetupInOOBE, ProtectYourPC
Assert-Test "2. unattend.xml chua day du cau hinh bo qua OOBE, bo qua Microsoft Account va cau hoi quyen rieng tu" {
    $opsContent -match '<HideEULAPage>true<\/HideEULAPage>' -and
    $opsContent -match '<HideLocalAccountScreen>true<\/HideLocalAccountScreen>' -and
    $opsContent -match '<HideOnlineAccountScreens>true<\/HideOnlineAccountScreens>' -and
    $opsContent -match '<HideWirelessSetupInOOBE>true<\/HideWirelessSetupInOOBE>' -and
    $opsContent -match '<ProtectYourPC>3<\/ProtectYourPC>'
}

# 3. unattend.xml phai tao tai khoan Local Administrator va kich hoat AutoLogon de vao thang Desktop
Assert-Test "3. unattend.xml tao tai khoan Local Admin va bat AutoLogon de vao thang Desktop khong can nhap mat khau" {
    $opsContent -match '<AutoLogon>' -and
    $opsContent -match '<Enabled>true<\/Enabled>' -and
    $opsContent -match '<LocalAccount' -and
    $opsContent -match '<Group>Administrators<\/Group>'
}

# 4. Phai nap PID.txt voi key Windows Pro vao thu muc Sources de khoa chat edition Pro
Assert-Test "4. Nap PID.txt khoa chat edition Windows Pro trong thu muc Sources" {
    $opsContent -match 'PID\.txt' -and $opsContent -match 'Value=VK7JG-NPHTM-C97JM-9MPGT-3V66T'
}

# 5. Phai nap unattend.xml vao nhieu vi tri chong loi (Panther, $WINDOWS.~BT, root o dia)
Assert-Test "5. Luu tru unattend.xml vao thu muc Panther va staging path de Windows Setup doc tu dong" {
    $opsContent -match 'Panther\\unattend\.xml' -or $opsContent -match 'Sources\\Panther'
}

# 6. setup_args trong che do clean phai dung cu phap chuan /auto clean va khong kem /unattend: (chong loi cu phap vi unattend da duoc nap qua autounattend.xml)
Assert-Test "6. setup_args che do clean phai dung cu phap /auto clean chuan Microsoft khong gay loi tham so" {
    $opsContent -match '\/auto clean \/eula accept' -and (-not ($opsContent -match 'format!\("[^"]*\/auto clean[^"]*\/unattend:'))
}

# 7. specialize pass phai inject BypassNRO vao Registry de Windows 11 khong bat ket noi mang
Assert-Test "7. specialize pass inject BypassNRO vao Registry chong bat mang Windows 11" {
    $opsContent -match 'BypassNRO'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
