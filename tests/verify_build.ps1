$f = Get-Item "E:\toolwindows\VUONGTT_Toolkit.exe"
$fvi = (Get-Command "E:\toolwindows\VUONGTT_Toolkit.exe").FileVersionInfo

[PSCustomObject]@{
    Name           = $f.Name
    SizeKB         = [math]::Round($f.Length / 1KB, 2)
    LastWriteTime  = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    FileVersion    = $fvi.FileVersion
    ProductVersion = $fvi.ProductVersion
} | Format-List
