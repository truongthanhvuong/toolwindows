# ==============================================================================
# BỘ TEST TỰ ĐỘNG ADVERSARIAL: KIỂM THỬ ĐỘ BỀN & BẢO MẬT NATIVE HTTP IPC DISPATCHER
# ==============================================================================

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:Vulnerabilities = @()

function Assert-Check {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$FailureMessage = "",
        [bool]$IsVulnerability = $false
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
        if ($IsVulnerability) {
            $script:Vulnerabilities += "[DEFECT] $($TestName): $($FailureMessage)"
        }
    }
}

Write-Host ">>> KHOI CHAY SERVER RUST DONG NATIVE HTTP IPC <<<" -ForegroundColor Cyan

$exePath = Join-Path $PSScriptRoot "..\src-tauri\target\debug\vuongtt_toolkit.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "Khong tim thay vuongtt_toolkit.exe! Bien dich lai..." -ForegroundColor Yellow
    cargo build --manifest-path (Join-Path $PSScriptRoot "..\src-tauri\Cargo.toml")
}

# Khoi chay server de test
$proc = Start-Process -FilePath $exePath -PassThru
Start-Sleep -Milliseconds 1200

# Tim port TCP ma server dang lang nghe
$tcpConn = Get-NetTCPConnection -OwningProcess $proc.Id -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
$port = if ($tcpConn) { $tcpConn.LocalPort } else { 58992 }
Write-Host "Server PID: $($proc.Id) dang lang nghe tren Port: $port" -ForegroundColor Green

# Don dep tien trinh con msedge do test proc sinh ra (tranh anh huong den nguoi dung)
Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $proc.Id } | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

$baseUrl = "http://127.0.0.1:$port"

function Send-IpcRequest {
    param(
        [string]$Path = "/api/rust-invoke",
        [string]$Method = "POST",
        [string]$Body = "{}",
        [string]$ContentType = "application/json"
    )
    try {
        $headers = @{ "Content-Type" = $ContentType }
        $resp = Invoke-RestMethod -Uri "$baseUrl$Path" -Method $Method -Body $Body -Headers $headers -TimeoutSec 5 -ErrorAction Stop
        return @{ Success = $true; Data = $resp; Raw = ($resp | ConvertTo-Json -Compress) }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message; Status = $_.Exception.Response.StatusCode.value__ }
    }
}

try {
    # --------------------------------------------------------------------------
    Write-Host "`n--- NHOM 1: Kiem tra Unknown Action Payload (Fail-Closed vs Silent-Success) ---" -ForegroundColor Magenta
    # --------------------------------------------------------------------------

    # Test 1.1: Direct unknown command payload
    $res1 = Send-IpcRequest -Body '{"command":"unknown_custom_action_123","payload":{}}'
    $isFailClosed1 = ($res1.Success -and $res1.Data.success -eq $false)
    Assert-Check `
        -TestName "1.1 Direct unknown command phai Fail-Closed voi success=false" `
        -Condition $isFailClosed1 `
        -FailureMessage "Server tra ve: $($res1.Raw). Server tra ve silent success=true cho unknown command thay vi fail-closed!" `
        -IsVulnerability $true

    # Test 1.2: Completely arbitrary JSON payload
    $res2 = Send-IpcRequest -Body '{"foo":"bar","action":"fake_action"}'
    $isFailClosed2 = ($res2.Success -and $res2.Data.success -eq $false)
    Assert-Check `
        -TestName "1.2 Arbitrary JSON payload phai Fail-Closed voi success=false" `
        -Condition $isFailClosed2 `
        -FailureMessage "Server tra ve: $($res2.Raw). Server tra ve silent success=true cho payload khong hop le!" `
        -IsVulnerability $true

    # Test 1.3: Unknown actionId qua run_system_action
    $res3 = Send-IpcRequest -Body '{"command":"run_system_action","actionId":"nonexistent_action_xyz_999"}'
    $isFailClosed3 = ($res3.Success -and $res3.Data.success -eq $false -and $res3.Data.message -match "không tồn tại|Lỗi")
    Assert-Check `
        -TestName "1.3 run_system_action voi actionId khong ton tai phai tra ve success=false" `
        -Condition $isFailClosed3 `
        -FailureMessage "Server tra ve: $($res3.Raw)" `
        -IsVulnerability $false

    # --------------------------------------------------------------------------
    Write-Host "`n--- NHOM 2: Malformed JSON & Unexpected Parameter Types (Crash/Panic Resistance) ---" -ForegroundColor Magenta
    # --------------------------------------------------------------------------

    # Test 2.1: Broken JSON syntax (unclosed brace)
    $resBroken = Send-IpcRequest -Body '{"command":"run_system_action", "actionId":"clean_temp'
    Assert-Check `
        -TestName "2.1 Broken JSON syntax khong gay crash tien trinh server" `
        -Condition (-not $proc.HasExited) `
        -FailureMessage "Tien trinh Rust server bi crash sau khi nhan JSON bi vo!" `
        -IsVulnerability $true

    # Test 2.2: Unexpected non-string parameter types (numbers, booleans, objects)
    $resTypes = Send-IpcRequest -Body '{"command":12345,"actionId":true,"apps":[1,2,3],"payload":{"nested":null}}'
    Assert-Check `
        -TestName "2.2 Parameter types khong dung kieu khong gay crash/panic" `
        -Condition (-not $proc.HasExited) `
        -FailureMessage "Server bi panic boi kieu du lieu khong hop le!"

    # Test 2.3: Array root instead of JSON object
    $resArray = Send-IpcRequest -Body '[{"command":"get_app_version"}]'
    Assert-Check `
        -TestName "2.3 Array root JSON payload duoc xu ly an toan" `
        -Condition (-not $proc.HasExited) `
        -FailureMessage "Server crash khi nhan array JSON!"

    # Test 2.4: Empty payload string
    $resEmpty = Send-IpcRequest -Body ''
    Assert-Check `
        -TestName "2.4 Empty HTTP body khong gay panic" `
        -Condition (-not $proc.HasExited) `
        -FailureMessage "Server crash khi nhan body rong!"

    # --------------------------------------------------------------------------
    Write-Host "`n--- NHOM 3: Window Control Subcommands & Substring Collisions ---" -ForegroundColor Magenta
    # --------------------------------------------------------------------------

    # Test 3.1: window_control voi command khong ton tai
    $resWinUnknown = Send-IpcRequest -Body '{"command":"window_control","action":"unsupported_action"}'
    $winUnknownOk = ($resWinUnknown.Success -and $resWinUnknown.Data.success -eq $false -and $resWinUnknown.Data.message -eq "Unknown window action")
    Assert-Check `
        -TestName "3.1 window_control voi action khong ho tro phai tra ve success=false" `
        -Condition $winUnknownOk `
        -FailureMessage "Server tra ve: $($resWinUnknown.Raw)"

    # Test 3.2: window_control minimize
    $resWinMin = Send-IpcRequest -Body '{"command":"window_control","action":"minimize"}'
    $winMinOk = ($resWinMin.Success -and ($resWinMin.Data.success -eq $true -or $resWinMin.Data.message -match "minimized|Window controlled"))
    Assert-Check `
        -TestName "3.2 window_control minimize phai thanh cong" `
        -Condition $winMinOk `
        -FailureMessage "Server tra ve: $($resWinMin.Raw)"

    # Test 3.3: Substring collision tren window_control: 'disclose' hoac note chua chu 'close'
    # Neu code dung body.contains("close") thi "disclose" se kich hoat lenh close va tat server!
    $resWinCollision = Send-IpcRequest -Body '{"command":"window_control","action":"disclose","note":"do not close"}'
    # Neu server bi tat, $proc.HasExited se la true!
    Start-Sleep -Milliseconds 300
    $collisionSafe = (-not $proc.HasExited)
    Assert-Check `
        -TestName "3.3 Substring collision 'disclose'/'note with close' khong duoc gay thoat nham server" `
        -Condition $collisionSafe `
        -FailureMessage "Server bi trigger thoat nham boi chuoi 'close' nam ben trong payload!" `
        -IsVulnerability $true

    # --------------------------------------------------------------------------
    Write-Host "`n--- NHOM 4: Quan Ly User & Admin Fleet Edge Cases ---" -ForegroundColor Magenta
    # --------------------------------------------------------------------------

    # Test 4.1: manage_local_user voi subAction khong ton tai
    $resUserUnknown = Send-IpcRequest -Body '{"command":"manage_local_user","subAction":"hack_account","username":"testuser"}'
    $userUnknownOk = ($resUserUnknown.Success -and $resUserUnknown.Data.success -eq $false)
    Assert-Check `
        -TestName "4.1 manage_local_user voi subAction khong hop le phai tra ve success=false" `
        -Condition $userUnknownOk `
        -FailureMessage "Server tra ve: $($resUserUnknown.Raw)"

    # Test 4.2: admin_login voi mat khau trong
    $resAdminEmpty = Send-IpcRequest -Body '{"command":"admin_login","payload":{"password":""},"password":""}'
    $adminEmptyOk = ($resAdminEmpty.Success -and $resAdminEmpty.Data.success -eq $false)
    Assert-Check `
        -TestName "4.2 admin_login voi mat khau trong phai fail-closed" `
        -Condition $adminEmptyOk `
        -FailureMessage "Server tra ve: $($resAdminEmpty.Raw)"

} finally {
    Write-Host "`n>>> DUNG TIEN TRINH RUST SERVER DANG TEST <<<" -ForegroundColor Cyan
    try {
        if (-not $proc.HasExited) {
            # Gui exit request
            $exitRes = Send-IpcRequest -Path "/api/exit" -Body "{}"
            Start-Sleep -Milliseconds 400
            if (-not $proc.HasExited) {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "KET QUA AUDIT: $script:PassedTests PASS / $script:TotalTests TOTAL" -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
if ($script:Vulnerabilities.Count -gt 0) {
    Write-Host "`nDANH SACH LOI / KHIEM KHUYET PHAT HIEN:" -ForegroundColor Red
    foreach ($v in $script:Vulnerabilities) {
        Write-Host "  * $v" -ForegroundColor Yellow
    }
}
Write-Host "==========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
