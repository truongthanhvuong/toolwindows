# =========================================================================
# TDD TEST SUITE: DEEPAUDIT, GITHUB AUTO-UPDATER & ZALO DATA FIXES
# tests/Test-DeepAuditAndZaloFixes.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$mainRs = Join-Path $repoRoot "src-tauri\src\main.rs"
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"
$appJs = Join-Path $repoRoot "src-ui\app.js"
$indexHtml = Join-Path $repoRoot "src-ui\index.html"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: DEEPAUDIT, GITHUB UPDATER & ZALO FIXES              " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "======================================================================" -ForegroundColor Cyan

$passedCount = 0
$failedCount = 0

function Assert-Test([string]$desc, [scriptblock]$condition) {
    try {
        $result = & $condition
        if ($result) {
            Write-Host " [PASS] $desc" -ForegroundColor Green
            $script:passedCount++
        } else {
            Write-Host " [FAIL] $desc" -ForegroundColor Red
            $script:failedCount++
        }
    } catch {
        Write-Host " [FAIL] $desc - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failedCount++
    }
}

$opsContent = Get-Content -Path $opsRs -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $indexHtml -Raw -Encoding UTF8
$mainContent = Get-Content -Path $mainRs -Raw -Encoding UTF8

# 1. Kiem tra view-zalo-data nam ben trong the <main>
Assert-Test "view-zalo-data phai nam hoan toan ben trong the <main> de khong bi vo layout" {
    $mainStart = $htmlContent.IndexOf('<main')
    $mainEnd = $htmlContent.IndexOf('</main>')
    $zaloPos = $htmlContent.IndexOf('id="view-zalo-data"')
    $zaloPos -gt $mainStart -and $zaloPos -lt $mainEnd
}

# 2. Kiem tra index.html khong co duplicate ID nao gay xung dot DOM
Assert-Test "index.html khong co bat ky duplicate DOM ID nao (dac biet la zalo-path-input va input-license-key)" {
    $idMatches = [regex]::Matches($htmlContent, 'id="([^"]+)"')
    $counts = @{}
    foreach ($m in $idMatches) {
        $id = $m.Groups[1].Value
        if ($counts.ContainsKey($id)) { $counts[$id]++ } else { $counts[$id] = 1 }
    }
    $dups = $counts.GetEnumerator() | Where-Object { $_.Value -gt 1 }
    $dups.Count -eq 0
}

# 3. Kiem tra view-it-helpdesk co card / link don dep Zalo Data
Assert-Test "view-it-helpdesk phai tich hop card Zalo Data Cleanup de khop voi menu sidebar" {
    $itStart = $htmlContent.IndexOf('id="view-it-helpdesk"')
    $itEnd = $htmlContent.IndexOf('id="view-vpn-proxy"')
    $itBlock = $htmlContent.Substring($itStart, $itEnd - $itStart)
    $itBlock -match 'Zalo' -and ($itBlock -match 'zaloClearCache' -or $itBlock -match 'view-zalo-data')
}

# 4. Kiem tra apply_update trong system_ops.rs khong chua loi cu phap PowerShell here-string
Assert-Test "apply_update powershell here-string khong duoc chua `\$i hoac `\$_. vi bi parse thanh \. gay loi" {
    $opsContent -notmatch '\$updateScript\s*=\s*@"[\s\S]*?\\\$i' -and
    $opsContent -notmatch '\$updateScript\s*=\s*@"[\s\S]*?\\\$_\.'
}

# 5. Kiem tra zalo_scan_all khong double count cache subdirs
Assert-Test "zalo_scan_all phai loai tru trung lap thu muc cache khong phan biet hoa thuong" {
    $opsContent -notmatch "'Cache',\s*'cache'"
}

# 6. Kiem tra main.rs route_ipc_request cho zalo_delete duoc trim va parse so nguyen an toan
Assert-Test "zalo_delete IPC response phai duoc trim tranh trailing newline gay loi JSON parse" {
    $mainContent -match 'deleted\.trim\(\)' -or $mainContent -match 'parse::<i64>'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
