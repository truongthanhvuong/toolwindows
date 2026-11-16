# ==============================================================================
# BỘ KIỂM THỬ ĐỘC LẬP (EMPIRICAL CHALLENGER TEST HARNESS) - MILESTONE 1
# ==============================================================================

$ErrorActionPreference = "Continue"
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:Failures = @()

function Assert-Check {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$FailureMessage = ""
    )
    $script:TotalTests++
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $script:PassedTests++
    } else {
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        if ($FailureMessage) {
            Write-Host "         Reason: $FailureMessage" -ForegroundColor Yellow
        }
        $script:FailedTests++
        $script:Failures += "$($TestName): $($FailureMessage)"
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "EMPIRICAL TEST SUITE: MILESTONE 1 VERIFICATION & STRESS TEST" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SECTION 1: Byte-Level BOM Inspection on Static Data Files
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 1: Kiem tra Byte-Level BOM tren cac file du lieu JSON <<<" -ForegroundColor Yellow

$filesToCheck = @(
    @{ Path = "src-ui/applications.json"; ExpectedCount = 428; KeyName = "applications" },
    @{ Path = "src-ui/uwp_presets.json"; ExpectedCount = 2; KeyName = "uwp_presets" },
    @{ Path = "src/Data/TroubleshootDatabase.json"; ExpectedCount = 547; KeyName = "troubleshoot" }
)

foreach ($f in $filesToCheck) {
    $fullPath = Join-Path $PSScriptRoot "..\$($f.Path)"
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    $hasBOM = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    
    Assert-Check `
        -TestName "1.1 BOM check cho $($f.Path) (Khong chua 0xEF 0xBB 0xBF)" `
        -Condition (-not $hasBOM) `
        -FailureMessage "Tep $($f.Path) chua UTF-8 BOM o 3 byte dau tien!"

    # Parse JSON
    $jsonObj = $null
    $parseOk = $false
    try {
        $rawText = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
        $jsonObj = $rawText | ConvertFrom-Json
        $parseOk = ($jsonObj -ne $null)
    } catch {
        $parseOk = $false
    }

    Assert-Check `
        -TestName "1.2 Parse JSON hop le cho $($f.Path)" `
        -Condition $parseOk `
        -FailureMessage "Loi cu phap JSON trong $($f.Path)"

    if ($f.KeyName -eq "applications") {
        $keyCount = ($jsonObj.PSObject.Properties | Measure-Object).Count
        Assert-Check `
            -TestName "1.3 applications.json phai chua dung 428 apps" `
            -Condition ($keyCount -eq 428) `
            -FailureMessage "So luong ung dung trong applications.json la $keyCount (mong doi: 428)"
    } elseif ($f.KeyName -eq "troubleshoot") {
        $probCount = $jsonObj.Problems.Count
        Assert-Check `
            -TestName "1.4 TroubleshootDatabase.json phai chua dung 547 su co" `
            -Condition ($probCount -eq 547) `
            -FailureMessage "So luong su co la $probCount (mong doi: 547)"
    }
}

# ------------------------------------------------------------------------------
# SECTION 2: Launch Live Rust Server & Establish IPC Connection
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 2: Khoi chay Server Rust de kiem thu Live Endpoints <<<" -ForegroundColor Yellow

$exePath = Join-Path $PSScriptRoot "..\src-tauri\target\debug\vuongtt_toolkit.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "Khong tim thay vuongtt_toolkit.exe! Chay cargo build..." -ForegroundColor Yellow
    cargo build --manifest-path (Join-Path $PSScriptRoot "..\src-tauri\Cargo.toml")
}

$proc = Start-Process -FilePath $exePath -PassThru
Start-Sleep -Milliseconds 1500

# Kill edge processes spawned by server
Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $proc.Id } | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

$tcpConn = Get-NetTCPConnection -OwningProcess $proc.Id -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
$port = if ($tcpConn) { $tcpConn.LocalPort } else { 58992 }
Write-Host "Live Server PID: $($proc.Id) dang hoat dong tren Port: $port" -ForegroundColor Green

$baseUrl = "http://127.0.0.1:$port"

try {
    # --------------------------------------------------------------------------
    # SECTION 3: Test Static Route Endpoints (GET /applications.json, etc.)
    # --------------------------------------------------------------------------
    Write-Host "`n>>> SECTION 3: Kiem thu Static Route Endpoints <<<" -ForegroundColor Yellow

    # Test 3.1: GET /applications.json
    $rawHttpApp = [System.Net.HttpWebRequest]::Create("$baseUrl/applications.json")
    $rawHttpApp.Timeout = 5000
    $respApp = $rawHttpApp.GetResponse()
    $statusApp = [int]$respApp.StatusCode
    $contentTypeApp = $respApp.ContentType
    
    $streamApp = $respApp.GetResponseStream()
    $memApp = New-Object System.IO.MemoryStream
    $streamApp.CopyTo($memApp)
    $appBytes = $memApp.ToArray()
    $respApp.Close()

    $appHasBOM = ($appBytes.Length -ge 3 -and $appBytes[0] -eq 0xEF -and $appBytes[1] -eq 0xBB -and $appBytes[2] -eq 0xBF)
    $appText = [System.Text.Encoding]::UTF8.GetString($appBytes)
    $appJson = $null
    try { $appJson = $appText | ConvertFrom-Json } catch {}
    $appCount = if ($appJson) { ($appJson.PSObject.Properties | Measure-Object).Count } else { 0 }

    Assert-Check `
        -TestName "3.1 GET /applications.json tra ve HTTP 200 OK" `
        -Condition ($statusApp -eq 200) `
        -FailureMessage "Status code la $statusApp"

    Assert-Check `
        -TestName "3.2 GET /applications.json co Content-Type application/json" `
        -Condition ($contentTypeApp -like "*application/json*") `
        -FailureMessage "Content-Type la $contentTypeApp"

    Assert-Check `
        -TestName "3.3 GET /applications.json response khong chua BOM va du 428 apps" `
        -Condition ((-not $appHasBOM) -and ($appCount -eq 428)) `
        -FailureMessage "hasBOM=$appHasBOM, appCount=$appCount"

    # Test 3.4: GET /uwp_presets.json
    $rawHttpUwp = [System.Net.HttpWebRequest]::Create("$baseUrl/uwp_presets.json")
    $rawHttpUwp.Timeout = 5000
    $respUwp = $rawHttpUwp.GetResponse()
    $statusUwp = [int]$respUwp.StatusCode
    $contentTypeUwp = $respUwp.ContentType
    
    $streamUwp = $respUwp.GetResponseStream()
    $memUwp = New-Object System.IO.MemoryStream
    $streamUwp.CopyTo($memUwp)
    $uwpBytes = $memUwp.ToArray()
    $respUwp.Close()

    $uwpHasBOM = ($uwpBytes.Length -ge 3 -and $uwpBytes[0] -eq 0xEF -and $uwpBytes[1] -eq 0xBB -and $uwpBytes[2] -eq 0xBF)

    Assert-Check `
        -TestName "3.4 GET /uwp_presets.json tra ve HTTP 200 OK va khong chua BOM" `
        -Condition ($statusUwp -eq 200 -and (-not $uwpHasBOM)) `
        -FailureMessage "status=$statusUwp, hasBOM=$uwpHasBOM"

    # --------------------------------------------------------------------------
    # SECTION 4: Test IPC Route Endpoints via POST /api/rust-invoke
    # --------------------------------------------------------------------------
    Write-Host "`n>>> SECTION 4: Kiem thu IPC API & Khong co BOM sau 'data': <<<" -ForegroundColor Yellow

    function Invoke-RawIpc {
        param([string]$CommandPayload)
        $req = [System.Net.HttpWebRequest]::Create("$baseUrl/api/rust-invoke")
        $req.Method = "POST"
        $req.ContentType = "application/json"
        $req.Timeout = 10000
        $reqBytes = [System.Text.Encoding]::UTF8.GetBytes($CommandPayload)
        $req.ContentLength = $reqBytes.Length
        $reqStream = $req.GetRequestStream()
        $reqStream.Write($reqBytes, 0, $reqBytes.Length)
        $reqStream.Close()

        $resp = $req.GetResponse()
        $respStream = $resp.GetResponseStream()
        $mem = New-Object System.IO.MemoryStream
        $respStream.CopyTo($mem)
        $rawBytes = $mem.ToArray()
        $resp.Close()

        $rawStr = [System.Text.Encoding]::UTF8.GetString($rawBytes)
        $parsedJson = $null
        try { $parsedJson = $rawStr | ConvertFrom-Json } catch { $parsedJson = $null }
        return @{
            RawBytes = $rawBytes;
            RawString = $rawStr;
            Json = $parsedJson
        }
    }

    # Test 4.1: get_store_applications
    $ipcStore = Invoke-RawIpc '{"command":"get_store_applications"}'
    $storeSuccess = ($ipcStore.Json -ne $null -and $ipcStore.Json.success -eq $true)
    
    # Check if raw string contains \uFEFF anywhere or right after "data":
    $dataIdx = $ipcStore.RawString.IndexOf('"data":')
    $charAfterData = if ($dataIdx -ge 0) { [int][char]($ipcStore.RawString[$dataIdx + 7]) } else { 0 }
    $hasBOMAfterData = ($charAfterData -eq 0xFEFF)
    $hasBOMInPayload = ($ipcStore.RawString.IndexOf([char]0xFEFF) -ge 0)

    Assert-Check `
        -TestName "4.1 IPC get_store_applications tra ve success=true va JSON hop le" `
        -Condition $storeSuccess `
        -FailureMessage "Payload: $($ipcStore.RawString.Substring(0, [math]::Min(100, $ipcStore.RawString.Length)))"

    Assert-Check `
        -TestName "4.2 IPC get_store_applications TUYET DOI KHONG co BOM sau 'data': hoac trong payload" `
        -Condition ((-not $hasBOMAfterData) -and (-not $hasBOMInPayload)) `
        -FailureMessage "hasBOMAfterData=$hasBOMAfterData, hasBOMInPayload=$hasBOMInPayload, charCode=$charAfterData"

    # Test 4.3: get_uwp_presets
    $ipcUwp = Invoke-RawIpc '{"command":"get_uwp_presets"}'
    $uwpSuccess = ($ipcUwp.Json -ne $null -and $ipcUwp.Json.success -eq $true)
    $uwpDataIdx = $ipcUwp.RawString.IndexOf('"data":')
    $uwpCharAfterData = if ($uwpDataIdx -ge 0) { [int][char]($ipcUwp.RawString[$uwpDataIdx + 7]) } else { 0 }
    $uwpBOMAfterData = ($uwpCharAfterData -eq 0xFEFF)
    $uwpHasBOMInPayload = ($ipcUwp.RawString.IndexOf([char]0xFEFF) -ge 0)

    Assert-Check `
        -TestName "4.3 IPC get_uwp_presets tra ve success=true va khong co BOM sau 'data':" `
        -Condition ($uwpSuccess -and (-not $uwpBOMAfterData) -and (-not $uwpHasBOMInPayload)) `
        -FailureMessage "uwpSuccess=$uwpSuccess, uwpBOMAfterData=$uwpBOMAfterData, charCode=$uwpCharAfterData"

    # Test 4.4: get_troubleshoot_database
    $ipcTrouble = Invoke-RawIpc '{"command":"get_troubleshoot_database"}'
    $troubleSuccess = ($ipcTrouble.Json -ne $null -and $ipcTrouble.Json.success -eq $true)
    $troubleDataIdx = $ipcTrouble.RawString.IndexOf('"data":')
    $troubleCharAfterData = if ($troubleDataIdx -ge 0) { [int][char]($ipcTrouble.RawString[$troubleDataIdx + 7]) } else { 0 }
    $troubleBOMAfterData = ($troubleCharAfterData -eq 0xFEFF)
    $troubleHasBOMInPayload = ($ipcTrouble.RawString.IndexOf([char]0xFEFF) -ge 0)
    $troubleCount = if ($ipcTrouble.Json -and $ipcTrouble.Json.data.Problems) { $ipcTrouble.Json.data.Problems.Count } else { 0 }

    Assert-Check `
        -TestName "4.4 IPC get_troubleshoot_database tra ve 547 su co khong co BOM" `
        -Condition ($troubleSuccess -and (-not $troubleBOMAfterData) -and (-not $troubleHasBOMInPayload) -and ($troubleCount -eq 547)) `
        -FailureMessage "troubleSuccess=$troubleSuccess, troubleCount=$troubleCount, troubleBOM=$troubleBOMAfterData, charCode=$troubleCharAfterData"

    # --------------------------------------------------------------------------
    # SECTION 5: Fast UWP Scan Latency Test (< 3.0s)
    # --------------------------------------------------------------------------
    Write-Host "`n>>> SECTION 5: Kiem thu do tre collect_uwp_apps (Fast Scan < 3s) <<<" -ForegroundColor Yellow

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ipcUwpScan = Invoke-RawIpc '{"command":"get_uwp_apps"}'
    $sw.Stop()
    $elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
    $uwpScanSuccess = ($ipcUwpScan.Json -ne $null -and $ipcUwpScan.Json.success -eq $true)
    $uwpAppsCount = if ($ipcUwpScan.Json -and $ipcUwpScan.Json.data) { $ipcUwpScan.Json.data.Count } else { 0 }

    Write-Host "  UWP Scan Thoi gian: $elapsedSec giay | So app tim thay: $uwpAppsCount" -ForegroundColor Cyan
    Assert-Check `
        -TestName "5.1 get_uwp_apps thoi gian phan hoi duoi 3 giay (Thuc te: $elapsedSec s)" `
        -Condition ($elapsedSec -lt 3.0) `
        -FailureMessage "Scan qua lau: $elapsedSec giay (gioi han 3s)"

    Assert-Check `
        -TestName "5.2 get_uwp_apps tra ve danh sach UWP hop le (count > 0)" `
        -Condition ($uwpScanSuccess -and $uwpAppsCount -gt 0) `
        -FailureMessage "success=$uwpScanSuccess, count=$uwpAppsCount"

    # --------------------------------------------------------------------------
    # SECTION 6: Winget & Uninstaller Schema Support
    # --------------------------------------------------------------------------
    Write-Host "`n>>> SECTION 6: Kiem thu Winget & Uninstaller Schema Compatibility <<<" -ForegroundColor Yellow

    # Test 6.1: Single app schema
    $ipcInstallSingle = Invoke-RawIpc '{"command":"install_apps","app":"MockApp.TestOnly"}'
    $installSingleOk = ($ipcInstallSingle.Json -ne $null)

    Assert-Check `
        -TestName "6.1 install_apps ho tro payload single 'app'" `
        -Condition $installSingleOk `
        -FailureMessage "Response: $($ipcInstallSingle.RawString)"

    # Test 6.2: Array apps schema
    $ipcInstallArray = Invoke-RawIpc '{"command":"install_apps","apps":["MockApp.TestOnly"]}'
    $installArrayOk = ($ipcInstallArray.Json -ne $null)

    Assert-Check `
        -TestName "6.2 install_apps ho tro payload array 'apps'" `
        -Condition $installArrayOk `
        -FailureMessage "Response: $($ipcInstallArray.RawString)"

    # Test 6.3: uninstall_app with target param
    $ipcUninstallTarget = Invoke-RawIpc '{"command":"run_system_action","actionId":"uninstall_app","target":"MockApp.NonExistent"}'
    $uninstallTargetOk = ($ipcUninstallTarget.Json -ne $null -and $ipcUninstallTarget.Json.success -eq $true)

    Assert-Check `
        -TestName "6.3 uninstall_app tiep nhan tham so 'target'" `
        -Condition $uninstallTargetOk `
        -FailureMessage "Response: $($ipcUninstallTarget.RawString)"

} finally {
    Write-Host "`n>>> SECTION 7: Don dep & Dong Server Rust <<<" -ForegroundColor Yellow
    try {
        if (-not $proc.HasExited) {
            $exitRes = Invoke-RawIpc '{"command":"window_control","action":"close"}'
            Start-Sleep -Milliseconds 400
            if (-not $proc.HasExited) {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "KET QUA STRESS TEST: $script:PassedTests PASS / $script:TotalTests TOTAL" -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
if ($script:Failures.Count -gt 0) {
    Write-Host "`nCAC LOI THAY DOI PHAT HIEN:" -ForegroundColor Red
    foreach ($f in $script:Failures) {
        Write-Host "  * $f" -ForegroundColor Yellow
    }
}
Write-Host "=================================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
