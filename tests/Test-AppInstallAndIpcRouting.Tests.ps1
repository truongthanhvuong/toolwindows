# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ IPC ROUTING, CÀI ĐẶT ỨNG DỤNG & SUB-TABS SOFTWARE HUB
# ==============================================================================

$testsPassed = 0
$testsFailed = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
        $script:testsFailed++
    }
}

Write-Host ">>> KIEM THU IPC ROUTING CAI DAT PHAN MEM & SUB-TABS SOFTWARE HUB <<<" -ForegroundColor Cyan

$mainRsPath = Join-Path $PSScriptRoot "..\src-tauri\src\main.rs"
$sysOpsRsPath = Join-Path $PSScriptRoot "..\src-tauri\src\system_ops.rs"
$indexHtmlPath = Join-Path $PSScriptRoot "..\src-ui\index.html"
$appJsPath = Join-Path $PSScriptRoot "..\src-ui\app.js"

$mainRs = [System.IO.File]::ReadAllText($mainRsPath, [System.Text.Encoding]::UTF8)
$sysOpsRs = [System.IO.File]::ReadAllText($sysOpsRsPath, [System.Text.Encoding]::UTF8)
$indexHtml = [System.IO.File]::ReadAllText($indexHtmlPath, [System.Text.Encoding]::UTF8)
$appJs = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)

# --- Test 1: IPC Routing in main.rs ---
Write-Host "`n--- Nhom 1: IPC Routing trong main.rs ---"
Assert-Condition -TestName "main.rs phai co routing cho install_apps" `
    -Condition ($mainRs -match 'body\.contains\("install_apps"\)') `
    -Message "main.rs chua bat command install_apps dan den lenh cai dat bi bo qua"

Assert-Condition -TestName "main.rs phai co routing cho get_install_logs" `
    -Condition ($mainRs -match 'body\.contains\("get_install_logs"\)') `
    -Message "main.rs chua bat command get_install_logs khien terminal khong nhan log"

Assert-Condition -TestName "main.rs phai co routing cho clear_install_logs" `
    -Condition ($mainRs -match 'body\.contains\("clear_install_logs"\)') `
    -Message "main.rs chua bat command clear_install_logs"

# --- Test 2: Support for Tor Browser and extended apps in system_ops.rs ---
Write-Host "`n--- Nhom 2: Ho tro goi cai dat Tor Browser & mo rong trong system_ops.rs ---"
Assert-Condition -TestName "system_ops.rs phai ho tro app_id tor hoac tor-browser" `
    -Condition ($sysOpsRs -match '"tor"' -or $sysOpsRs -match '"tor-browser"') `
    -Message "system_ops.rs thieu mapping cho tor browser"

# --- Test 3: Sub-tabs Navigation in Software Hub ---
Write-Host "`n--- Nhom 3: Dieu huong 4 Sub-tabs trong Software Hub ---"
Assert-Condition -TestName "index.html phai co tab chuyen Cai App Tuy Chinh co id hoac onclick" `
    -Condition ($indexHtml -match 'id="tab-soft-custom"' -or $indexHtml -match 'switchSoftSubTab\(''custom''\)') `
    -Message "Subtab Cai App Tuy Chinh chi la nut tinh khong co id hoac su kien"

Assert-Condition -TestName "index.html phai co tab chuyen Go Bo Sach co id hoac onclick" `
    -Condition ($indexHtml -match 'id="tab-soft-uninstall"' -or $indexHtml -match 'switchSoftSubTab\(''uninstall''\)') `
    -Message "Subtab Go Bo Sach chi la nut tinh khong co id hoac su kien"

Assert-Condition -TestName "index.html phai co tab chuyen Cai Font Chu co id hoac onclick" `
    -Condition ($indexHtml -match 'id="tab-soft-fonts"' -or $indexHtml -match 'switchSoftSubTab\(''fonts''\)') `
    -Message "Subtab Cai Font Chu chi la nut tinh khong co id hoac su kien"

# --- Test 4: Sub-views exist in index.html ---
Write-Host "`n--- Nhom 4: Cac sub-view noi dung tuong ung ton tai ---"
Assert-Condition -TestName "Phai co sub-view cho Cai App Tuy Chinh" `
    -Condition ($indexHtml -match 'id="subview-soft-custom"') `
    -Message "Thieu section hoac div id=subview-soft-custom"

Assert-Condition -TestName "Phai co sub-view cho Go Bo Sach" `
    -Condition ($indexHtml -match 'id="subview-soft-uninstall"') `
    -Message "Thieu section hoac div id=subview-soft-uninstall"

Assert-Condition -TestName "Phai co sub-view cho Cai Font Chu" `
    -Condition ($indexHtml -match 'id="subview-soft-fonts"') `
    -Message "Thieu section hoac div id=subview-soft-fonts"

$total = $testsPassed + $testsFailed
Write-Host "`n=========================================================="
Write-Host "KET QUA: $testsPassed PASS / $total TOTAL"
Write-Host "=========================================================="

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
