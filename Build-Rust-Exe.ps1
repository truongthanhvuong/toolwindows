# =========================================================================
#   VUONGTT TOOL PRO 2026 — BUILD RUST (TAURI V2) EXECUTABLE
# =========================================================================
param()

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot

Write-Host ">>> BAT DAU BIEN DICH VUONGTT TOOL PRO 2026 (RUST TAURI V2)..." -ForegroundColor Cyan

# 1. Cap nhat src-ui/index.html tu 14 man hinh Stitch
Write-Host " -> Dong bo 14 man hinh Stitch vao src-ui/index.html..." -ForegroundColor Yellow
& "$projectRoot\scripts\Build-StitchUI.ps1"

# 2. Bien dich bang Cargo
Write-Host " -> Dang bien dich Rust release binary..." -ForegroundColor Yellow
$cargoExe = "$env:USERPROFILE\.cargo\bin\cargo.exe"
if (-not (Test-Path $cargoExe)) {
    $cargoExe = "cargo"
}

& $cargoExe build --release --manifest-path "$projectRoot\src-tauri\Cargo.toml"
if ($LASTEXITCODE -ne 0) {
    throw "Loi bien dich Rust!"
}

# 3. Copy file ra thu muc goc
$srcExe = "$projectRoot\src-tauri\target\release\vuongtt_toolkit.exe"
$distExe = "$projectRoot\VUONGTT_Toolkit_Rust.exe"

Copy-Item -Path $srcExe -Destination $distExe -Force
$sizeKb = [math]::Round(((Get-Item $distExe).Length / 1KB), 2)

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "[THANH CONG] Da tao file: $distExe" -ForegroundColor Green
Write-Host "Dung luong: $sizeKb KB (Sieu nhe ~1.7 MB)" -ForegroundColor Green
Write-Host "Design System: Fluent OS Utility (13+1 Stitch Screens)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# 4. Smoke test
& $distExe --smoke-test
