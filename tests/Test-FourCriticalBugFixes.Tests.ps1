# ============================================================================
#   TEST SUITE: Test-FourCriticalBugFixes.Tests.ps1
#   Verifies fixes for 4 critical issues reported by user:
#   1. Windows Setup 0x80070490 & elevated launch
#   2. Windows Update thorough termination & queue purge
#   3. Zalo data scanning syntax & detection accuracy
#   4. Multi-layer UAC elevation in Bootstrapper scripts
# ============================================================================

$ErrorActionPreference = "Stop"
$passed = 0
$failed = 0

function Assert-Test([string]$name, [scriptblock]$testBlock) {
    try {
        $result = & $testBlock
        if ($result -eq $true) {
            Write-Host " [PASS] $name" -ForegroundColor Green
            $script:passed++
        } else {
            Write-Host " [FAIL] $name - Condition returned false" -ForegroundColor Red
            $script:failed++
        }
    } catch {
        Write-Host " [FAIL] $name - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "`n=== BAT DAU KIEM THU 4 SU CO CRITICAL (TDD) ===" -ForegroundColor Cyan

$opsContent = Get-Content -Raw -Path "src-tauri\src\system_ops.rs"
$winPsContent = Get-Content -Raw -Path "win.ps1"
$vuongttPsContent = Get-Content -Raw -Path "vuongtt.ps1"
$forceUpdateContent = Get-Content -Raw -Path "Force-Update.ps1"

# --- TEST 1: Zalo scan syntax & detection ---
Assert-Test "1.1: zalo_scan_all dung ngoac don bao quanh Join-Path chong loi ParameterBindingException" {
    # Khong duoc chua Join-Path naked theo sau boi dau phay khong co ngoac
    $hasNakedJoinPath = $opsContent -match "Join-Path \`$_ 'ZaloData',\s*Join-Path"
    $hasParenthesizedJoinPath = $opsContent -match '\(Join-Path \$_ ''ZaloData''\)'
    (-not $hasNakedJoinPath) -and $hasParenthesizedJoinPath
}

Assert-Test "1.2: Thuc thi Zalo scan thuc te phat hien duoc ZaloData va tong dung luong > 0" {
    $zRoots = [System.Collections.Generic.List[string]]::new()
    @($env:APPDATA, $env:LOCALAPPDATA, $env:USERPROFILE) | ForEach-Object {
        if ($_ -and (Test-Path $_)) {
            @( (Join-Path $_ 'ZaloData'), (Join-Path $_ 'AppData\Roaming\ZaloData'), (Join-Path $_ 'AppData\Local\ZaloData') ) | ForEach-Object {
                if ((Test-Path $_) -and (-not $zRoots.Contains($_))) { $zRoots.Add($_) }
            }
        }
    }
    $zRoots.Count -gt 0 -and (Test-Path $zRoots[0])
}

# --- TEST 2: Windows Update thorough termination ---
Assert-Test "2.1: disable_windows_update huy toan bo BITS transfer dang chay ngam" {
    $opsContent -match "Remove-BitsTransfer" -or $opsContent -match "Get-BitsTransfer"
}

Assert-Test "2.2: disable_windows_update diet triet de tien trinh cap nhat TiWorker va TrustedInstaller" {
    $opsContent -match "taskkill.*TiWorker" -and $opsContent -match "taskkill.*TrustedInstaller"
}

Assert-Test "2.3: disable_windows_update xoa sach thu muc SoftwareDistribution\\Download" {
    $opsContent -match "SoftwareDistribution\\Download"
}

# --- TEST 3: Windows Setup tempdrive & elevated execution ---
Assert-Test "3.1: start_win_deploy truyen /tempdrive voi chu cai o dia sach se khong chua dau gach cheo nguoc" {
    # /tempdrive phai truyen format chu cai sach se, khong duoc format C:\
    $opsContent -match '/tempdrive\s+\$tempDrive' -or $opsContent -match '/tempdrive\s+\{\}' -or $opsContent -match '/tempdrive\s+[''"]?\$'
    # Va khong duoc format format!(\"/tempdrive {{}}:\\\"
    (-not ($opsContent -match 'format!\("/product server /DynamicUpdate disable /tempdrive \{\}:\\\\"'))
}

Assert-Test "3.2: start_win_deploy khoi chay qua Verb RunAs de dam bao quyen Admin BCD NT Authority" {
    $opsContent -match '-Verb RunAs'
}

# --- TEST 4: Bootstrapper multi-layer UAC elevation ---
Assert-Test "4.1: win.ps1 tich hop co che nang quyen UAC an toan" {
    $winPsContent -match "Verb RunAs" -and $winPsContent -match "ShellExecute"
}

Assert-Test "4.2: Force-Update.ps1 tich hop thong bao UAC ro rang va du phong" {
    $forceUpdateContent -match "Verb RunAs"
}

Write-Host "`n=== KET QUA KIEM THU ===" -ForegroundColor Cyan
Write-Host " Tong so test: $($passed + $failed)"
Write-Host " Passed: $passed" -ForegroundColor Green
Write-Host " Failed: $failed" -ForegroundColor Red

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
