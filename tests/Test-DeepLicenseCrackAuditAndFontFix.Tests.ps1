# =========================================================================
# TDD TEST SUITE: DEEP LICENSE CRACK AUDIT & FONT ENCODING FIX
# tests/Test-DeepLicenseCrackAuditAndFontFix.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"
$indexHtml = Join-Path $repoRoot "src-ui\index.html"
$appJs = Join-Path $repoRoot "src-ui\app.js"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: DEEP LICENSE CRACK AUDIT & FONT ENCODING FIX       " -ForegroundColor Yellow -BackgroundColor Black
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
$htmlContent = if (Test-Path $indexHtml) { Get-Content -Path $indexHtml -Raw -Encoding UTF8 } else { "" }
$jsContent = if (Test-Path $appJs) { Get-Content -Path $appJs -Raw -Encoding UTF8 } else { "" }

# 1. detect_bios_license va run_ps_oneshot phai thiet lap UTF-8 OutputEncoding chong loi font dau hoi ?
Assert-Test "1. Backend Rust bat buoc thiet lap UTF-8 Console OutputEncoding chong vo font tieng Viet" {
    $opsContent -match '(?s)detect_bios_license.*\[Console\]::OutputEncoding' -and
    $opsContent -match '(?s)run_ps_oneshot.*\[Console\]::OutputEncoding'
}

# 2. system_ops.rs phai dang ky hanh dong deep_license_crack_audit
Assert-Test "2. Dang ky IPC action deep_license_crack_audit trong system_ops.rs" {
    $opsContent -match 'deep_license_crack_audit' -or $opsContent -match 'audit_license_and_cracks'
}

# 3. Backend phai quet va phat hien cac phuong thuc crack: KMS Localhost, Ohook DLL, Hosts block, SppExtComObjHook
Assert-Test "3. Backend quet day du cac phuong thuc crack: KMS 127.0.0.1, Ohook sppc.dll, Hosts Adobe, IDM reset" {
    $opsContent -match 'sppc\.dll' -and
    $opsContent -match '127\.0\.0\.1' -and
    $opsContent -match 'SoftwareLicensingProduct'
}

# 4. index.html phai chua giao dien Kiem tra phan mem crack chuan Hinh 2 trong view-hwid-act
Assert-Test "4. Giao dien view-hwid-act chua bang dieu khien Kiem tra phan mem crack chuan Hinh 2" {
    $htmlContent -match 'Kiểm tra phần mềm crack' -and
    $htmlContent -match 'Quét nhanh' -and
    $htmlContent -match 'Quét toàn diện' -and
    $htmlContent -match 'Dấu hiệu crack' -and
    $htmlContent -match 'Phần mềm trả phí'
}

# 5. app.js phai co ham runDeepLicenseCrackAudit va exportReportHtml
Assert-Test "5. Frontend app.js co day du ham kich hoat quet va render bang kiem tra crack" {
    $jsContent -match 'runDeepLicenseCrackAudit' -and
    $jsContent -match 'deep_license_crack_audit'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
