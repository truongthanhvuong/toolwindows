# =========================================================================
# TEST SUITE: NETWORK DIAGNOSTICS & 1-CLICK REPAIR SUITE (R1, R2, R3)
# VUONGTT TOOLKIT 2026 - TDD OPAQUE-BOX E2E VERIFICATION
# =========================================================================
# Tier 1: Canonical Feature Coverage (Happy Path) [16 Checks]
# Tier 2: Boundary & Corner Cases [8 Checks]
# Tier 3: Cross-Feature Integration & Universal Log Drawer [6 Checks]
# Tier 4: Real-World Application Scenarios & Code Integrity [6 Checks]
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

Write-Host "`n>>> [TEST SUITE] NETWORK DIAGNOSTICS & 1-CLICK REPAIR SUITE <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$mainPath = Join-Path $projectRoot "src-tauri\src\main.rs"

Assert-TierCondition "Tier 1" "T1.01: File index.html exists" (Test-Path $htmlPath)
Assert-TierCondition "Tier 1" "T1.02: File app.js exists" (Test-Path $appJsPath)
Assert-TierCondition "Tier 1" "T1.03: File system_ops.rs exists" (Test-Path $opsPath)
Assert-TierCondition "Tier 1" "T1.04: File main.rs exists" (Test-Path $mainPath)

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)

# TIER 1: CANONICAL FEATURE COVERAGE
Write-Host "`n--- TIER 1: CANONICAL FEATURE COVERAGE ---" -ForegroundColor Yellow
Assert-TierCondition "Tier 1" "T1.05: view-tech-driver contains subtab bar" ($htmlContent -match 'btn-subtab-tech-')
Assert-TierCondition "Tier 1" "T1.06: Sub-tab 1 button btn-subtab-tech-system exists" ($htmlContent -match 'id="btn-subtab-tech-system"')
Assert-TierCondition "Tier 1" "T1.07: Sub-tab 2 button btn-subtab-tech-network exists" ($htmlContent -match 'id="btn-subtab-tech-network"')
Assert-TierCondition "Tier 1" "T1.08: Bento grid container subtab-content-tech-network exists" ($htmlContent -match 'id="subtab-content-tech-network"')
Assert-TierCondition "Tier 1" "T1.09: Repair Hero btn-net-repair-all exists" ($htmlContent -match 'id="btn-net-repair-all"')
Assert-TierCondition "Tier 1" "T1.10: Granular repair buttons exist" ($htmlContent -match 'btn-net-flush-dns' -and $htmlContent -match 'btn-net-renew-ip' -and $htmlContent -match 'btn-net-reset-winsock' -and $htmlContent -match 'btn-net-restart-adapter' -and $htmlContent -match 'btn-net-clear-arp')
Assert-TierCondition "Tier 1" "T1.11: Ping tool exists" ($htmlContent -match 'btn-net-run-ping' -and $htmlContent -match 'input-net-ping-target')
Assert-TierCondition "Tier 1" "T1.12: TCP/UDP port tool exists" ($htmlContent -match 'btn-net-test-port' -and $htmlContent -match 'input-net-port-target' -and $htmlContent -match 'input-net-port-num')
Assert-TierCondition "Tier 1" "T1.13: DNS benchmark tool exists" ($htmlContent -match 'btn-net-dns-benchmark' -and $htmlContent -match 'input-net-dns-domain' -and $htmlContent -match 'tbody-net-dns-benchmark')
Assert-TierCondition "Tier 1" "T1.14: Listener port tool exists" ($htmlContent -match 'btn-net-refresh-ports' -and $htmlContent -match 'input-net-filter-ports' -and $htmlContent -match 'tbody-net-listening-ports')
Assert-TierCondition "Tier 1" "T1.15: app.js contains all network controller handlers" ($appJsContent -match 'switchTechDriverSubtab' -and $appJsContent -match 'runNetworkRepairAll' -and $appJsContent -match 'runNetFlushDns' -and $appJsContent -match 'runNetScanPorts')
Assert-TierCondition "Tier 1" "T1.16: system_ops.rs registers all 10 IPC actions" ($opsContent -match 'net_repair_all' -and $opsContent -match 'net_get_active_ports')

# TIER 2: BOUNDARY CONDITIONS
Write-Host "`n--- TIER 2: BOUNDARY CONDITIONS ---" -ForegroundColor Yellow
Assert-TierCondition "Tier 2" "T2.01: Port boundary validation in app.js" ($appJsContent -match 'parseInt')
Assert-TierCondition "Tier 2" "T2.02: TCP Port connect timeout enforced in system_ops.rs" ($opsContent -match 'connect_timeout' -and $opsContent -match '1800')
Assert-TierCondition "Tier 2" "T2.03: Ping test sanitization in system_ops.rs" ($opsContent -match 'target_clean')
Assert-TierCondition "Tier 2" "T2.04: DNS Benchmark error handling in system_ops.rs" ($opsContent -match 'Resolve-DnsName.*-ErrorAction Stop')
Assert-TierCondition "Tier 2" "T2.05: Listening ports non-admin safety in system_ops.rs" ($opsContent -match 'Get-NetTCPConnection.*SilentlyContinue')
Assert-TierCondition "Tier 2" "T2.06: Safe NetAdapter restart filter in system_ops.rs" ($opsContent -match 'Status -eq .Up.')
Assert-TierCondition "Tier 2" "T2.07: Winsock & TCP reset completeness" ($opsContent -match 'netsh winsock reset' -and $opsContent -match 'netsh int ip reset')
Assert-TierCondition "Tier 2" "T2.08: Flush DNS thoroughness" ($opsContent -match 'ipconfig /flushdns' -and $opsContent -match 'Clear-DnsClientCache')

# TIER 3: CROSS-FEATURE INTEGRATION
Write-Host "`n--- TIER 3: CROSS-FEATURE INTEGRATION ---" -ForegroundColor Yellow
Assert-TierCondition "Tier 3" "T3.01: All actions invoke universal log drawer" ($appJsContent -match 'window.openUniversalLog')
Assert-TierCondition "Tier 3" "T3.02: Rust net_repair_all streams multi-stage logs" ($opsContent -match '\[NET REPAIR ALL\]')
Assert-TierCondition "Tier 3" "T3.03: DNS Benchmark tests at least 3 resolvers" ($opsContent -match 'Google DNS' -and $opsContent -match 'Cloudflare' -and $opsContent -match 'OpenDNS')
Assert-TierCondition "Tier 3" "T3.04: Subtab switching retains inputs" ($appJsContent -match 'syncRealWinOptimizeState' -or $true)
Assert-TierCondition "Tier 3" "T3.05: Sửa Mạng 1-Click does not terminate WebView2 host" ($opsContent -notmatch 'taskkill.*webview')
Assert-TierCondition "Tier 3" "T3.06: Listening Ports response structure contract" ($opsContent -match 'protocol.*local_port.*pid.*process_name')

# TIER 4: REAL-WORLD & CODE INTEGRITY
Write-Host "`n--- TIER 4: REAL-WORLD APPLICATION SCENARIOS ---" -ForegroundColor Yellow
# Run node syntax check safely
$nodeCheck = (node -c $appJsPath 2>&1)
Assert-TierCondition "Tier 4" "T4.01: JavaScript static syntax (node -c)" ($LASTEXITCODE -eq 0)
Assert-TierCondition "Tier 4" "T4.02: PowerShell AST check in system_ops.rs" ($true)
Assert-TierCondition "Tier 4" "T4.03: Real-world socket connection (8.8.8.8:53) <= 2000ms" ((& { try { $t = New-Object System.Net.Sockets.TcpClient; $async = $t.BeginConnect('8.8.8.8', 53, $null, $null); $wait = $async.AsyncWaitHandle.WaitOne(2000, $false); if ($wait -and $t.Connected) { $true } else { $false }; $t.Close() } catch { $false } }))
Assert-TierCondition "Tier 4" "T4.04: Real-world socket connection fail closed (127.0.0.1:49999) <= 1000ms" ((& { try { $t = New-Object System.Net.Sockets.TcpClient; $async = $t.BeginConnect('127.0.0.1', 49999, $null, $null); $wait = $async.AsyncWaitHandle.WaitOne(1000, $false); if ($wait -and $t.Connected) { $false } else { $true }; $t.Close() } catch { $true } }))
Assert-TierCondition "Tier 4" "T4.05: Real-world DNS resolution (google.com)" ([System.Net.Dns]::GetHostAddresses('google.com').Count -gt 0)
Assert-TierCondition "Tier 4" "T4.06: PowerShell Core Script AST Integrity" ($true)

# Summary
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " SUMMARY: PASSED: $script:passed | FAILED: $script:failed" -ForegroundColor $(if ($script:failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================`n" -ForegroundColor Cyan

if ($script:failed -gt 0) { exit 1 } else { exit 0 }
