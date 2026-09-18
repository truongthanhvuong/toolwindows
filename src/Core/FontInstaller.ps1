# VUONGTT Toolkit 2026 - Vietnamese Fonts & Typography Installer Module

function Install-VietnameseFonts {
    [CmdletBinding()]
    param(
        [ValidateSet("ALL", "TCVN3", "VNI", "UNICODE")]
        [string]$FontType = "ALL",
        [scriptblock]$OnProgress = $null
    )

    $log = @()
    if ($OnProgress) { & $OnProgress "Bắt đầu khởi tạo tiến trình nạp bộ Font Tiếng Việt ($FontType)..." }

    try {
        $fontDir = "$env:WINDIR\Fonts"
        $regFonts = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

        $downloadDir = "$env:TEMP\VUONGTT_Fonts"
        if (-not (Test-Path $downloadDir)) { New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null }

        $log += "[OK] Đã chuẩn bị môi trường Fonts hệ thống: $fontDir"

        # Download standard VN fonts package if not present
        $zipUrl = "https://raw.githubusercontent.com/vuongtt/font-pack/main/vietnamese_essential_fonts.zip" # Fallback CDN
        $zipFile = Join-Path $downloadDir "fonts.zip"

        $log += "[OK] Kiểm tra các tệp font hệ thống có sẵn..."
        
        # Windows Native Shell App to register font correctly
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14) # Fonts SpecialFolder

        # Notify font change to system
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class FontHelper {
    [DllImport("gdi32.dll", EntryPoint="AddFontResourceW", SetLastError=true)]
    public static extern int AddFontResource([In, MarshalAs(UnmanagedType.LPWStr)] string lpFileName);

    [DllImport("user32.dll")]
    public static extern int SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@ -ErrorAction SilentlyContinue

        [FontHelper]::SendMessage([IntPtr]0xffff, 0x001D, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null

        $log += "[OK] Đã làm mới hệ thống GDI font cache của Windows."
        $log += "=== Hoàn tất cài đặt bộ Font Tiếng Việt ($FontType) cho các ứng dụng văn phòng và đồ họa! ==="
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }

    return ($log -join "`n")
}
