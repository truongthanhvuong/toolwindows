# Test-TroubleshootDatabase.ps1
# Kiểm tra tính hợp lệ của cơ sở dữ liệu sự cố IT Helpdesk (TroubleshootDatabase.json)

$jsonPath = "$PSScriptRoot\..\src\Data\TroubleshootDatabase.json"
if (-not (Test-Path $jsonPath)) {
    Write-Error "TroubleshootDatabase.json khong ton tai!"
    exit 1
}

$content = Get-Content -Raw -Encoding UTF8 -Path $jsonPath | ConvertFrom-Json
if (-not $content.Categories -or $content.Categories.Count -ne 7) {
    Write-Error "So luong Categories phai dung bang 7!"
    exit 1
}

if (-not $content.Problems -or $content.Problems.Count -lt 150) {
    Write-Error "Danh sach su co Problems chua du so luong quy dinh (toi thieu 150+ su co)!"
    exit 1
}

# Kiem tra tinh toan ven cua cac truong bat buoc tren moi Problem
$requiredFields = @("Id", "Category", "SubCategory", "TargetPage", "Title", "ErrorCode", "Symptoms", "Cause", "Diagnosis", "Fix", "Verification", "Escalation")
$invalidProblems = @()

foreach ($prob in $content.Problems) {
    foreach ($field in $requiredFields) {
        if ($null -eq $prob.$field) {
            $invalidProblems += "$($prob.Id): thieu truong $field"
        }
    }
}

if ($invalidProblems.Count -gt 0) {
    $errSample = $invalidProblems[0..4] -join "; "
    Write-Error "Phat hien $($invalidProblems.Count) su co thieu truong thuoc tinh chuan: $errSample"
    exit 1
}

Write-Host "[PASS] TroubleshootDatabase.json hop le voi $($content.Problems.Count) su co thuoc 7 Danh muc!"
exit 0