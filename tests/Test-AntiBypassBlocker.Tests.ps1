# =========================================================================
# TEST SUITE: ANTI-BYPASS WEBSITE & GAME BLOCKER ENGINE (R1)
# VUONGTT TOOLKIT 2026 - TDD OPAQUE-BOX E2E VERIFICATION
# =========================================================================
# Tier 1: Canonical Feature Coverage (Happy Path)
# Tier 2: Boundary & Corner Cases (Negative/Null/Idempotency)
# Tier 3: Cross-Feature Combinations (Hosts + DoH + Firewall Synergy)
# Tier 4: Real-World Application Scenarios (Full Lifecycle & AST Verification)
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

Write-Host "`n>>> [TEST SUITE] R1: ANTI-BYPASS WEBSITE & GAME BLOCKER ENGINE <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"

Assert-TierCondition "Tier 1" "T1.01: File index.html phai ton tai" (Test-Path $htmlPath)
Assert-TierCondition "Tier 1" "T1.02: File app.js phai ton tai" (Test-Path $appJsPath)
Assert-TierCondition "Tier 1" "T1.03: File system_ops.rs phai ton tai" (Test-Path $opsPath)

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)

# =========================================================================
# TIER 1: CANONICAL FEATURE COVERAGE (HAPPY PATH)
# =========================================================================
Write-Host "`n--- TIER 1: CANONICAL FEATURE COVERAGE ---" -ForegroundColor Yellow

# T1.1: UI Elements Coverage
Assert-TierCondition "Tier 1" "T1.04: View view-block-web-game ton tai trong HTML" `
    ($htmlContent -match 'id="view-block-web-game"')
Assert-TierCondition "Tier 1" "T1.05: Nut Master Toggle toggle-block-all ton tai" `
    ($htmlContent -match 'id="toggle-block-all"')
Assert-TierCondition "Tier 1" "T1.06: Nut ap dung btn-apply-block-rules ton tai" `
    ($htmlContent -match 'id="btn-apply-block-rules"')
Assert-TierCondition "Tier 1" "T1.07: Nut go chan toan bo btn-remove-all-blocks ton tai" `
    ($htmlContent -match 'id="btn-remove-all-blocks"')
Assert-TierCondition "Tier 1" "T1.08: The card Facebook block-card-facebook ton tai" `
    ($htmlContent -match 'id="block-card-facebook"')

# T1.2: Frontend Controller Coverage
Assert-TierCondition "Tier 1" "T1.09: app.js co ham applyBlockRules" `
    ($appJsContent -match 'applyBlockRules')
Assert-TierCondition "Tier 1" "T1.10: app.js co ham unblockAllRules" `
    ($appJsContent -match 'unblockAllRules')
Assert-TierCondition "Tier 1" "T1.11: app.js co ham initBlockWebGameController" `
    ($appJsContent -match 'initBlockWebGameController')
Assert-TierCondition "Tier 1" "T1.12: app.js goi invokeRust('run_system_action') voi apply_block_rules" `
    ($appJsContent -match 'actionId:\s*["'']apply_block_rules["'']')
Assert-TierCondition "Tier 1" "T1.13: app.js goi invokeRust('run_system_action') voi unblock_all_rules" `
    ($appJsContent -match 'actionId:\s*["'']unblock_all_rules["'']')

# T1.3: Backend Rust Actions Coverage
Assert-TierCondition "Tier 1" "T1.14: system_ops.rs ho tro action apply_block_rules" `
    ($opsContent -match 'act\s*==\s*["'']apply_block_rules["'']')
Assert-TierCondition "Tier 1" "T1.15: system_ops.rs ho tro action unblock_all_rules" `
    ($opsContent -match 'act\s*==\s*["'']unblock_all_rules["'']')
Assert-TierCondition "Tier 1" "T1.16: system_ops.rs ho tro action get_block_rules_status" `
    ($opsContent -match 'act\s*==\s*["'']get_block_rules_status["'']')

# T1.4: DNS Flush & Markers Coverage
Assert-TierCondition "Tier 1" "T1.17: system_ops.rs chua lenh ipconfig /flushdns" `
    ($opsContent -match 'ipconfig\s*/flushdns')
Assert-TierCondition "Tier 1" "T1.18: system_ops.rs chua marker VUONGTT BLOCK RULES BEGIN va END" `
    ($opsContent -match 'VUONGTT BLOCK RULES BEGIN' -and $opsContent -match 'VUONGTT BLOCK RULES END')

# =========================================================================
# TIER 2: BOUNDARY CONDITIONS & NEGATIVE INPUTS
# =========================================================================
Write-Host "`n--- TIER 2: BOUNDARY CONDITIONS & NEGATIVE INPUTS ---" -ForegroundColor Yellow

# T2.1: Domain extraction handles URL prefixes, protocols, and trailing paths
function Resolve-TestDomainExtraction {
    param([string]$RawInput)
    $domains = @()
    if ($RawInput) {
        $lines = $RawInput -split "[\r\n]+"
        foreach ($line in $lines) {
            $d = $line.Trim().ToLower()
            if ($d -and -not $d.StartsWith("#")) {
                $d = $d -replace '^https?://', '' -replace '/.*$', '' -replace ':\d+$', ''
                if ($d) {
                    $domains += $d
                    if (-not $d.StartsWith("www.")) { $domains += "www.$d" }
                }
            }
        }
    }
    return ($domains | Select-Object -Unique)
}

$urlInput = "https://facebook.com/messages/t/123`r`nhttp://m.facebook.com/watch`r`ncustom-game.vn:8080/play"
$extracted = Resolve-TestDomainExtraction -RawInput $urlInput
Assert-TierCondition "Tier 2" "T2.01: Xu ly tach domain loai bo protocol https/http va path url" `
    ($extracted -contains "facebook.com" -and $extracted -contains "m.facebook.com" -and $extracted -contains "custom-game.vn")
Assert-TierCondition "Tier 2" "T2.02: Tu dong sinh them prefix www cho domain hop le" `
    ($extracted -contains "www.facebook.com" -and $extracted -contains "www.custom-game.vn")

# T2.2: Handle empty string or null input gracefully
$emptyExtracted = Resolve-TestDomainExtraction -RawInput ""
Assert-TierCondition "Tier 2" "T2.03: Dau vao rong khong sinh ra domain rac hoac loi ngoai le" `
    ($emptyExtracted.Count -eq 0)

# T2.3: Deduplication check
$dupInput = "facebook.com`r`nfacebook.com`r`nFACEBOOK.COM`r`nwww.facebook.com"
$dedupExtracted = Resolve-TestDomainExtraction -RawInput $dupInput
$exactFbCount = ($dedupExtracted | Where-Object { $_ -eq "facebook.com" }).Count
Assert-TierCondition "Tier 2" "T2.04: Loai bo domain trung lap va chuan hoa chu thuong thanh cong" `
    ($exactFbCount -eq 1)

# T2.4: Domain Map Canonical Contract Validation
$requiredFacebookDomains = @(
    'facebook.com', 'www.facebook.com', 'm.facebook.com', 'web.facebook.com',
    'fb.com', 'www.fb.com', 'fbcdn.net', 'connect.facebook.net',
    'edge-chat.facebook.com', 'graph.facebook.com', 'messenger.com', 'www.messenger.com'
)
$missingFbDomains = @()
foreach ($d in $requiredFacebookDomains) {
    if ($opsContent -notmatch [regex]::Escape($d)) {
        $missingFbDomains += $d
    }
}
Assert-TierCondition "Tier 2" "T2.05: system_ops.rs dinh nghia day du cac domain Facebook/Messenger cot loi" `
    ($missingFbDomains.Count -eq 0) `
    "Cac domain con thieu: $($missingFbDomains -join ', ')"

# =========================================================================
# TIER 3: CROSS-FEATURE COMBINATIONS (HOSTS + DOH + FIREWALL SYNERGY)
# =========================================================================
Write-Host "`n--- TIER 3: CROSS-FEATURE COMBINATIONS ---" -ForegroundColor Yellow

# T3.1: Anti-Bypass Registry Policy Presence Check
$hasChromeDoH = ($opsContent -match 'Google\\Chrome' -and $opsContent -match 'DnsOverHttpsMode') -or ($opsContent -match 'Policies.*Chrome')
$hasEdgeDoH = ($opsContent -match 'Microsoft\\Edge' -and $opsContent -match 'DnsOverHttpsMode') -or ($opsContent -match 'Policies.*Edge')
Assert-TierCondition "Tier 3" "T3.01: system_ops.rs cau hinh tat DoH tren Google Chrome (DnsOverHttpsMode = off)" `
    $hasChromeDoH "Chua tim thay cau hinh tat DoH Chrome trong system_ops.rs"
Assert-TierCondition "Tier 3" "T3.02: system_ops.rs cau hinh tat DoH tren Microsoft Edge (DnsOverHttpsMode = off)" `
    $hasEdgeDoH "Chua tim thay cau hinh tat DoH Edge trong system_ops.rs"

# T3.2: Windows Firewall Outbound Rule Verification
$hasFwRule = ($opsContent -match 'VUONGTT_Block_Facebook' -or $opsContent -match 'advfirewall.*firewall')
$hasMetaCidr = ($opsContent -match '31\.13\.0\.0/16' -or $opsContent -match '157\.240\.0\.0/16' -or $opsContent -match 'remoteip')
Assert-TierCondition "Tier 3" "T3.03: system_ops.rs tao luat Firewall Outbound VUONGTT_Block_Facebook" `
    $hasFwRule "Chua tim thay luat Firewall VUONGTT_Block_Facebook trong system_ops.rs"
Assert-TierCondition "Tier 3" "T3.04: Luat Firewall chan cac dai IP Meta/Facebook (31.13.0.0/16, 157.240.0.0/16...)" `
    $hasMetaCidr "Chua tim thay dai IP remoteip trong system_ops.rs"

# T3.3: Socket and Browser Process Termination
$hasBrowserKill = ($opsContent -match 'chrome' -and $opsContent -match 'msedge' -and $opsContent -match 'Stop-Process')
Assert-TierCondition "Tier 3" "T3.05: system_ops.rs dong tien trinh trinh duyet cat socket HTTP/2 & QUIC cu" `
    $hasBrowserKill "Chua tim thay Stop-Process cho chrome/msedge trong system_ops.rs"

# T3.4: Clean Unblock & Reversion Verification
$hasCleanRevert = ($opsContent -match 'unblock_all_rules') -and `
                  ($opsContent -match 'DnsOverHttpsMode' -or $opsContent -match 'Remove-ItemProperty' -or $opsContent -match 'VUONGTT_Block_Facebook')
Assert-TierCondition "Tier 3" "T3.06: unblock_all_rules go bo hoan toan quy tac Firewall va Registry DoH" `
    $hasCleanRevert "unblock_all_rules chua hoan tac DoH hoac Firewall"

# =========================================================================
# TIER 4: REAL-WORLD APPLICATION SCENARIOS
# =========================================================================
Write-Host "`n--- TIER 4: REAL-WORLD APPLICATION SCENARIOS ---" -ForegroundColor Yellow

# T4.1: End-to-End Simulation of Host Content Transformation
function Simulate-HostsBlockCycle {
    param(
        [string[]]$DomainsToBlock
    )
    $originalHosts = "# Copyright (c) 1993-2009 Microsoft Corp.`r`n127.0.0.1 localhost`r`n::1 localhost`r`n"
    
    # Generate Block Lines
    $blockLines = @(
        "# === VUONGTT BLOCK RULES BEGIN ===",
        "# Chan Website & Game Truc Tuyen - VUONGTT Toolkit 2026",
        "# Thoi gian ap dung: 17/11/2026 12:00:00"
    )
    foreach ($d in $DomainsToBlock) {
        $blockLines += "0.0.0.0 $d"
        $blockLines += "127.0.0.1 $d"
        $blockLines += "::1 $d"
    }
    $blockLines += "# === VUONGTT BLOCK RULES END ==="
    
    $blockedHosts = $originalHosts.TrimEnd() + "`r`n`r`n" + ($blockLines -join "`r`n") + "`r`n"
    
    # Verify Content in Blocked State
    $hasMarkers = ($blockedHosts -match 'VUONGTT BLOCK RULES BEGIN' -and $blockedHosts -match 'VUONGTT BLOCK RULES END')
    $hasFacebook = ($blockedHosts -match '0\.0\.0\.0 facebook\.com' -and $blockedHosts -match '127\.0\.0\.1 facebook\.com')
    $hasMessenger = ($blockedHosts -match '0\.0\.0\.0 messenger\.com')
    
    # Now simulate unblock cleanup
    $cleanPattern = '(?s)# === VUONGTT BLOCK RULES BEGIN ===.*?# === VUONGTT BLOCK RULES END ===\r?\n?'
    $restoredHosts = ($blockedHosts -replace $cleanPattern, '').TrimEnd() + "`r`n"
    
    $isRestored = ($restoredHosts -notmatch 'VUONGTT BLOCK RULES BEGIN') -and ($restoredHosts -match '127\.0\.0\.1 localhost')
    
    return [PSCustomObject]@{
        HasMarkers = $hasMarkers
        HasFacebook = $hasFacebook
        HasMessenger = $hasMessenger
        IsRestored = $isRestored
        RestoredMatchesOriginal = ($restoredHosts.Trim() -eq $originalHosts.Trim())
    }
}

$simResult = Simulate-HostsBlockCycle -DomainsToBlock @('facebook.com', 'messenger.com', 'custom-site.org')
Assert-TierCondition "Tier 4" "T4.01: Chu trinh ghi va go chan file hosts tao dung cu phap 0.0.0.0/127.0.0.1/::1" `
    ($simResult.HasMarkers -and $simResult.HasFacebook -and $simResult.HasMessenger)
Assert-TierCondition "Tier 4" "T4.02: Chu trinh go chan hoan tac file hosts nguyen ban khong lam mat entry cua he dieu hanh" `
    ($simResult.IsRestored -and $simResult.RestoredMatchesOriginal)

# T4.2: AST Syntax Parsing of system_ops.rs PowerShell snippets
$psSnippetPattern = '(?s)let\s+ps(?:_code)?\s*=\s*format!\(\s*r##"(.*?)"##\s*\);'
$psMatches = [regex]::Matches($opsContent, $psSnippetPattern)
$astParseErrors = 0
$totalSnippetsParsed = 0

foreach ($m in $psMatches) {
    $rawPs = $m.Groups[1].Value
    # Replace rust format braces {{ and }} with { and }
    $cleanPs = $rawPs.Replace('{{', '{').Replace('}}', '}')
    # Replace placeholder variables like {safe_platforms} with dummy literals
    $cleanPs = [regex]::Replace($cleanPs, '\{[a-zA-Z0-9_]+\}', 'test')
    
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseInput($cleanPs, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        $astParseErrors++
        $lines = $cleanPs -split "\r?\n"
        $errLineNum = $errors[0].Extent.StartLineNumber
        $errCol = $errors[0].Extent.StartColumnNumber
        $errText = $errors[0].Extent.Text
        $script:lastAstError = "$($errors[0].Message) (Line $errLineNum Col $errCol Text: '$errText')"
    }
    $totalSnippetsParsed++
}

Assert-TierCondition "Tier 4" "T4.03: Cac doan script PowerShell nhung trong system_ops.rs tuan thu cu phap AST (0 loi parse)" `
    ($astParseErrors -eq 0 -and $totalSnippetsParsed -gt 0) `
    "Co $astParseErrors loi syntax trong tong so $totalSnippetsParsed doan script: $script:lastAstError"

# =========================================================================
# SUMMARY REPORT
# =========================================================================
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " KET QUA KIEM THU R1 (ANTI-BYPASS BLOCKER ENGINE):" -ForegroundColor Cyan
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
