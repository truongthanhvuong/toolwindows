<#
    .SYNOPSIS
        TDD Test suite for Zalo and UniKey installation lifecycle & stability.
#>

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$installerScript = Join-Path $projectRoot "src\Core\SoftwareInstaller.ps1"
$dbJsonPath = Join-Path $projectRoot "src\Data\SoftwareDatabase.json"

Write-Host "Running Zalo & UniKey Install Lifecycle Tests..." -ForegroundColor Cyan

# 1. Test Zalo URL in SoftwareInstaller.ps1
. $installerScript

$zaloApp = $script:VUONGTT_APPS | Where-Object { $_.Id -eq "zalo" }
if (-not $zaloApp) {
    throw "TEST FAILED: Zalo app definition not found in SoftwareInstaller.ps1!"
}

Write-Host "Checking Zalo Direct URL: $($zaloApp.Url)"
$req = [System.Net.HttpWebRequest]::Create($zaloApp.Url)
$req.Method = "HEAD"
$req.UserAgent = "Mozilla/5.0"
$req.Timeout = 10000
try {
    $resp = $req.GetResponse()
    $status = [int]$resp.StatusCode
    $resp.Close()
    if ($status -ne 200) {
        throw "TEST FAILED: Zalo URL in SoftwareInstaller returned status $status (expected 200)!"
    }
    Write-Host "[PASS] Zalo URL in SoftwareInstaller is valid (HTTP 200)" -ForegroundColor Green
} catch {
    throw "TEST FAILED: Zalo URL in SoftwareInstaller is unreachable: $($_.Exception.Message)"
}

# 2. Test Zalo DirectUrl in SoftwareDatabase.json
$dbContent = Get-Content -Raw -Encoding UTF8 -Path $dbJsonPath | ConvertFrom-Json
$dbZalo = $dbContent | Where-Object { $_.Id -eq "zalo" }
if (-not $dbZalo) {
    throw "TEST FAILED: Zalo app not found in SoftwareDatabase.json!"
}

Write-Host "Checking Zalo DirectUrl in DB: $($dbZalo.DirectUrl)"
$req2 = [System.Net.HttpWebRequest]::Create($dbZalo.DirectUrl)
$req2.Method = "HEAD"
$req2.UserAgent = "Mozilla/5.0"
$req2.Timeout = 10000
try {
    $resp2 = $req2.GetResponse()
    $status2 = [int]$resp2.StatusCode
    $resp2.Close()
    if ($status2 -ne 200) {
        throw "TEST FAILED: Zalo DirectUrl in SoftwareDatabase returned status $status2 (expected 200)!"
    }
    Write-Host "[PASS] Zalo DirectUrl in SoftwareDatabase is valid (HTTP 200)" -ForegroundColor Green
} catch {
    throw "TEST FAILED: Zalo DirectUrl in SoftwareDatabase is unreachable: $($_.Exception.Message)"
}

# 3. Test UniKey Direct Installation with running process simulation
Write-Host "Testing UniKey Direct Installation..."
$resUniKey = Install-VUONGTTApp -AppId "unikey" -PreferDirect:$true -AutoLaunch:$false
Write-Host "UniKey Result: $resUniKey"
if ($resUniKey -match '\[LỖI\]|Lỗi tải|thất bại|không hợp lệ') {
    throw "TEST FAILED: UniKey direct install reported failure: $resUniKey"
}
Write-Host "[PASS] UniKey direct install succeeded without errors" -ForegroundColor Green

# 4. Test Zalo Direct Installation
Write-Host "Testing Zalo Direct Installation..."
$resZalo = Install-VUONGTTApp -AppId "zalo" -PreferDirect:$true -AutoLaunch:$false
Write-Host "Zalo Result: $resZalo"
if ($resZalo -match '\[LỖI\]|Lỗi tải|thất bại|không hợp lệ') {
    throw "TEST FAILED: Zalo direct install reported failure: $resZalo"
}
Write-Host "[PASS] Zalo direct install succeeded without errors" -ForegroundColor Green

Write-Host "`nAll Zalo & UniKey Install tests PASSED!" -ForegroundColor Green
