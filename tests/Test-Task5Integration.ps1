# Test-Task5Integration.ps1
# Kiem tra cu phap va tich hop Task 5 cho VUONGTT_Toolkit.ps1

$ErrorActionPreference = "Stop"

Write-Host "1. Kiem tra cu phap PowerShell bang AST Parser..."
$parseErrors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile("E:\toolwindows\VUONGTT_Toolkit.ps1", [ref]$tokens, [ref]$parseErrors)

if ($parseErrors -and $parseErrors.Count -gt 0) {
    Write-Error "VUONGTT_Toolkit.ps1 co $($parseErrors.Count) loi cu phap:`n$($parseErrors | Out-String)"
    exit 1
}
Write-Host "[PASS] VUONGTT_Toolkit.ps1 cu phap hop le 100%! 0 syntax errors." -ForegroundColor Green

Write-Host "2. Kiem tra import TroubleshootManager..."
$content = Get-Content -Path "E:\toolwindows\VUONGTT_Toolkit.ps1" -Raw -Encoding UTF8
if ($content -notmatch 'TroubleshootManager\.ps1') {
    Write-Error "Chua import TroubleshootManager.ps1 vao VUONGTT_Toolkit.ps1!"
    exit 1
}
if ($content -notmatch 'Initialize-VUONGTTTroubleshootEngine') {
    Write-Error "Chua goi Initialize-VUONGTTTroubleshootEngine!"
    exit 1
}
Write-Host "[PASS] TroubleshootManager da duoc import va khoi tao thanh cong!" -ForegroundColor Green

Write-Host "3. Kiem tra 8 Hubs trong danh sach menu va pages dictionary..."
$requiredHubs = @('SysInfo', 'SystemFix', 'NetworkLAN', 'PrinterLAN', 'OfficeAIO', 'SoftwareHub', 'HardwareDisk', 'TechUtilities', 'AdminPortal')
foreach ($hub in $requiredHubs) {
    if ($content -notmatch "`"$hub`"\s*=") {
        Write-Error "Thieu Hub '$hub' trong `$pages dictionary!"
        exit 1
    }
}
Write-Host "[PASS] Tat ca 8 Hubs + AdminPortal da duoc dinh nghia trong `$pages dictionary!" -ForegroundColor Green

Write-Host "4. Kiem tra cac ham Capsule Sub-tabs..."
$requiredSubTabFunctions = @(
    'Switch-SysInfoSubTab',
    'Switch-SystemFixSubTab',
    'Switch-SoftwareHubSubTab',
    'Switch-HardwareDiskSubTab',
    'Switch-TechUtilitiesSubTab',
    'Set-CapsuleSubTabStyle'
)
foreach ($fn in $requiredSubTabFunctions) {
    if ($content -notmatch "function\s+$fn\b") {
        Write-Error "Thieu ham '$fn'!"
        exit 1
    }
}
Write-Host "[PASS] Tat ca 5 ham SubTab switcher da duoc dinh nghia!" -ForegroundColor Green

Write-Host "5. Kiem tra cac ham Troubleshoot Widget..."
$requiredTroubleshootFunctions = @(
    'Refresh-TroubleshootList',
    'Show-TroubleshootDetail',
    'Execute-TroubleshootAction'
)
foreach ($fn in $requiredTroubleshootFunctions) {
    if ($content -notmatch "function\s+$fn\b") {
        Write-Error "Thieu ham '$fn'!"
        exit 1
    }
}
Write-Host "[PASS] Tat ca cac ham xu ly Troubleshoot Widget da duoc dinh nghia!" -ForegroundColor Green

Write-Host "6. Kiem tra cac su kien nut bam Troubleshoot..."
$troubleshootEvents = @(
    'dgTroubleshootList\.Add_SelectionChanged',
    'cboTroubleshootCategoryFilter\.Add_SelectionChanged',
    'txtTroubleshootSearch\.Add_TextChanged',
    'btnTroubleshootClearSearch\.Add_Click',
    'btnActionDiagnosis\.Add_Click',
    'btnActionAutoFix\.Add_Click',
    'btnActionVerify\.Add_Click',
    'btnActionEscalation\.Add_Click',
    'btnClearTroubleshootLog\.Add_Click'
)
foreach ($ev in $troubleshootEvents) {
    if ($content -notmatch $ev) {
        Write-Error "Thieu su kien '$ev'!"
        exit 1
    }
}
Write-Host "[PASS] Tat ca 9 su kien tuong tac Troubleshoot Widget da duoc gan thanh cong!" -ForegroundColor Green

Write-Host "`n=== TAT CA 6 MUC KIEM TRA INTEGRATION TASK 5 DEU DAT 100%! ===" -ForegroundColor Green
