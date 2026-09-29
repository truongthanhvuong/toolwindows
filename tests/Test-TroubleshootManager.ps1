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

Write-Host "[PASS] TroubleshootManager.ps1 hoat dong chinh xac va day du nghiep vu!"
exit 0