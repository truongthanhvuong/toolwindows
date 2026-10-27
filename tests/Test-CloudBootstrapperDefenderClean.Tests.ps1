# TDD Test Suite: Test-CloudBootstrapperDefenderClean.Tests.ps1
# Ensures win.ps1 and vuongtt.ps1 contain zero signatures that trigger Defender / AMSI (Trojan:Win32/ClickFix.CCY!MTB)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$winPs1 = Join-Path $repoRoot "win.ps1"
$vuongttPs1 = Join-Path $repoRoot "vuongtt.ps1"

Write-Host "`n=== BAT DAU KIEM THU BOOTSTRAPPER DEFENDER CLEAN ===" -ForegroundColor Cyan

$allPassed = $true

function Assert-Test([string]$name, [scriptblock]$condition) {
    try {
        $result = & $condition
        if ($result) {
            Write-Host " [PASS] $name" -ForegroundColor Green
        } else {
            Write-Host " [FAIL] $name" -ForegroundColor Red
            $script:allPassed = $false
        }
    } catch {
        Write-Host " [FAIL] $name - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:allPassed = $false
    }
}

foreach ($targetFile in @($winPs1, $vuongttPs1)) {
    $fileName = Split-Path $targetFile -Leaf
    Write-Host "`n--- Kiem tra file: $fileName ---" -ForegroundColor Yellow

    Assert-Test "$fileName ton tai tren dia" {
        Test-Path $targetFile
    }

    $content = Get-Content -Path $targetFile -Raw -Encoding UTF8

    Assert-Test "$fileName khong chua Add-MpPreference (Defense Evasion T1562.001)" {
        $content -notmatch "Add-MpPreference"
    }

    Assert-Test "$fileName khong chua DllImport / kernel32 P/Invoke" {
        ($content -notmatch 'DllImport\s*\(\s*"?kernel32\.dll"?\s*\)') -and ($content -notmatch 'Win32Console')
    }

    Assert-Test "$fileName khong chua -EncodedCommand (Base64 Execution Trigger)" {
        $content -notmatch '(?i)-EncodedCommand'
    }

    Assert-Test "$fileName khong chua [System.Reflection.Assembly]::Load (Reflective PE Injection)" {
        $content -notmatch 'Assembly\]::Load' -and $content -notmatch 'Assembly\.Load'
    }

    Assert-Test "$fileName cu phap PowerShell hop le (AST Parser 0 syntax errors)" {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count -eq 0
    }

    Assert-Test "$fileName ho tro TLS 1.2 va TLS 1.3" {
        $content -match 'Tls12' -and $content -match 'Tls13'
    }

    Assert-Test "$fileName kiem tra va yeu cau quyen Administrator sach" {
        $content -match '\[Security\.Principal\.WindowsBuiltInRole\]::Administrator'
    }

    Assert-Test "$fileName tao day du hai loi tat Desktop (VUONGTT Toolkit.lnk va VUONGTT Tool Pro 2026.lnk)" {
        $content -match 'VUONGTT Toolkit\.lnk' -and $content -match 'VUONGTT Tool Pro 2026\.lnk'
    }

    Assert-Test "$fileName khoi chay tien trinh EXE truc tiep an toan" {
        $content -match 'Start-Process\s+(-FilePath\s+)?\$exePath'
    }
}

Write-Host "`n=== KET QUA TONG THE ===" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host ">>> TAT CA CAC BAI KIEM THU DEFENDER CLEAN DEU DAT (100% PASS) <<<`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host ">>> PHAT HIEN LOI TRONG CAC BAI KIEM THU DEFENDER CLEAN! <<<`n" -ForegroundColor Red
    exit 1
}
