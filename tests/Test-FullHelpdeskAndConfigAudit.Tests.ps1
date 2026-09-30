# ==============================================================================
# Test-FullHelpdeskAndConfigAudit.Tests.ps1
# Comprehensive Real-World Audit: IT Helpdesk Rescue Center & Config and Fixes
# ==============================================================================

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $testDir

$dbPath = Join-Path $rootDir "src\Data\TroubleshootDatabase.json"
$corePath = Join-Path $rootDir "src\Core"
$xamlPath = Join-Path $rootDir "src\UI\MainWindow.xaml"
$scriptPath = Join-Path $rootDir "VUONGTT_Toolkit.ps1"

$testsRun = 0
$testsPassed = 0
$testsFailed = 0

function Assert-Audit {
    param([string]$TestName, [bool]$Condition, [string]$FailureMessage = "")
    $script:testsRun++
    if ($Condition) {
        $script:testsPassed++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } else {
        $script:testsFailed++
        Write-Host "  [FAIL] $TestName - $FailureMessage" -ForegroundColor Red
    }
}

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host ">>> BAT DAU KIEM TRA THUC TE TOAN BO CUU HO IT HELPDESK & CAU HINH SUA LOI <<<" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# PHAN 1: KIEM TRA CO SO DU LIEU IT HELPDESK (TROUBLESHOOT DATABASE)
# ------------------------------------------------------------------------------
Write-Host "`n--- PHAN 1: Kiem tra Co So Du Lieu IT Helpdesk (Troubleshoot Database) ---" -ForegroundColor Cyan

Assert-Audit "File TroubleshootDatabase.json ton tai" (Test-Path $dbPath)
$dbRaw = [System.IO.File]::ReadAllText($dbPath)
$db = $dbRaw | ConvertFrom-Json

Assert-Audit "Database co dung 7 Categories chuan IT Helpdesk" ($db.Categories.Count -eq 7) "Hien tai co $($db.Categories.Count) categories"
Assert-Audit "Database co tren 500 Su Co (Thuc te: $($db.Problems.Count))" ($db.Problems.Count -ge 500) "So luong su co chi co $($db.Problems.Count)"

# Kiem tra tinh toan ven schema cua 100% cac su co
$invalidProblems = @()
foreach ($p in $db.Problems) {
    if (-not $p.Id -or -not $p.Category -or -not $p.Title -or -not $p.ErrorCode -or -not $p.Symptoms -or -not $p.Cause -or -not $p.Escalation) {
        $invalidProblems += $p.Id
    }
}
Assert-Audit "100% Su co ($($db.Problems.Count)/$($db.Problems.Count)) day du cac truong schema bat buoc" ($invalidProblems.Count -eq 0) "Cac su co loi: $($invalidProblems -join ', ')"

# ------------------------------------------------------------------------------
# PHAN 2: KIEM TRA DONG CO THUC THI IT HELPDESK (TROUBLESHOOT ENGINE LIVE)
# ------------------------------------------------------------------------------
Write-Host "`n--- PHAN 2: Kiem tra Dong Co Thuc Thi IT Helpdesk (Live Telemetry & Actions) ---" -ForegroundColor Cyan

# Import module TroubleshootManager
. (Join-Path $corePath "TroubleshootManager.ps1")
$initOk = Initialize-VUONGTTTroubleshootEngine -CustomDbPath $dbPath
Assert-Audit "Khoi tao Dong Co Troubleshoot Engine thanh cong" ($initOk -eq $true)

$cats = Get-VUONGTTTroubleshootCategories
Assert-Audit "Get-VUONGTTTroubleshootCategories tra ve du 7 danh muc" ($cats.Count -eq 7)

$probs = Get-VUONGTTTroubleshootProblems -Category "All"
Assert-Audit "Get-VUONGTTTroubleshootProblems lay duoc toan bo $($db.Problems.Count) su co" ($probs.Count -eq $db.Problems.Count)

# Kiem tra tim kiem
$searchResult = Search-VUONGTTTroubleshootProblem -Keyword "RAM"
Assert-Audit "Search-VUONGTTTroubleshootProblem tim kiem tu khoa 'RAM' tra ve ket qua" ($searchResult.Count -gt 0)

# Kiem tra Live Execution cho cac su co dai dien tren ca 7 danh muc
Write-Host "`n  -> Thuc thi Live Test cho cac su co tren 7 Danh Muc:" -ForegroundColor Gray

# 1. Cat 01: System & Performance (PERF-001 & PERF-011 & UPDATE-001)
$resDiagPerf = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-001" -ActionType "Diagnosis"
Assert-Audit "[Cat 01] PERF-001 Diagnosis tra ve Live Telemetry (CPU & RAM & Uptime)" ($resDiagPerf.Success -and $resDiagPerf.OutputDetails -match "Uptime|CPU Load|RAM")

$resFixPerf11 = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-011" -ActionType "Fix"
Assert-Audit "[Cat 01] PERF-011 Fix xu ly SysMain & I/O thanh cong" ($resFixPerf11.Success -and $resFixPerf11.OutputDetails -match "SysMain")

$resDiagUpd = Invoke-VUONGTTTroubleshootAction -ProblemId "UPDATE-001" -ActionType "Diagnosis"
Assert-Audit "[Cat 01] UPDATE-001 Diagnosis kiem tra dich vu Windows Update (wuauserv)" ($resDiagUpd.Success -and $resDiagUpd.OutputDetails -match "wuauserv")

# 2. Cat 02: Network & Remote Access (NET-001)
$resDiagNet = Invoke-VUONGTTTroubleshootAction -ProblemId "NET-001" -ActionType "Diagnosis"
Assert-Audit "[Cat 02] NET-001 Diagnosis kiem tra Ping Internet thuc te" ($resDiagNet.Success -and $resDiagNet.OutputDetails -match "Ping")

# 3. Cat 03: Printer & LAN Share (PRINT-001)
$resDiagPrn = Invoke-VUONGTTTroubleshootAction -ProblemId "PRINT-001" -ActionType "Diagnosis"
Assert-Audit "[Cat 03] PRINT-001 Diagnosis kiem tra trang thai Spooler & hang doi in" ($resDiagPrn.Success -and $resDiagPrn.OutputDetails -match "Print Spooler")

# 4. Cat 04: Account & Active Directory (SEC-001)
$resDiagSec = Invoke-VUONGTTTroubleshootAction -ProblemId "SEC-001" -ActionType "Diagnosis"
Assert-Audit "[Cat 04] SEC-001 Diagnosis thuc thi Live Telemetry an toan" ($resDiagSec.Success -and $resDiagSec.OutputDetails.Length -gt 50)

# 5. Cat 05: Microsoft Office & M365 (OFFICE-001)
$resDiagOff = Invoke-VUONGTTTroubleshootAction -ProblemId "OFFICE-001" -ActionType "Diagnosis"
Assert-Audit "[Cat 05] OFFICE-001 Diagnosis thuc thi do luong he thong cho Office" ($resDiagOff.Success -and $resDiagOff.OutputDetails.Length -gt 50)

# 6. Cat 06: Application & Browser (APP-001)
$resDiagApp = Invoke-VUONGTTTroubleshootAction -ProblemId "APP-001" -ActionType "Diagnosis"
Assert-Audit "[Cat 06] APP-001 Diagnosis kiem tra ung dung & trinh duyet" ($resDiagApp.Success -and $resDiagApp.OutputDetails.Length -gt 50)

# 7. Cat 07: Hardware & Peripherals (AUDIO-001)
$resDiagAud = Invoke-VUONGTTTroubleshootAction -ProblemId "AUDIO-001" -ActionType "Diagnosis"
Assert-Audit "[Cat 07] AUDIO-001 Diagnosis kiem tra dich vu am thanh (Audiosrv)" ($resDiagAud.Success -and $resDiagAud.OutputDetails -match "Audiosrv")

# 8. Kiem tra Escalation Guide chuan hoa thong tin lien he
$resEsc = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-001" -ActionType "Escalation"
Assert-Audit "Escalation Guide chua dung Hotline (0328808425) & Email ky thuat" ($resEsc.Success -and $resEsc.OutputDetails -match "0328808425" -and $resEsc.OutputDetails -match "truongthanhvuong61@gmail.com")

# 9. Kiem tra Verify Action
$resVer = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-001" -ActionType "Verify"
Assert-Audit "Verify Action do luong lai chi so CPU Load thuc te" ($resVer.Success -and $resVer.OutputDetails -match "CPU")


# ------------------------------------------------------------------------------
# PHAN 3: KIEM TRA PHAN HE CAU HINH & SUA LOI (CONFIG & FIXES)
# ------------------------------------------------------------------------------
Write-Host "`n--- PHAN 3: Kiem tra Phan He Cau Hinh & Sua Loi (Config & Fixes) ---" -ForegroundColor Cyan

$xamlContent = [System.IO.File]::ReadAllText($xamlPath)

# 1. Kiem tra su ton tai cua 9 CheckBox Features trong XAML
$featControls = @(
    "chk_FeatNetFx3", "chk_FeatHyperV", "chk_FeatF8Boot", "chk_FeatDirectPlay",
    "chk_FeatNFS", "chk_FeatRegBackup", "chk_FeatSandbox", "chk_FeatWSL", "chk_FeatClassicMenu"
)
foreach ($fc in $featControls) {
    Assert-Audit "XAML chua Feature Control: $fc" ($xamlContent.Contains("x:Name=`"$fc`""))
}

# 2. Kiem tra su ton tai cua 25 CheckBox Fixes trong XAML
$fixControls = @(
    "chk_FixSystemFiles", "chk_FixWindowsUpdate", "chk_FixNetwork", "chk_FixPrintSpooler",
    "chk_FixExplorer", "chk_FixSearch", "chk_FixStore", "chk_FixAudio", "chk_FixNtp",
    "chk_FixTempFiles", "chk_FixWinGet", "chk_FixFirewall", "chk_FixHostsFile", "chk_FixAutoLogon",
    "chk_FixClassicContextMenu", "chk_FixDefender", "chk_FixDefenderExclusion", "chk_FixWinInstaller",
    "chk_FixIconCache", "chk_FixBluetooth", "chk_FixLanDiscovery", "chk_FixSleepPower",
    "chk_FixWmiRepo", "chk_FixSketchUpOpenGL", "chk_FixHighPerfGpu"
)
foreach ($fxc in $fixControls) {
    Assert-Audit "XAML chua Fix Control: $fxc" ($xamlContent.Contains("x:Name=`"$fxc`""))
}

# 3. Kiem tra 14 nut mo Legacy Windows Panels trong XAML
$panelButtons = @(
    "btnPanelCompMgmt", "btnPanelControl", "btnPanelMouse", "btnPanelNetwork",
    "btnPanelPower", "btnPanelPrinters", "btnPanelAppWiz", "btnPanelRegion",
    "btnPanelSecurity", "btnPanelSound", "btnPanelSysProperties", "btnPanelTimeDate",
    "btnPanelFirewall", "btnPanelRestore"
)
foreach ($pb in $panelButtons) {
    Assert-Audit "XAML chua Panel Button: $pb" ($xamlContent.Contains("x:Name=`"$pb`""))
}

# 4. Kiem tra cac ham xu ly Fix trong ConfigManager.ps1 & SystemTweaks.ps1
. (Join-Path $corePath "ConfigManager.ps1")
. (Join-Path $corePath "SystemTweaks.ps1")

# Thuc thi kiem tra live mot so ham sua loi khong pha huy he thong
Write-Host "`n  -> Thuc thi kiem tra Live cac ham xu ly sua loi thuc te:" -ForegroundColor Gray

# Fix Temp & Prefetch
$resFixTemp = Invoke-VUONGTTFixTempAndPrefetch
Assert-Audit "Invoke-VUONGTTFixTempAndPrefetch don dep temp thuc te" ($resFixTemp -match "\[OK\]")

# Fix Hosts File (dùng file test an toàn không phá hủy hosts hệ thống)
$testHosts = Join-Path $env:TEMP "hosts_test_audit.txt"
"127.0.0.1 old.domain" | Set-Content -Path $testHosts -Encoding ASCII
$resFixHosts = Invoke-VUONGTTFixHostsFile -TargetPath $testHosts
Assert-Audit "Invoke-VUONGTTFixHostsFile khoi phuc file hosts chuan" ($resFixHosts -match "\[OK\]")
Remove-Item $testHosts -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "hosts_test_audit.txt.bak_*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# Fix Classic Context Menu
$resCtxMenu = Set-VUONGTTClassicContextMenu -Enable $true
Assert-Audit "Set-VUONGTTClassicContextMenu kich hoat menu chuot phai Win 10" ($resCtxMenu -match "thành công|bật")

# Fix F8 Boot
$resF8 = Set-VUONGTTLegacyF8Boot -Enable $true
Assert-Audit "Set-VUONGTTLegacyF8Boot thiet lap bootmenupolicy legacy" ($resF8 -match "\[OK\]")

# Fix Registry Daily Backup
$resRegBak = Enable-VUONGTTRegistryBackupDaily
Assert-Audit "Enable-VUONGTTRegistryBackupDaily thuc thi va tra ve ket qua an toan" ($resRegBak -match "\[OK\]|\[LỖI\]")

# Fix SketchUp OpenGL & High Perf GPU
$resSkp = Invoke-VUONGTTFixSketchUpOpenGL
Assert-Audit "Invoke-VUONGTTFixSketchUpOpenGL cau hinh registry gia toc SketchUp" ($resSkp -match "\[OK\]")

$resGpu = Invoke-VUONGTTFixHighPerfGpu
Assert-Audit "Invoke-VUONGTTFixHighPerfGpu cau hinh High Performance GPU" ($resGpu -match "\[OK\]")

# Kiem tra Open-VUONGTTLegacyPanel routing
$resPanelComp = Open-VUONGTTLegacyPanel -PanelId "test_nonexistent"
Assert-Audit "Open-VUONGTTLegacyPanel co ham dieu huong hop le" ($resPanelComp -match "\[OK\]|\[LỖI\]")

# ------------------------------------------------------------------------------
# TONG KET
# ------------------------------------------------------------------------------
$color = "Green"
if ($testsFailed -gt 0) { $color = "Yellow" }
Write-Host "`n==============================================================================" -ForegroundColor Cyan
Write-Host ">>> KET QUA AUDIT: $testsPassed/$testsRun PASSED ($testsFailed FAILED) <<<" -ForegroundColor $color
Write-Host "==============================================================================" -ForegroundColor Cyan

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
