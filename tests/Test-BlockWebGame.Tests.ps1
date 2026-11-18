# =========================================================================
# TEST SUITE: KIEM THU PHAN HE CHAN WEBSITE & GAME TRUC TUYEN (PARENTAL CONTROL)
# VUONGTT TOOLKIT 2026 - TDD ENGINE
# =========================================================================

$ErrorActionPreference = "Stop"

$script:passed = 0
$script:failed = 0

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $script:failed++
        throw "TEST FAILED: $message"
    } else {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:passed++
    }
}

Write-Host "`n>>> KIEM THU TDD: PHAN HE CHAN WEBSITE & GAME TRUC TUYEN <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"

Assert-True (Test-Path $htmlPath) "Tep index.html phai ton tai"
Assert-True (Test-Path $appJsPath) "Tep app.js phai ton tai"
Assert-True (Test-Path $opsPath) "Tep system_ops.rs phai ton tai"

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)

Write-Host "--- Nhom 1: Kiem Tra Giao Dien UI Chan Web & Game (index.html) ---" -ForegroundColor Yellow

Assert-True ($htmlContent -match 'data-target="view-block-web-game"') "Sidebar phai co nut menu data-target='view-block-web-game'"
Assert-True ($htmlContent -match 'id="view-block-web-game"') "View view-block-web-game phai ton tai trong index.html"
Assert-True ($htmlContent -match 'id="toggle-block-all"') "Toggle switch chan tat ca id='toggle-block-all' phai ton tai"
Assert-True ($htmlContent -match 'id="count-selected-blocks"') "Badge dem so nen tang id='count-selected-blocks' phai ton tai"
Assert-True ($htmlContent -match 'id="count-total-blocks"') "Badge tong so nen tang id='count-total-blocks' phai ton tai"
Assert-True ($htmlContent -match 'id="btn-uncheck-all-blocks"') "Nut bo chon het id='btn-uncheck-all-blocks' phai ton tai"
Assert-True ($htmlContent -match 'id="btn-remove-all-blocks"') "Nut go chan toan bo id='btn-remove-all-blocks' phai ton tai"
Assert-True ($htmlContent -match 'id="btn-apply-block-rules"') "Nut luu va ap dung id='btn-apply-block-rules' phai ton tai"
Assert-True ($htmlContent -match 'id="block-save-status"') "Badge trang thai luu id='block-save-status' phai ton tai"

# Kiem tra 13 the nen tang
$platforms = @('facebook', 'tiktok', 'youtube', 'instagram', 'threads', 'twitter', 'linkedin', 'telegram', 'discord', 'roblox', 'garena', 'steam', 'riot')
foreach ($p in $platforms) {
    Assert-True ($htmlContent -match "id=`"block-card-$p`"") "The nen tang block-card-$p phai ton tai"
    Assert-True ($htmlContent -match "id=`"block-cb-$p`"") "Checkbox block-cb-$p phai ton tai"
}

Assert-True ($htmlContent -match 'id="input-custom-blocked-domains"') "Textarea nhap website khac id='input-custom-blocked-domains' phai ton tai"

Write-Host "`n--- Nhom 2: Kiem Tra Controller Frontend (app.js) ---" -ForegroundColor Yellow

Assert-True ($appJsContent -match 'initBlockWebGameController') "app.js phai co ham initBlockWebGameController"
Assert-True ($appJsContent -match 'toggleBlockCard') "app.js phai co ham toggleBlockCard"
Assert-True ($appJsContent -match 'toggleSelectAllBlocks') "app.js phai co ham toggleSelectAllBlocks"
Assert-True ($appJsContent -match 'toggleCategoryBlocks') "app.js phai co ham toggleCategoryBlocks"
Assert-True ($appJsContent -match 'applyBlockRules') "app.js phai co ham applyBlockRules"
Assert-True ($appJsContent -match 'unblockAllRules') "app.js phai co ham unblockAllRules"
Assert-True ($appJsContent -match 'initBlockWebGameController\(\);') "DOMContentLoaded phai goi initBlockWebGameController()"
Assert-True ($appJsContent -match 'view-block-web-game') "subTabRouteMap hoac navigation phai ho tro view-block-web-game"

Write-Host "`n--- Nhom 3: Kiem Tra Backend Rust (system_ops.rs) ---" -ForegroundColor Yellow

Assert-True ($opsContent -match 'get_block_rules_status') "system_ops.rs phai ho tro action 'get_block_rules_status'"
Assert-True ($opsContent -match 'apply_block_rules') "system_ops.rs phai ho tro action 'apply_block_rules'"
Assert-True ($opsContent -match 'unblock_all_rules') "system_ops.rs phai ho tro action 'unblock_all_rules'"
Assert-True ($opsContent -match 'VUONGTT BLOCK RULES BEGIN') "system_ops.rs phai co marker hosts VUONGTT BLOCK RULES BEGIN"
Assert-True ($opsContent -match 'facebook\.com') "system_ops.rs phai dinh nghia domain facebook.com"
Assert-True ($opsContent -match 'tiktok\.com') "system_ops.rs phai dinh nghia domain tiktok.com"
Assert-True ($opsContent -match 'youtube\.com') "system_ops.rs phai dinh nghia domain youtube.com"
Assert-True ($opsContent -match 'roblox\.com') "system_ops.rs phai dinh nghia domain roblox.com"
Assert-True ($opsContent -match 'garena\.vn') "system_ops.rs phai dinh nghia domain garena.vn"

Write-Host "`n--- Nhom 4: Kiem Tra Anti-Bypass Blocker Engine (DNS-over-HTTPS & Firewall) ---" -ForegroundColor Yellow

# Kiem tra tat ca 17+ ten mien Facebook mo rong
$expectedFbDomains = @(
    'facebook.com', 'www.facebook.com', 'm.facebook.com', 'web.facebook.com',
    'fb.com', 'www.fb.com', 'fbcdn.net', 'www.fbcdn.net',
    'static.xx.fbcdn.net', 'scontent.xx.fbcdn.net', 'scontent.fbcdn.net', 'external.xx.fbcdn.net',
    'connect.facebook.net', 'edge-chat.facebook.com', 'graph.facebook.com',
    'messenger.com', 'www.messenger.com', 'm.messenger.com'
)
foreach ($dom in $expectedFbDomains) {
    $escapedDom = [regex]::Escape($dom)
    Assert-True ($opsContent -match $escapedDom) "system_ops.rs phai bao gom ten mien mo rong '$dom'"
}

# Kiem tra cau hinh Registry vo hieu hoa DoH tren Chrome va Edge
Assert-True ($opsContent -match 'SOFTWARE\\Policies\\Google\\Chrome') "system_ops.rs phai cau hinh policy Chrome"
Assert-True ($opsContent -match 'SOFTWARE\\Policies\\Microsoft\\Edge') "system_ops.rs phai cau hinh policy Edge"
Assert-True ($opsContent -match 'DnsOverHttpsMode') "system_ops.rs phai thiet lap thuoc tinh DnsOverHttpsMode"
Assert-True ($opsContent -match "DnsOverHttpsMode.*'off'") "system_ops.rs phai dat DnsOverHttpsMode = 'off'"
Assert-True ($opsContent -match "New-Item.*-Force") "system_ops.rs phai tu dong tao parent key cho policies"

# Kiem tra cau hinh Windows Firewall chan Meta IP subnets
Assert-True ($opsContent -match 'VUONGTT_Block_Facebook') "system_ops.rs phai tao firewall rule 'VUONGTT_Block_Facebook'"
Assert-True ($opsContent -match '31\.13\.0\.0/16') "Firewall rule phai chan dai IP 31.13.0.0/16"
Assert-True ($opsContent -match '157\.240\.0\.0/16') "Firewall rule phai chan dai IP 157.240.0.0/16"
Assert-True ($opsContent -match '129\.134\.0\.0/16') "Firewall rule phai chan dai IP 129.134.0.0/16"
Assert-True ($opsContent -match '185\.60\.216\.0/22') "Firewall rule phai chan dai IP 185.60.216.0/22"
Assert-True ($opsContent -match '57\.144\.0\.0/14') "Firewall rule phai chan dai IP 57.144.0.0/14"

# Kiem tra cat socket va don dep tien trinh trinh duyet
Assert-True ($opsContent -match 'Stop-Process.*chrome' -and $opsContent -match 'msedge') "system_ops.rs phai dong tien trinh trinh duyet chrome va msedge"
Assert-True ($opsContent -match 'ipconfig /flushdns') "system_ops.rs phai flush DNS cache"
Assert-True ($opsContent -match 'Clear-DnsClientCache') "system_ops.rs phai xoa cache DnsClient"

# Kiem tra quy trinh hoan tac unblock_all_rules
Assert-True ($opsContent -match 'Remove-ItemProperty.*DnsOverHttpsMode') "unblock_all_rules phai xoa bo thuoc tinh DnsOverHttpsMode"
Assert-True ($opsContent -match 'netsh advfirewall firewall delete rule name="VUONGTT_Block_Facebook"') "unblock_all_rules phai xoa rule firewall VUONGTT_Block_Facebook"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "KET QUA KIEM THU: PASS $script:passed / TOTAL $($script:passed + $script:failed)" -ForegroundColor Green
Write-Host "=======================================================`n" -ForegroundColor Cyan
