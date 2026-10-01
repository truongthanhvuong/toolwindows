# tests/Fix-AllUtf8Bom.ps1
# Ensures all .ps1 and .json files have UTF-8 BOM encoding

$rootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$targets = Get-ChildItem -Path $rootDir -Include "*.ps1", "*.json", "*.xaml" -Recurse | Where-Object {
    $_.FullName -notmatch "\\(\.git|\.agents|\.gemini|bin|obj)\\"
}

$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$count = 0

foreach ($file in $targets) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        if (-not $hasBom) {
            $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8Bom)
            $count++
        }
    } catch {}
}

Write-Host "Applied UTF-8 BOM to $count files." -ForegroundColor Green
