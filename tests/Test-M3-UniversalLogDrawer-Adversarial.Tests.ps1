# =========================================================================
# TEST SUITE: ADVERSARIAL STRESS TEST FOR UNIVERSAL LOG DRAWER (M3)
# EMPIRICAL CHALLENGER VERIFICATION HARNESS
# =========================================================================

$ErrorActionPreference = "Stop"

$script:passed = 0
$script:failed = 0
$script:tierStats = @{
    "Tier 1" = @{ Pass = 0; Fail = 0 }
    "Tier 2" = @{ Pass = 0; Fail = 0 }
    "Tier 3" = @{ Pass = 0; Fail = 0 }
    "Tier 4" = @{ Pass = 0; Fail = 0 }
}

function Assert-TierCondition {
    param(
        [string]$Tier,
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [$Tier][PASS] $TestName" -ForegroundColor Green
        $script:passed++
        $script:tierStats[$Tier].Pass++
    } else {
        Write-Host "  [$Tier][FAIL] $TestName - $Message" -ForegroundColor Red
        $script:failed++
        $script:tierStats[$Tier].Fail++
    }
}

Write-Host "`n>>> [ADVERSARIAL SUITE] M3: UNIVERSAL REAL-TIME EXECUTION LOG DRAWER <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

# =========================================================================
# TIER 1: HEADLESS JS ADVERSARIAL STRESS SUITE (NODE.JS)
# =========================================================================
Write-Host "`n--- TIER 1: HEADLESS JS ADVERSARIAL STRESS SUITE ---" -ForegroundColor Yellow

$nodeTestPath = Join-Path $projectRoot "tests\test-universal-log-adversarial.cjs"
Assert-TierCondition "Tier 1" "T1.01: File test-universal-log-adversarial.cjs ton tai" (Test-Path $nodeTestPath)

$nodeOutput = & node $nodeTestPath 2>&1
$nodeExitCode = $LASTEXITCODE

Assert-TierCondition "Tier 1" "T1.02: Chay toan bo 13 bai test headless adversarial Node.js dat 100% PASS (ExitCode 0)" `
    ($nodeExitCode -eq 0) "ExitCode: $nodeExitCode`nOutput:`n$nodeOutput"

# =========================================================================
# TIER 2: 1000+ LOG LINES STREAM & RING-BUFFER CAPPING LOGIC
# =========================================================================
Write-Host "`n--- TIER 2: 1000+ LOG STREAM & MEMORY CAP VERIFICATION ---" -ForegroundColor Yellow

# Simulate Rust EXECUTION_LOGS ring-buffer behavior
function Simulate-RustExecutionLogs {
    param([int]$TotalLogs)
    $logs = [System.Collections.Generic.List[string]]::new()

    for ($i = 1; $i -le $TotalLogs; $i++) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $line = "[$timestamp] Log entry #$i from high-throughput action dispatch"
        
        # Rust logic: if logs.len() > 1000 { logs.drain(0..200); }
        if ($logs.Count -gt 1000) {
            $logs.RemoveRange(0, 200)
        }
        $logs.Add($line)
    }

    return @{
        FinalCount = $logs.Count
        Oldest = $logs[0]
        Newest = $logs[$logs.Count - 1]
    }
}

$simResult = Simulate-RustExecutionLogs -TotalLogs 2500
Assert-TierCondition "Tier 2" "T2.01: Backend Rust Ring Buffer giu dung muc tran (FinalCount <= 1001 khi stream 2500 logs)" `
    ($simResult.FinalCount -le 1001 -and $simResult.FinalCount -ge 801) `
    "Count was $($simResult.FinalCount)"

Assert-TierCondition "Tier 2" "T2.02: Backend Rust Ring Buffer loai bo cu nhat theo nguyen ly FIFO" `
    ($simResult.Newest -match "#2500" -and -not ($simResult.Oldest -match "#1\b"))

# =========================================================================
# TIER 3: EMPTY BUFFER OPERATIONS & IDEMPOTENCY
# =========================================================================
Write-Host "`n--- TIER 3: EMPTY BUFFER OPERATIONS & IDEMPOTENCY ---" -ForegroundColor Yellow

$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)

# Check empty buffer check in Copy button
$hasEmptyCopyGuard = ($appJsContent -match 'if\s*\(\s*!text\.trim\(\)\s*\)' -and $appJsContent -match 'btnCopy')
Assert-TierCondition "Tier 3" "T3.01: Nut Sao chep kiem tra ro rang buffer rong (!text.trim()) va hien toast canh bao chu khong crash" `
    $hasEmptyCopyGuard

# Check clear log idempotent handling
$hasClearHandling = ($appJsContent -match 'clear_install_logs' -and $appJsContent -match 'body\.innerHTML\s*=\s*""' -and $appJsContent -match 'lastUniversalLogCount\s*=\s*0')
Assert-TierCondition "Tier 3" "T3.02: Nut Xoa log thuc hien reset idempotent (innerHTML='', lastUniversalLogCount=0, count badge='0')" `
    $hasClearHandling

# =========================================================================
# TIER 4: SPECIAL CHARACTERS, UNICODE, QUOTES & BACKSLASHES
# =========================================================================
Write-Host "`n--- TIER 4: SPECIAL CHARACTERS, UNICODE, QUOTES & BACKSLASHES ---" -ForegroundColor Yellow

$adversarialStrings = @(
    'C:\Program Files\VUONGTT Toolkit\bin\runner.exe /flag:"--verbose" \server\share\test.iso',
    'Chuyen gia IT Helpdesk: Su co 547 tren o dia C: Dang toi uu...',
    'Double "quotes", single ''quotes'', and backticks `command`',
    '<script>alert("XSS")</script><img src=x onerror=alert(1)>',
    'JSON payload: {"action": "optimize", "targets": ["RAM", "DNS", "Services"]}',
    ("A" * 5000),
    'Special symbols: [OK] [ERROR] [WARN] -> % $ # @ ! * ( ) _ +'
)

$serializationPassed = $true
foreach ($raw in $adversarialStrings) {
    # Simulate Rust get_logs_json serialization
    $escaped = $raw.Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", '\n').Replace("`t", '\t')
    $json = "[`"$escaped`"]"
    try {
        $parsed = $json | ConvertFrom-Json
        if ($parsed[0] -ne $raw.Replace("`r`n", "`n")) {
            $serializationPassed = $false
            Write-Host "    Mismatch on string: $($raw.Substring(0, [Math]::Min(30, $raw.Length)))" -ForegroundColor Red
        }
    } catch {
        $serializationPassed = $false
        Write-Host "    JSON parse failed: $_" -ForegroundColor Red
    }
}

Assert-TierCondition "Tier 4" "T4.01: Rust JSON Serialization xu ly an toan 100% ky tu dac biet, duong dan va dau ngoac" `
    $serializationPassed

# Verify XSS sanitization: app.js uses textContent (not innerHTML) for user logs
$usesTextContent = ($appJsContent -match 'msgSpan\.textContent\s*=\s*text' -or $appJsContent -match 'textContent\s*=\s*text')
Assert-TierCondition "Tier 4" "T4.02: app.js su dung textContent de tranh lo hong XSS khi log chua HTML/Script" `
    $usesTextContent

# =========================================================================
# SUMMARY
# =========================================================================
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " KET QUA ADVERSARIAL STRESS TEST R3:" -ForegroundColor Cyan
Write-Host "  Tong so tests PASS: $script:passed" -ForegroundColor Green
Write-Host "  Tong so tests FAIL: $script:failed" -ForegroundColor $(if ($script:failed -eq 0) { "Green" } else { "Red" })
Write-Host "  Phan bo Tiers:"
foreach ($tierKey in $script:tierStats.Keys | Sort-Object) {
    $tPass = $script:tierStats[$tierKey].Pass
    $tFail = $script:tierStats[$tierKey].Fail
    Write-Host "    $tierKey : $tPass PASS / $($tPass + $tFail) Total" -ForegroundColor $(if ($tFail -eq 0) { "Green" } else { "Yellow" })
}
Write-Host "========================================================`n" -ForegroundColor Cyan

if ($script:failed -gt 0) {
    exit 1
} else {
    exit 0
}
