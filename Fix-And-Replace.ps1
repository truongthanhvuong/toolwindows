
# Fix-And-Replace.ps1
# Chạy với quyền Administrator
$ErrorActionPreference = 'Stop'
$SourceUrl = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/VUONGTT_Toolkit.exe"
$TargetExe = "E:\toolwindows\VUONGTT_Toolkit.exe"
$TempExe = "E:\toolwindows\VUONGTT_Toolkit_Fix.exe"

Write-Host "--- THỰC HIỆN ÉP THAY THẾ FILE THỰC THI ---" -ForegroundColor Yellow

# 1. Kill bằng mọi giá
taskkill /F /IM "VUONGTT_Toolkit.exe" /T
taskkill /F /IM "VUONGTT_Toolkit_Rust.exe" /T

# 2. Tải bản mới về Temp
Invoke-WebRequest -Uri $SourceUrl -OutFile $TempExe -UseBasicParsing

# 3. Ép move đè lên file cũ (CMD move hỗ trợ tốt hơn PowerShell khi file bị lock)
cmd /c move /Y "$TempExe" "$TargetExe"

Write-Host "--- HOÀN TẤT. VUI LÒNG MỞ LẠI TOOL ---" -ForegroundColor Green
Start-Sleep -Seconds 2
