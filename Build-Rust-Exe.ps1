# =========================================================================
#   VUONGTT TOOL PRO 2026 — BUILD RUST (TAURI V2) EXECUTABLE
#   Bien dich Rust Native sieu nhe (~1.7MB) lam file thuc thi chinh VUONGTT_Toolkit.exe
# =========================================================================
param()

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
if (-not $projectRoot) { $projectRoot = "E:\toolwindows" }

Write-Host ">>> BAT DAU BIEN DICH VUONGTT TOOL PRO 2026 (RUST NATIVE)..." -ForegroundColor Cyan

# 1. Doc phien ban tu version.json
$verJsonPath = Join-Path $projectRoot "version.json"
$appVersion = "20.5.909.111"
if (Test-Path $verJsonPath) {
    try {
        $vObj = Get-Content -Path $verJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($vObj.version) { $appVersion = $vObj.version.Trim() }
    } catch {}
}
Write-Host " -> Phien ban phat hanh: v$appVersion" -ForegroundColor Green

# 2. Dong bo version vao Cargo.toml (SemVer 3-part) va main.rs (4-part)
$cargoTomlPath = Join-Path $projectRoot "src-tauri\Cargo.toml"
if (Test-Path $cargoTomlPath) {
    $semVer = "20.5.110"
    $parts = $appVersion.Split('.')
    if ($parts.Count -ge 4) { $semVer = "$($parts[0]).$($parts[1]).$($parts[3])" }
    $tomlContent = [System.IO.File]::ReadAllText($cargoTomlPath, [System.Text.Encoding]::UTF8)
    $tomlContent = $tomlContent -replace 'version\s*=\s*"[^"]+"', "version = `"$semVer`""
    [System.IO.File]::WriteAllText($cargoTomlPath, $tomlContent, (New-Object System.Text.UTF8Encoding($false)))
}

$mainRsPath = Join-Path $projectRoot "src-tauri\src\main.rs"
if (Test-Path $mainRsPath) {
    $mainContent = [System.IO.File]::ReadAllText($mainRsPath, [System.Text.Encoding]::UTF8)
    $mainContent = $mainContent -replace 'const APP_VERSION:\s*&str\s*=\s*"[^"]+"', "const APP_VERSION: &str = `"$appVersion`""
    [System.IO.File]::WriteAllText($mainRsPath, $mainContent, (New-Object System.Text.UTF8Encoding($false)))
}

# 3. Bien dich bang Cargo
Write-Host " -> Dang bien dich Rust release binary..." -ForegroundColor Yellow
$cargoExe = "$env:USERPROFILE\.cargo\bin\cargo.exe"
if (-not (Test-Path $cargoExe)) {
    $cargoExe = "cargo"
}

& $cargoExe build --release --manifest-path "$projectRoot\src-tauri\Cargo.toml"
if ($LASTEXITCODE -ne 0) {
    throw "Loi bien dich Rust!"
}

# 4. Copy file ra thu muc goc (ca VUONGTT_Toolkit.exe va VUONGTT_Toolkit_Rust.exe)
$srcExe = "$projectRoot\src-tauri\target\release\vuongtt_toolkit.exe"
$distExe = "$projectRoot\VUONGTT_Toolkit.exe"
$distRustExe = "$projectRoot\VUONGTT_Toolkit_Rust.exe"

Copy-Item -Path $srcExe -Destination $distExe -Force
Copy-Item -Path $srcExe -Destination $distRustExe -Force
$sizeKb = [math]::Round(((Get-Item $distExe).Length / 1KB), 2)

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "[THANH CONG] Da tao file chinh: $distExe" -ForegroundColor Green
Write-Host "[THANH CONG] Da tao file phu:   $distRustExe" -ForegroundColor Green
Write-Host "Dung luong: $sizeKb KB (Sieu nhe ~1.7 MB)" -ForegroundColor Green
Write-Host "Nen tang: Rust Native + Win32 API + Edge App Mode (0% CPU, 100ms startup)" -ForegroundColor Green
Write-Host "Design System: Fluent OS Utility (15 Stitch Screens)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# 5. Smoke test & version verification
& $distExe --smoke-test
& $distExe --version
