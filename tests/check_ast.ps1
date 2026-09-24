$filesToCheck = @(
    "e:\toolwindows\VUONGTT_Toolkit.ps1",
    "e:\toolwindows\src\Core\SystemBackupManager.ps1"
)

$allOk = $true
foreach ($f in $filesToCheck) {
    $errs = $null
    $tokens = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errs) | Out-Null
    if ($errs -and $errs.Count -gt 0) {
        $allOk = $false
        Write-Host "  [SYNTAX ERROR] $f" -ForegroundColor Red
        foreach ($e in $errs) {
            Write-Host "    Line $($e.Extent.StartLineNumber): $($e.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [SYNTAX OK] $f" -ForegroundColor Green
    }
}

if (-not $allOk) {
    Exit 1
} else {
    Write-Host "`n>>> TOAN BO MA NGUON DONG THOI HOP LE 100% <<<" -ForegroundColor Cyan
    Exit 0
}
