# ==============================================================================
# BỘ KIỂM THỬ ĐỘC LẬP & TẤN CÔNG STRESS-TEST (EMPIRICAL CHALLENGER TEST)
# PHÂN HỆ: R1 ANTI-BYPASS WEBSITE/GAME BLOCKER ENGINE (MILESTONE M1)
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

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "CHALLENGER 1: EMPIRICAL ADVERSARIAL STRESS TEST FOR R1 ANTI-BYPASS" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SECTION 1: Registry Edge Cases & Parent Key Creation
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 1: Kiem Tra Edge Case Registry Policies Chrome & Edge <<<" -ForegroundColor Yellow

# S1.1: Verify PowerShell AST and logic in system_ops.rs for policy auto-creation
$sysOpsContent = Get-Content -Path "src-tauri/src/system_ops.rs" -Raw -Encoding UTF8

$hasChromePolicy = $sysOpsContent -match [regex]::Escape("HKLM:\SOFTWARE\Policies\Google\Chrome")
$hasEdgePolicy   = $sysOpsContent -match [regex]::Escape("HKLM:\SOFTWARE\Policies\Microsoft\Edge")
$hasDnsModeOff   = $sysOpsContent -match "'DnsOverHttpsMode'\s*,\s*'off'" -or $sysOpsContent -match "-Name 'DnsOverHttpsMode' -Value 'off'"
$hasAutoCreate   = $sysOpsContent -match 'New-Item\s+-Path\s+\$polPath\s+-Force'

Assert-Check `
    -TestName "1.1 system_ops.rs dinh nghia policy Google Chrome" `
    -Condition $hasChromePolicy `
    -FailureMessage "Khong tim thay duong dan HKLM:\SOFTWARE\Policies\Google\Chrome trong system_ops.rs"

Assert-Check `
    -TestName "1.2 system_ops.rs dinh nghia policy Microsoft Edge" `
    -Condition $hasEdgePolicy `
    -FailureMessage "Khong tim thay duong dan HKLM:\SOFTWARE\Policies\Microsoft\Edge trong system_ops.rs"

Assert-Check `
    -TestName "1.3 system_ops.rs cau hinh DnsOverHttpsMode = 'off'" `
    -Condition $hasDnsModeOff `
    -FailureMessage "Khong tim thay thiet lap DnsOverHttpsMode = 'off' trong system_ops.rs"

Assert-Check `
    -TestName "1.4 system_ops.rs su dung New-Item -Force de tu dong tao parent key" `
    -Condition $hasAutoCreate `
    -FailureMessage "Thieu lenh New-Item -Path `$polPath -Force de tao key neu chua ton tai"

# S1.5: Empirical Sandbox Test - Simulate completely missing parent keys
$sandboxKey = "HKCU:\Software\VUONGTT_Challenge_Sandbox"
Remove-Item -Path $sandboxKey -Recurse -Force -ErrorAction SilentlyContinue

$deepChrome = "$sandboxKey\Google\Chrome"
$deepEdge   = "$sandboxKey\Microsoft\Edge"

$sandboxSuccess = $true
try {
    foreach ($pol in @($deepChrome, $deepEdge)) {
        if (-not (Test-Path $pol)) {
            New-Item -Path $pol -Force | Out-Null
        }
        Set-ItemProperty -Path $pol -Name "DnsOverHttpsMode" -Value "off" -Type String -Force
    }
} catch {
    $sandboxSuccess = $false
}

$chromeCreated = (Test-Path $deepChrome) -and ((Get-ItemProperty -Path $deepChrome -Name "DnsOverHttpsMode" -ErrorAction SilentlyContinue).DnsOverHttpsMode -eq "off")
$edgeCreated   = (Test-Path $deepEdge) -and ((Get-ItemProperty -Path $deepEdge -Name "DnsOverHttpsMode" -ErrorAction SilentlyContinue).DnsOverHttpsMode -eq "off")

Assert-Check `
    -TestName "1.5 Empirical: New-Item -Force tu dong tao duoc key con khi chua co parent key" `
    -Condition ($sandboxSuccess -and $chromeCreated -and $edgeCreated) `
    -FailureMessage "New-Item -Force that bai khi parent key chua ton tai!"

# S1.6: Clean Unblock Sandbox Test - Remove-ItemProperty only removes the property, not the key or neighbor properties
Set-ItemProperty -Path $deepChrome -Name "OtherEnterprisePolicy" -Value "PreservedValue" -Type String -Force
$unblockSandboxSuccess = $true
try {
    foreach ($pol in @($deepChrome, $deepEdge)) {
        if (Test-Path $pol) {
            Remove-ItemProperty -Path $pol -Name "DnsOverHttpsMode" -Force -ErrorAction SilentlyContinue
        }
    }
} catch {
    $unblockSandboxSuccess = $false
}

$propRemoved = $null -eq (Get-ItemProperty -Path $deepChrome -Name "DnsOverHttpsMode" -ErrorAction SilentlyContinue).DnsOverHttpsMode
$neighborPreserved = (Get-ItemProperty -Path $deepChrome -Name "OtherEnterprisePolicy" -ErrorAction SilentlyContinue).OtherEnterprisePolicy -eq "PreservedValue"

Assert-Check `
    -TestName "1.6 Empirical: Unblock chi xoa thuoc tinh DnsOverHttpsMode, giu nguyen key va cac policy khac" `
    -Condition ($unblockSandboxSuccess -and $propRemoved -and $neighborPreserved) `
    -FailureMessage "Unblock khong bao toan duoc key hoac lam hong cac enterprise policy khac"

Remove-Item -Path $sandboxKey -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# SECTION 2: Firewall Rule Idempotency & Collision Stress Test
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 2: Kiem Tra Idempotency & Tranh Trung Lap Rule Firewall <<<" -ForegroundColor Yellow

$hasPreDelete = $sysOpsContent -match 'netsh advfirewall firewall delete rule name="VUONGTT_Block_Facebook"'
$hasAddRule   = $sysOpsContent -match 'netsh advfirewall firewall add rule name="VUONGTT_Block_Facebook"'
$hasAllCidrs  = ($sysOpsContent -match "31\.13\.0\.0/16") -and
                ($sysOpsContent -match "157\.240\.0\.0/16") -and
                ($sysOpsContent -match "129\.134\.0\.0/16") -and
                ($sysOpsContent -match "185\.60\.216\.0/22") -and
                ($sysOpsContent -match "57\.144\.0\.0/14")

Assert-Check `
    -TestName "2.1 system_ops.rs xoa rule firewall cu truoc khi add (chong trung lap/stacking)" `
    -Condition $hasPreDelete `
    -FailureMessage "Thieu lenh netsh advfirewall firewall delete rule truoc khi add rule moi"

Assert-Check `
    -TestName "2.2 system_ops.rs tao outbound rule VUONGTT_Block_Facebook" `
    -Condition $hasAddRule `
    -FailureMessage "Thieu lenh add rule VUONGTT_Block_Facebook"

Assert-Check `
    -TestName "2.3 Firewall rule chan du 5 dai CIDR trong tam cua Meta" `
    -Condition $hasAllCidrs `
    -FailureMessage "Thieu mot hoac nhieu dai CIDR cua Facebook/Meta"

Assert-Check `
    -TestName "2.4 unblock_all_rules chua lenh xoa ca 2 rule VUONGTT_Block_Facebook va VUONGTT_Block_WebGame" `
    -Condition ($sysOpsContent -match 'netsh advfirewall firewall delete rule name="VUONGTT_Block_Facebook"' -and
                $sysOpsContent -match 'netsh advfirewall firewall delete rule name="VUONGTT_Block_WebGame"') `
    -FailureMessage "unblock_all_rules chua xoa rule firewall"

# ------------------------------------------------------------------------------
# SECTION 3: Domain Parsing, Custom Domains & Wildcard Stress Test
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 3: Kiem Tra Phan Tich Domain, Custom Domains va Wildcards <<<" -ForegroundColor Yellow

# S3.1: Verify Expanded Facebook Domains Count
$fbPattern = "'facebook'\s*=\s*@\(([^)]+)\)"
$fbMatch = [regex]::Match($sysOpsContent, $fbPattern)
$fbDomains = @()
if ($fbMatch.Success) {
    $fbRaw = $fbMatch.Groups[1].Value
    $fbDomains = [regex]::Matches($fbRaw, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value }
}

Assert-Check `
    -TestName "3.1 Facebook domain map phai co it nhat 17 ten mien" `
    -Condition ($fbDomains.Count -ge 17) `
    -FailureMessage "So luong Facebook domain hien tai: $($fbDomains.Count), ky vong >= 17"

$essentialDomains = @(
    'facebook.com', 'www.facebook.com', 'm.facebook.com', 'web.facebook.com',
    'fb.com', 'www.fb.com', 'fbcdn.net', 'www.fbcdn.net',
    'static.xx.fbcdn.net', 'scontent.xx.fbcdn.net', 'scontent.fbcdn.net', 'external.xx.fbcdn.net',
    'connect.facebook.net', 'edge-chat.facebook.com', 'graph.facebook.com',
    'messenger.com', 'www.messenger.com', 'm.messenger.com'
)
$missingFbDomains = @()
foreach ($d in $essentialDomains) {
    if ($fbDomains -notcontains $d) {
        $missingFbDomains += $d
    }
}

Assert-Check `
    -TestName "3.2 Danh sach domain Facebook bao gom tat ca cac endpoint thiet yeu" `
    -Condition ($missingFbDomains.Count -eq 0) `
    -FailureMessage "Thieu cac domain: $($missingFbDomains -join ', ')"

# S3.3: Stress test domain parser against noisy / dirty user inputs
$dirtyInputs = @"
https://gambling-site.com/login?ref=123
http://malicious-game.net:8080/play
# This is a comment line that should be skipped
  SPACED-DOMAIN.COM  
WWW.ALREADY-WWW.ORG
https://sub.domain.co.uk/path/file.html#hash
"@

$parsedDomains = @()
$lines = $dirtyInputs -split "[\r\n]+"
foreach ($line in $lines) {
    $d = $line.Trim().ToLower()
    if ($d -and -not $d.StartsWith("#")) {
        $d = $d -replace '^https?://', '' -replace '/.*$', '' -replace ':\d+$', ''
        if ($d) {
            $parsedDomains += $d
            if (-not $d.StartsWith("www.")) { $parsedDomains += "www.$d" }
        }
    }
}
$parsedDomains = $parsedDomains | Select-Object -Unique

Assert-Check `
    -TestName "3.3 Parser loc bo protocol http/https, query params, ports va comments" `
    -Condition ($parsedDomains -contains "gambling-site.com" -and
                $parsedDomains -contains "www.gambling-site.com" -and
                $parsedDomains -contains "spaced-domain.com" -and
                $parsedDomains -contains "www.already-www.org" -and
                -not ($parsedDomains -match "^#")) `
    -FailureMessage "Parser domain khong lam sach duoc du lieu dau vao ban"

# ------------------------------------------------------------------------------
# SECTION 4: Hosts File Clean Restoration & Idempotency
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 4: Kiem Tra Chu Trinh Ghi / Go Chan Hosts File <<<" -ForegroundColor Yellow

$originalMockHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
127.0.0.1       localhost
::1             localhost
192.168.1.100   printer.local
"@

# Simulate 3 consecutive block cycles
$currentHosts = $originalMockHosts
for ($i = 1; $i -le 3; $i++) {
    $pattern = '(?s)# === VUONGTT BLOCK RULES BEGIN ===.*?# === VUONGTT BLOCK RULES END ===\r?\n?'
    $cleaned = $currentHosts -replace $pattern, ''

    $blockLines = @(
        "# === VUONGTT BLOCK RULES BEGIN ===",
        "# Chặn Website & Game Trực Tuyến - VUONGTT Toolkit 2026",
        "# Thời gian áp dụng: 17/11/2026 12:00:00"
    )
    foreach ($dom in @('facebook.com', 'www.facebook.com')) {
        $blockLines += "0.0.0.0 $dom"
        $blockLines += "127.0.0.1 $dom"
        $blockLines += "::1 $dom"
    }
    $blockLines += "# === VUONGTT BLOCK RULES END ==="
    $currentHosts = $cleaned.TrimEnd() + "`r`n`r`n" + ($blockLines -join "`r`n") + "`r`n"
}

$blockRuleMatches = [regex]::Matches($currentHosts, "# === VUONGTT BLOCK RULES BEGIN ===")
Assert-Check `
    -TestName "4.1 Ap dung 3 lan lien tiep khong bi nhan doi block block trong hosts (chi co 1 block)" `
    -Condition ($blockRuleMatches.Count -eq 1) `
    -FailureMessage "Bi duplicate block markers sau nhieu lan ghi hosts: count = $($blockRuleMatches.Count)"

# Now simulate unblock
$unblockPattern = '(?s)# === VUONGTT BLOCK RULES BEGIN ===.*?# === VUONGTT BLOCK RULES END ===\r?\n?'
$restoredHosts = ($currentHosts -replace $unblockPattern, '').TrimEnd() + "`r`n"

$hasOriginalEntries = ($restoredHosts.Contains("127.0.0.1       localhost")) -and
                      ($restoredHosts.Contains("::1             localhost")) -and
                      ($restoredHosts.Contains("192.168.1.100   printer.local"))
$noBlockedDomainsLeft = (-not ($restoredHosts.Contains("facebook.com"))) -and
                        (-not ($restoredHosts.Contains("VUONGTT BLOCK RULES")))

Assert-Check `
    -TestName "4.2 Go chan phai khoi phuc nguyen ven file hosts ban dau, khong sot rule block" `
    -Condition ($hasOriginalEntries -and $noBlockedDomainsLeft) `
    -FailureMessage "File hosts bi mat entry ban dau hoac van con sot marker block sau khi unblock"

# ------------------------------------------------------------------------------
# SECTION 5: Browser Socket Termination & DNS Cache Clearing
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 5: Kiem Tra Cat Socket Trinh Duyet & Lam Sach DNS Cache <<<" -ForegroundColor Yellow

$hasBrowserKill = $sysOpsContent -match "Stop-Process -Name chrome, msedge, brave, opera -Force -ErrorAction SilentlyContinue"
$hasDnsFlush    = $sysOpsContent -match "ipconfig /flushdns"
$hasDnsClient   = $sysOpsContent -match "Clear-DnsClientCache"

Assert-Check `
    -TestName "5.1 system_ops.rs dong tien trinh chrome, msedge, brave, opera khi block" `
    -Condition $hasBrowserKill `
    -FailureMessage "Thieu lenh dung tien trinh cac trinh duyet chu chot de cat socket QUIC/HTTP2"

Assert-Check `
    -TestName "5.2 system_ops.rs chay ipconfig /flushdns" `
    -Condition $hasDnsFlush `
    -FailureMessage "Thieu lenh flushdns"

Assert-Check `
    -TestName "5.3 system_ops.rs chay Clear-DnsClientCache" `
    -Condition $hasDnsClient `
    -FailureMessage "Thieu lenh Clear-DnsClientCache"

# ------------------------------------------------------------------------------
# SUMMARY & VERDICT
# ------------------------------------------------------------------------------
Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "KET QUA KIEM THU CHALLENGER M1: PASS $($script:PassedTests) / TOTAL $($script:TotalTests)" -ForegroundColor Cyan
if ($script:FailedTests -gt 0) {
    Write-Host "SO TESTS THAT BAI: $($script:FailedTests)" -ForegroundColor Red
    foreach ($f in $script:Failures) {
        Write-Host "  - $f" -ForegroundColor Red
    }
}
Write-Host "========================================================================" -ForegroundColor Cyan

if ($script:FailedTests -eq 0) {
    exit 0
} else {
    exit 1
}
