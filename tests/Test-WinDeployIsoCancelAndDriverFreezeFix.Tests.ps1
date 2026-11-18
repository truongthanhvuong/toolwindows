$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        throw "Assertion Failed: $message"
    }
    Write-Host "  [PASS] $message" -ForegroundColor Green
}

Write-Host ""
Write-Host ">>> KIEM THU TDD: FIX LOI HUY CHON ISO & DONG BANG DRIVER KHI CAI WIN <<<" -ForegroundColor Cyan
Write-Host ""

$mainRsPath = "E:\toolwindows\src-tauri\src\main.rs"
$opsPath = "E:\toolwindows\src-tauri\src\system_ops.rs"
$appJsPath = "E:\toolwindows\src-ui\app.js"

$mainRsContent = [System.IO.File]::ReadAllText($mainRsPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)

Write-Host "--- Nhom 1: Rust IPC Routing (main.rs) ---" -ForegroundColor Yellow

# 1.1 Khi browse_iso that bai/bi huy, file_path phai la chuoi rong
Assert-True ($mainRsContent.Contains('let escaped_path = if success { escape_json_str(&msg) } else { String::new() };')) "main.rs phai tra ve file_path rong khi browse_iso khong thanh cong"

Write-Host ""
Write-Host "--- Nhom 2: Frontend Validation & Anti-Freeze (app.js) ---" -ForegroundColor Yellow

# 2.1 app.js browseIsoFile phai kiem tra !res.file_path.includes('hủy')
Assert-True ($appJsContent.Contains('!res.file_path.includes("hủy")')) "browseIsoFile phai loai bo thong bao huy khoi duong dan ISO"

# 2.2 startWinDeploy phai kiem tra strict invalid path truoc khi set loading hay bat dau
Assert-True ($appJsContent.Contains('rawPath.includes("hủy")') -and $appJsContent.Contains('rawPath.includes("chưa chọn")')) "startWinDeploy phai tu choi chuoi huy/chua chon truoc khi bat dau"

# 2.3 startWinDeploy phai tu dong mo Console Log Drawer (openUniversalLog)
Assert-True ($appJsContent.Contains('window.openUniversalLog') -and $appJsContent.Contains('[CÀI WIN TỰ ĐỘNG]')) "startWinDeploy phai tu dong mo Console Log Drawer va ghi log realtime"

# 2.4 startWinDeploy khong duoc goi duplicate backupDriverFromDeploy trong than ham
$startWinDeployPart = $appJsContent.Substring($appJsContent.IndexOf("async function startWinDeploy()"))
$startWinDeployPart = $startWinDeployPart.Substring(0, $startWinDeployPart.IndexOf("window.startWinDeploy = startWinDeploy;"))
Assert-True (-not ($startWinDeployPart.Contains("await backupDriverFromDeploy()"))) "startWinDeploy khong duoc goi lap lai backupDriverFromDeploy"

# 2.5 input-iso-path phai co event listener dong bo truc tiep voi iso-path-text khi nguoi dung nhap/paste
Assert-True ($appJsContent.Contains('inputIsoEl.addEventListener("input"')) "input-iso-path phai co live listener de dong bo voi iso-path-text"

Write-Host ""
Write-Host "--- Nhom 3: Backend Zero-Delay Precheck & Robust Mount (system_ops.rs) ---" -ForegroundColor Yellow

# 3.1 system_ops.rs phai kiem tra iso_path va test-path ngay tai dau ham start_win_deploy
Assert-True ($opsContent.Contains('[LỖI] Đường dẫn tệp tin ISO không hợp lệ hoặc chưa được chọn!')) "start_win_deploy phai kiem tra hop le iso_path ngay dau ham"
Assert-True ($opsContent.Contains('[LỖI] Không tìm thấy file ISO hoặc ổ đĩa cài đặt tại:')) "start_win_deploy phai kiem tra Test-Path ngay truoc khi thuc hien cac tac vu nang"

# 3.2 system_ops.rs phai co fallback kiem tra volume da mount san neu Mount-DiskImage bi loi
Assert-True ($opsContent.Contains('Get-DiskImage -ImagePath $iso') -and $opsContent.Contains('Get-Volume')) "system_ops.rs phai co co che tu dong nhan dien o dia ISO neu da duoc mount truoc do"

# 3.3 Start-Process phai thiet lap WorkingDirectory la thu muc o dia mount
Assert-True ($opsContent.Contains('Start-Process -FilePath "{}\setup.exe" -ArgumentList "{}" -WorkingDirectory "{}\"')) "Start-Process phai set WorkingDirectory den o dia mount setup.exe"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "KET QUA: TAT CA CAC MUC KIEM THU TDD DEU DAT 100% PASS" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
