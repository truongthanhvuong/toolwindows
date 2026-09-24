# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ ĐỔI TÊN MÁY TÍNH VỚI DOMAIN CREDENTIAL & CHUẨN WINDOWS
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

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST ĐỔI TÊN MÁY VỚI CREDENTIAL & WINDOWS NATIVE <<<" -ForegroundColor Cyan

$customizerPath = Join-Path $PSScriptRoot "..\src\Core\SystemCustomizer.ps1"
$mainScriptPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"

$customizerContent = [System.IO.File]::ReadAllText($customizerPath, [System.Text.Encoding]::UTF8)
$mainContent       = [System.IO.File]::ReadAllText($mainScriptPath, [System.Text.Encoding]::UTF8)

# ------------------------------------------------------------------------------
# 1. KIỂM THỬ HÀM Invoke-VUONGTTRenameComputer TRONG SystemCustomizer.ps1
# ------------------------------------------------------------------------------
$renameFuncMatch = [regex]::Match($customizerContent, 'function\s+Invoke-VUONGTTRenameComputer\s*\{(?s)(.+?)\nfunction\s+')
$renameFuncBody = if ($renameFuncMatch.Success) { $renameFuncMatch.Groups[1].Value } else { "" }

Assert-Condition -TestName "1.1: Hàm Invoke-VUONGTTRenameComputer phải tồn tại" `
    -Condition ($renameFuncBody -ne "") `
    -Message "Không tìm thấy hàm Invoke-VUONGTTRenameComputer"

# Phải có tham số nhận DomainUser / DomainPassword hoặc Credential
$hasCredentialParams = ($renameFuncBody -match '\$DomainUser' -and $renameFuncBody -match '\$DomainPassword')
Assert-Condition -TestName "1.2: Invoke-VUONGTTRenameComputer phải hỗ trợ tham số DomainUser và DomainPassword" `
    -Condition ($hasCredentialParams) `
    -Message "Hàm chưa nhận tham số tài khoản/mật khẩu quản trị để đổi tên máy thuộc Domain"

# Phải có tham số nhận đối tượng PSCredential hoặc PromptCredential
$hasPsCredParam = ($renameFuncBody -match 'PSCredential' -or $renameFuncBody -match '\$Credential')
Assert-Condition -TestName "1.3: Invoke-VUONGTTRenameComputer phải hỗ trợ tham số Credential" `
    -Condition ($hasPsCredParam) `
    -Message "Hàm chưa hỗ trợ truyền đối tượng PSCredential"

# Phải gọi Rename-Computer kèm -DomainCredential khi có tài khoản
$hasDomainCredCall = ($renameFuncBody -match 'Rename-Computer[\s\S]+?-DomainCredential')
Assert-Condition -TestName "1.4: Phải gọi Rename-Computer với tham số -DomainCredential" `
    -Condition ($hasDomainCredCall) `
    -Message "Chưa truyền -DomainCredential vào Rename-Computer khiến Domain từ chối đổi tên máy"

# Phải có xử lý bắt lỗi xác thực và gợi ý mở Hộp Thoại Windows
$hasAuthCatchHelp = ($renameFuncBody -match 'SystemPropertiesComputerName' -or $renameFuncBody -match 'sysdm\.cpl' -or $renameFuncBody -match 'Hộp Thoại Windows')
Assert-Condition -TestName "1.5: Phải có hướng dẫn hoặc gợi ý mở Hộp Thoại Windows khi lỗi xác thực" `
    -Condition ($hasAuthCatchHelp) `
    -Message "Chưa có gợi ý giải pháp Hộp Thoại Windows khi gặp lỗi The user name or password is incorrect"

# ------------------------------------------------------------------------------
# 2. KIỂM THỬ SỰ KIỆN btnRenameComputerDirect TRONG VUONGTT_Toolkit.ps1
# ------------------------------------------------------------------------------
$renameBtnMatch = [regex]::Match($mainContent, '\$btnRenameComputerDirect\.Add_Click\(\{(?s)(.+?)\}\s*\)')
$renameBtnBody = if ($renameBtnMatch.Success) { $renameBtnMatch.Groups[1].Value } else { "" }

Assert-Condition -TestName "2.1: Sự kiện btnRenameComputerDirect phải tồn tại" `
    -Condition ($renameBtnBody -ne "") `
    -Message "Không tìm thấy sự kiện click của btnRenameComputerDirect"

# Phải đọc tài khoản $txtDomainUser và mật khẩu $pwdDomainPass từ form
$readsDomainInput = ($renameBtnBody -match '\$txtDomainUser' -and $renameBtnBody -match '\$pwdDomainPass')
Assert-Condition -TestName "2.2: btnRenameComputerDirect phải đọc tài khoản và mật khẩu từ form" `
    -Condition ($readsDomainInput) `
    -Message "Nút Đổi Tên Máy chưa lấy thông tin tài khoản mà người dùng đã nhập trên form"

# Phải kiểm tra máy thuộc Domain hoặc hỗ trợ prompt Get-Credential như Windows
$hasDomainPromptOrCred = ($renameBtnBody -match 'Get-Credential' -or $renameBtnBody -match 'PartOfDomain' -or $renameBtnBody -match 'Open-VUONGTTSystemPropertiesComputerNameDialog')
Assert-Condition -TestName "2.3: Phải hỗ trợ cơ chế nhập tài khoản giống Windows (Get-Credential / Hộp thoại Windows)" `
    -Condition ($hasDomainPromptOrCred) `
    -Message "Chưa có cơ chế hỏi tài khoản chuẩn Windows khi đổi tên máy thuộc Domain"

# ------------------------------------------------------------------------------
# 3. KIỂM THỬ CÚ PHÁP AST HỢP LỆ
# ------------------------------------------------------------------------------
$tokens = $null
$err1 = $null
$ast1 = [System.Management.Automation.Language.Parser]::ParseFile($customizerPath, [ref]$tokens, [ref]$err1)

$err2 = $null
$ast2 = [System.Management.Automation.Language.Parser]::ParseFile($mainScriptPath, [ref]$tokens, [ref]$err2)

Assert-Condition -TestName "3.1: Cú pháp AST của SystemCustomizer.ps1 và VUONGTT_Toolkit.ps1 hợp lệ" `
    -Condition (($err1.Count -eq 0) -and ($err2.Count -eq 0)) `
    -Message "Có lỗi cú pháp AST"

# ------------------------------------------------------------------------------
# TỔNG KẾT
# ------------------------------------------------------------------------------
Write-Host "--------------------------------------------------------"
Write-Host "KẾT QUẢ KIỂM THỬ RENAME COMPUTER CREDENTIAL:"
Write-Host "  Số test thành công: $testsPassed" -ForegroundColor Green
Write-Host "  Số test thất bại:   $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "--------------------------------------------------------"

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
