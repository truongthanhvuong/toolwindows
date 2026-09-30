# Test-TroubleshootManager.ps1
# Kiem tra cac ham cot loi cua Core Troubleshoot Engine

$managerPath = "$PSScriptRoot\..\src\Core\TroubleshootManager.ps1"
if (-not (Test-Path $managerPath)) {
    Write-Error "Khong tim thay ma nguon TroubleshootManager.ps1 tai $managerPath"
    exit 1
}

. $managerPath

# 1. Khoi tao Engine
$init = Initialize-VUONGTTTroubleshootEngine
if (-not $init) { 
    Write-Error "Khoi tao Engine that bai!"
    exit 1 
}

# 2. Kiem tra nap Categories (dung 7 categories)
$cats = Get-VUONGTTTroubleshootCategories
if ($null -eq $cats -or $cats.Count -ne 7) { 
    Write-Error "So luong Categories nap duoc khong bang 7 (thuc te: $($cats.Count))!"
    exit 1 
}

# 3. Kiem tra loc theo Category va TargetPage
$probByCat = Get-VUONGTTTroubleshootProblems -Category "01. Windows / Operating System"
if ($null -eq $probByCat -or $probByCat.Count -eq 0) {
    Write-Error "Loc su co theo Category '01. Windows / Operating System' khong co ket qua!"
    exit 1
}

$probByPage = Get-VUONGTTTroubleshootProblems -TargetPage "pageCleaner"
if ($null -eq $probByPage -or $probByPage.Count -eq 0) {
    Write-Error "Loc su co theo TargetPage 'pageCleaner' khong co ket qua!"
    exit 1
}

# 4. Kiem tra tim kiem nhanh ma loi
$searchRes = Search-VUONGTTTroubleshootProblem -Query "0x80070002"
if ($null -eq $searchRes -or $searchRes.Count -eq 0) { 
    Write-Error "Khong tim thay ma loi 0x80070002!"
    exit 1 
}

# 5. Kiem tra thuc thi Action: Diagnosis tren PERF-011 (Disk 100%)
$diagRes = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-011" -ActionType "Diagnosis"
if (-not $diagRes -or -not $diagRes.StatusText) { 
    Write-Error "Chan doan PERF-011 that bai!"
    exit 1 
}

# 6. Kiem tra thuc thi Action: Fix tren PERF-011
$fixRes = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-011" -ActionType "Fix"
if (-not $fixRes -or -not $fixRes.ContainsKey("Success")) { 
    Write-Error "Thuc thi Fix PERF-011 that bai!"
    exit 1 
}

# 7. Kiem tra thuc thi Action: Verify tren PERF-011
$verifyRes = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-011" -ActionType "Verify"
if (-not $verifyRes -or -not $verifyRes.ContainsKey("Success")) {
    Write-Error "Xac minh Verify PERF-011 that bai!"
    exit 1
}

# 8. Kiem tra thuc thi Action: Escalation tren PERF-011
$escRes = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-011" -ActionType "Escalation"
if (-not $escRes -or -not $escRes.OutputDetails) { 
    Write-Error "Lay Escalation guide that bai!"
    exit 1 
}
if ($escRes.OutputDetails -notlike "*0328808425*") {
    Write-Error "Escalation guide chua chua so Hotline moi '0328808425'!"
    exit 1
}
if ($escRes.OutputDetails -notlike "*truongthanhvuong61@gmail.com*") {
    Write-Error "Escalation guide chua chua Email moi 'truongthanhvuong61@gmail.com'!"
    exit 1
}
if ($escRes.OutputDetails -like "*1900-xxxx*" -or $escRes.OutputDetails -like "*support@domain.local*") {
    Write-Error "Escalation guide van con chua thong tin lien he mau cu (1900-xxxx hoac support@domain.local)!"
    exit 1
}

# 9. Kiem tra cac action tren nhom uu tien cao: Windows Update, Print Spooler, Network
$netDiag = Invoke-VUONGTTTroubleshootAction -ProblemId "NET-001" -ActionType "Diagnosis"
if (-not $netDiag -or -not $netDiag.ContainsKey("Success")) {
    Write-Error "Chan doan NET-001 that bai!"
    exit 1
}

$printDiag = Invoke-VUONGTTTroubleshootAction -ProblemId "PRINT-001" -ActionType "Diagnosis"
if (-not $printDiag -or -not $printDiag.ContainsKey("Success")) {
    Write-Error "Chan doan PRINT-001 that bai!"
    exit 1
}

# 10. Kiem tra dinh tuyen chinh xac cho PERM-001 (Khong bi hijack boi Print Spooler)
$permDiag = Invoke-VUONGTTTroubleshootAction -ProblemId "PERM-001" -ActionType "Diagnosis"
if (-not $permDiag -or -not $permDiag.Success) {
    Write-Error "Chan doan PERM-001 that bai!"
    exit 1
}
if ($permDiag.OutputDetails -like "*Spooler*" -or $permDiag.StatusText -like "*Spooler*") {
    Write-Error "Loi nghiem trong: PERM-001 bi dinh tuyen nham sang Print Spooler routine!"
    exit 1
}
if ($permDiag.OutputDetails -notlike "*truy c*p*") {
    Write-Error "PERM-001 khong goi dung RoutineFilePermission!"
    exit 1
}

# 11. Kiem tra RoutineFilePermission bao loi khi thu muc khong ton tai
$invalidPath = "C:\NonExistent_VUONGTT_Folder_XYZ_12345"
$permFixFail = Invoke-VUONGTTTroubleshootAction -ProblemId "PERM-001" -ActionType "Fix" -Parameters @{ Path = $invalidPath }
if ($permFixFail.Success -ne $false) {
    Write-Error "RoutineFilePermission phai tra ve Success = `$false khi path khong ton tai!"
    exit 1
}
if ($permFixFail.StatusText -notlike "*$invalidPath*" -or $permFixFail.StatusText -notlike "*kh*ng t*n t*i*") {
    Write-Error "RoutineFilePermission khong bao loi ro rang khi path khong ton tai!"
    exit 1
}

# 12. Kiem tra NetworkStack Fix chua ipconfig /renew
$netFix = Invoke-VUONGTTTroubleshootAction -ProblemId "NET-001" -ActionType "Fix"
if (-not $netFix -or -not $netFix.Success) {
    Write-Error "Thuc thi Fix NET-001 that bai!"
    exit 1
}
if ($netFix.OutputDetails -notlike "*ipconfig /renew*") {
    Write-Error "NetworkStack Fix chua chua lenh ipconfig /renew!"
    exit 1
}

Write-Host "[PASS] TroubleshootManager.ps1 hoat dong chinh xac va day du nghiep vu!"
exit 0