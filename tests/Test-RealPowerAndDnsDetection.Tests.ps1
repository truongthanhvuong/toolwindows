param()

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

function Assert-True($condition, $testName) {
    $script:TotalTests++
    if ($condition) {
        $script:PassedTests++
        Write-Host "  [PASS] $testName" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "  [FAIL] $testName" -ForegroundColor Red
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$rustOps     = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$rustMain    = Join-Path $projectRoot "src-tauri\src\main.rs"
$uiHtml      = Join-Path $projectRoot "src-ui\index.html"
$uiJs        = Join-Path $projectRoot "src-ui\app.js"

Write-Host ">>> KIEM THU GOI NGUON THUC TE, DNS THUC TE VA CHE DO 24/7 <<<" -ForegroundColor Cyan

# Group 1: UI HTML
Write-Host "`n--- Nhom 1: Giao dien UI (index.html) ---" -ForegroundColor Magenta
$htmlContent = if (Test-Path $uiHtml) { [System.IO.File]::ReadAllText($uiHtml, [System.Text.Encoding]::UTF8) } else { "" }

Assert-True ($htmlContent -match 'id="active-power-badge"') "Phai co badge id='active-power-badge'"
Assert-True ($htmlContent -match 'data-plan="never_sleep"') "Phai co nut chon data-plan='never_sleep'"
Assert-True ($htmlContent -match 'toggleNeverSleep') "Phai co nut bam toggleNeverSleep"
Assert-True ($htmlContent -match 'id="active-dns-info"') "Phai co khu vuc id='active-dns-info'"
Assert-True ($htmlContent -match 'id="toggle-dark-theme"') "Toggle Dark Theme phai co id"
Assert-True ($htmlContent -match 'id="toggle-show-ext"') "Toggle Show Ext phai co id"

# Group 2: Controller JS
Write-Host "`n--- Nhom 2: Controller Frontend (app.js) ---" -ForegroundColor Magenta
$jsContent = if (Test-Path $uiJs) { [System.IO.File]::ReadAllText($uiJs, [System.Text.Encoding]::UTF8) } else { "" }

Assert-True ($jsContent -match 'syncRealWinOptimizeState') "app.js phai co ham syncRealWinOptimizeState"
Assert-True ($jsContent -match 'toggleNeverSleep') "app.js phai co ham toggleNeverSleep"
Assert-True ($jsContent -match 'get_win_optimize_state') "app.js phai goi get_win_optimize_state"

# Group 3: Backend Rust
Write-Host "`n--- Nhom 3: Backend Rust ---" -ForegroundColor Magenta
$opsContent = if (Test-Path $rustOps) { [System.IO.File]::ReadAllText($rustOps, [System.Text.Encoding]::UTF8) } else { "" }
$mainContent = if (Test-Path $rustMain) { [System.IO.File]::ReadAllText($rustMain, [System.Text.Encoding]::UTF8) } else { "" }

Assert-True ($opsContent -match 'collect_win_optimize_state') "system_ops.rs phai co ham collect_win_optimize_state"
Assert-True ($opsContent -match 'never_sleep') "system_ops.rs phai ho tro never_sleep"
Assert-True ($mainContent -match 'get_win_optimize_state') "main.rs phai dinh tuyen get_win_optimize_state"

# Group 4: Real System Checks
Write-Host "`n--- Nhom 4: Kiem tra thong so thuc te ---" -ForegroundColor Magenta
$realScheme = (powercfg /getactivescheme | Out-String).Trim()
Assert-True ($realScheme.Length -gt 0) "powercfg getactivescheme hop le: $realScheme"

$realDns = (Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object -First 1)
Assert-True ($realDns -ne $null) "Nhan dien duoc DNS thuc te: $($realDns.ServerAddresses -join ', ')"

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "KET QUA: $script:PassedTests / $script:TotalTests PASS" -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
