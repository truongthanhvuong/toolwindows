# =========================================================================
# TDD TEST SUITE: WIN DEPLOY EXECUTION & UNFREEZE BUTTON FIX
# tests/Test-WinDeployExecutionFix.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"
$appJs = Join-Path $repoRoot "src-ui\app.js"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN DEPLOY SETUP EXECUTION & UNFREEZE FIX          " -ForegroundColor Yellow -BackgroundColor Black
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

$opsContent = if (Test-Path $opsRs) { Get-Content -Path $opsRs -Raw -Encoding UTF8 } else { "" }
$appJsContent = if (Test-Path $appJs) { Get-Content -Path $appJs -Raw -Encoding UTF8 } else { "" }

# 1. system_ops.rs phai su dung cmd /c start hoac shell wrapper de khoi chay setup.exe (chong loi The request is not supported)
Assert-Test "system_ops.rs phai khoi chay setup.exe qua cmd /c start de chong loi The request is not supported" {
    $opsContent -match 'cmd\.exe.*start.*setup\.exe' -or $opsContent -match '/c start.*setup\.exe'
}

# 2. system_ops.rs phai kiem tra loi thuc thi bang .output() va ghi log thay vi .spawn() khong kiem soat
Assert-Test "system_ops.rs phai bat loi thuc thi setup.exe thay vi spawn khong kiem soat" {
    $opsContent -match 'run_cmd\.output\(\)' -or $opsContent -match 'ERR_LAUNCH'
}

# 3. system_ops.rs che do custom khong duoc truyen /compat ignorewarning khi khong co /auto
Assert-Test "system_ops.rs che do custom phai loai bo /compat ignorewarning de tranh loi cu phap" {
    $opsContent -notmatch 'format!\("/DynamicUpdate disable /compat ignorewarning /tempdrive'
}

# 4. app.js phai co co che tu dong mo khoa btn-start-deploy sau khi khoi chay thanh cong
Assert-Test "app.js phai tu dong mo khoa btn-start-deploy sau khi kich hoat thanh cong" {
    $appJsContent -match 'ĐÃ KÍCH HOẠT THÀNH CÔNG' -and $appJsContent -match 'resetDeployButton|unfreezeDeployButton|btn\.disabled\s*=\s*false;\s*btn\.innerHTML\s*='
}

# 5. app.js selectDeployMode phai mo khoa btn-start-deploy khi nguoi dung chuyen doi che do cai
Assert-Test "app.js selectDeployMode phai khoi phuc nut btn-start-deploy khi chuyen che do" {
    $appJsContent -match 'function selectDeployMode' -and ($appJsContent -match 'btn-start-deploy' -and $appJsContent -match 'btnDeploy\.disabled\s*=\s*false')
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
