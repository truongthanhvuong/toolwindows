# Script chuẩn hóa toàn bộ file PS1 sang UTF-8 WITH BOM
$enc = New-Object System.Text.UTF8Encoding($true)
$files = Get-ChildItem -Path $PSScriptRoot -Include *.ps1, *.psm1 -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' }

$count = 0
foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    if (-not $hasBom) {
        $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($f.FullName, $text, $enc)
        Write-Host "Applied UTF-8 BOM to: $($f.Name)" -ForegroundColor Green
        $count++
    }
}
Write-Host "Tong so file da gan BOM: $count" -ForegroundColor Cyan
