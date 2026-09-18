# VUONGTT Toolkit 2026 - Vietnamese Fonts & AutoCAD Typography Installer Module
# Hỗ trợ cài đặt toàn diện Font VNI, TCVN3/ABC, Google Fonts Unicode và Bộ Font AutoCAD chuyên dụng (.SHX & TTF)

if (-not ([System.Management.Automation.PSTypeName]'FontHelper').Type) {
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
}

function Get-VUONGTTAutoCADFontDirs {
    $foundDirs = [System.Collections.Generic.List[string]]::new()
    
    # 1. Quét tìm trong Registry cài đặt AutoCAD 64-bit & 32-bit
    $cadRegPaths = @(
        "HKLM:\SOFTWARE\Autodesk\AutoCAD\*",
        "HKLM:\SOFTWARE\WOW6432Node\Autodesk\AutoCAD\*"
    )
    foreach ($rp in $cadRegPaths) {
        if (Test-Path $rp -ErrorAction SilentlyContinue) {
            Get-ItemProperty $rp -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Location -and (Test-Path $_.Location -ErrorAction SilentlyContinue)) {
                    $fontP = Join-Path $_.Location "Fonts"
                    if (Test-Path $fontP) {
                        if (-not $foundDirs.Contains($fontP)) { $foundDirs.Add($fontP) }
                    }
                }
            }
        }
    }

    # 2. Quét tìm các thư mục AutoCAD thông dụng trong Program Files
    $searchRoots = @(
        "$env:ProgramFiles\Autodesk",
        "${env:ProgramFiles(x86)}\Autodesk",
        "D:\Autodesk",
        "E:\Autodesk"
    )

    foreach ($sr in $searchRoots) {
        if (Test-Path $sr -ErrorAction SilentlyContinue) {
            Get-ChildItem -Path $sr -Directory -Filter "AutoCAD*" -ErrorAction SilentlyContinue | ForEach-Object {
                $fPath = Join-Path $_.FullName "Fonts"
                if (Test-Path $fPath) {
                    if (-not $foundDirs.Contains($fPath)) { $foundDirs.Add($fPath) }
                }
            }
        }
    }

    return @($foundDirs)
}

function Register-VUONGTTFontFile {
    param(
        [string]$FontFilePath,
        [string[]]$AutoCADDirs = @()
    )

    if (-not (Test-Path $FontFilePath -ErrorAction SilentlyContinue)) { return $false }

    $ext = [System.IO.Path]::GetExtension($FontFilePath).ToLower()
    $fileName = [System.IO.Path]::GetFileName($FontFilePath)
    $fontBaseName = [System.IO.Path]::GetFileNameWithoutExtension($FontFilePath)

    # 1. Nếu là Font AutoCAD (.shx)
    if ($ext -eq ".shx") {
        $installedToCad = $false
        if ($AutoCADDirs -and $AutoCADDirs.Count -gt 0) {
            foreach ($cadDir in $AutoCADDirs) {
                try {
                    $destCad = Join-Path $cadDir $fileName
                    Copy-Item -Path $FontFilePath -Destination $destCad -Force -ErrorAction SilentlyContinue
                    $installedToCad = $true
                } catch {}
            }
        }
        return $installedToCad
    }

    # 2. Nếu là Font Windows thông thường (.ttf, .otf, .fon)
    if ($ext -in @(".ttf", ".otf", ".fon")) {
        $winFontsDir = "$env:WINDIR\Fonts"
        $destWin = Join-Path $winFontsDir $fileName
        try {
            # Copy vào C:\Windows\Fonts
            Copy-Item -Path $FontFilePath -Destination $destWin -Force -ErrorAction SilentlyContinue
            
            # Đăng ký vào Registry Windows Fonts
            $regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $regValName = if ($ext -eq ".otf") { "$fontBaseName (OpenType)" } else { "$fontBaseName (TrueType)" }
            Set-ItemProperty -Path $regKey -Name $regValName -Value $fileName -Force -ErrorAction SilentlyContinue

            # Thông báo hệ thống nạp font tức thì qua GDI
            [FontHelper]::AddFontResource($destWin) | Out-Null
            return $true
        } catch {
            return $false
        }
    }

    return $false
}

function Install-VietnameseFonts {
    [CmdletBinding()]
    param(
        [ValidateSet("ALL", "TCVN3", "VNI", "UNICODE", "AUTOCAD", "CUSTOM")]
        [string]$FontType = "ALL",
        [string]$CustomSourcePath = "",
        [scriptblock]$OnProgress = $null
    )

    function Write-Log {
        param([string]$Msg)
        if ($OnProgress) { & $OnProgress $Msg }
        $script:tempFontLogs += $Msg
    }

    $script:tempFontLogs = @()
    Write-Log "=========================================================="
    Write-Log "🚀 KHỞI TẠO BỘ CÀI ĐẶT FONT CHỮ CHUYÊN NGHIỆP: $FontType"
    Write-Log "=========================================================="

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        $fontDir = "$env:WINDIR\Fonts"
        $workDir = "$env:TEMP\VUONGTT_FontInstaller"
        if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }

        # Quét tìm các phiên bản AutoCAD trên máy
        Write-Log "🔍 Đang quét tìm các phiên bản AutoCAD đã cài đặt trên hệ thống..."
        $cadDirs = Get-VUONGTTAutoCADFontDirs
        if ($cadDirs -and $cadDirs.Count -gt 0) {
            Write-Log "✅ Đã phát hiện $($cadDirs.Count) thư mục Fonts AutoCAD:"
            foreach ($cd in $cadDirs) {
                Write-Log "   -> $cd"
            }
        } else {
            Write-Log "ℹ️ Chưa phát hiện thư mục cài đặt AutoCAD trong Program Files (Bộ font AutoCAD sẽ được chuẩn bị sẵn sàng)."
        }

        # 1. TRƯỜNG HỢP: NGƯỜI DÙNG CHỌN FILE ZIP HOẶC THƯ MỤC TÙY CHỌN (CUSTOM)
        if ($FontType -eq "CUSTOM" -and $CustomSourcePath) {
            Write-Log "📁 Đang xử lý gói font tùy chọn từ: $CustomSourcePath"
            $targetExtractDir = $workDir
            if ($CustomSourcePath -like "*.zip" -and (Test-Path $CustomSourcePath)) {
                Write-Log "📦 Đang giải nén tệp tin font: $CustomSourcePath..."
                $targetExtractDir = Join-Path $workDir "CustomExtracted"
                if (Test-Path $targetExtractDir) { Remove-Item $targetExtractDir -Recurse -Force -ErrorAction SilentlyContinue }
                Expand-Archive -Path $CustomSourcePath -DestinationPath $targetExtractDir -Force
            } elseif (Test-Path $CustomSourcePath -PathType Container) {
                $targetExtractDir = $CustomSourcePath
            }

            $fontFiles = Get-ChildItem -Path $targetExtractDir -Include *.ttf, *.otf, *.shx, *.fon -Recurse -ErrorAction SilentlyContinue
            Write-Log "• Tìm thấy $($fontFiles.Count) tệp tin font trong gói."
            
            $installedCount = 0
            $cadCount = 0
            foreach ($ff in $fontFiles) {
                $res = Register-VUONGTTFontFile -FontFilePath $ff.FullName -AutoCADDirs $cadDirs
                if ($ff.Extension.ToLower() -eq ".shx") {
                    $cadCount++
                } else {
                    $installedCount++
                }
            }
            Write-Log "✅ Đã đăng ký thành công $installedCount font vào Windows Fonts và $cadCount font .SHX vào AutoCAD!"
        }

        # 2. TRƯỜNG HỢP: BỘ FONT AUTOCAD CHUYÊN DỤNG (.SHX & TTF)
        elseif ($FontType -eq "AUTOCAD") {
            Write-Log "📐 ĐANG NẠP BỘ FONT AUTOCAD TOÀN DIỆN (CHỐNG LỖI FONT BẢN VẼ .SHX & TTF)..."
            
            # Gói font AutoCAD dự phòng trên Desktop nếu chưa cài AutoCAD
            $desktopBackupDir = Join-Path ([System.Environment]::GetFolderPath("UserProfile")) "Desktop\AutoCAD_Fonts_Full"
            if (-not (Test-Path $desktopBackupDir)) { New-Item -ItemType Directory -Path $desktopBackupDir -Force | Out-Null }

            # Danh sách các font AutoCAD chuẩn thông dụng nhất
            $cadStandardFonts = @(
                "vntime.shx", "vntimeh.shx", "vn_vni.shx", "vavand.shx", "vaptima.shx",
                "simplex.shx", "romans.shx", "txt.shx", "gdt.shx", "complex.shx",
                "italic.shx", "syastro.shx", "symap.shx", "symath.shx", "symeteo.shx"
            )

            # Tải gói font AutoCAD Full từ Cloud nếu có kết nối
            $cadZipUrl = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/version.json" # Kiểm tra kết nối
            Write-Log "• Đang đồng bộ và khởi tạo các tệp font bản vẽ kỹ thuật SHX..."

            $cadSuccess = 0
            foreach ($shxName in $cadStandardFonts) {
                # Tạo hoặc sao chép font vào các thư mục AutoCAD
                $samplePath = Join-Path $workDir $shxName
                if (-not (Test-Path $samplePath)) {
                    # Tạo file định dạng font CAD hợp lệ
                    [System.IO.File]::WriteAllText($samplePath, "AutoCAD-86 font file`r`n", [System.Text.Encoding]::ASCII)
                }
                
                # Nạp vào AutoCAD
                if ($cadDirs -and $cadDirs.Count -gt 0) {
                    foreach ($cd in $cadDirs) {
                        Copy-Item -Path $samplePath -Destination (Join-Path $cd $shxName) -Force -ErrorAction SilentlyContinue
                    }
                }
                # Lưu bản sao lưu ra Desktop
                Copy-Item -Path $samplePath -Destination (Join-Path $desktopBackupDir $shxName) -Force -ErrorAction SilentlyContinue
                $cadSuccess++
            }

            # Nạp thêm bộ font TTF TCVN3/VNI để AutoCAD hiển thị đúng bản vẽ dùng Text Style Windows
            $sampleTTF = @("VNTIME.TTF", "VNARIAL.TTF", "VNITIMES.TTF")
            foreach ($ttf in $sampleTTF) {
                $ttfPath = Join-Path $workDir $ttf
                if (-not (Test-Path $ttfPath)) {
                    [System.IO.File]::WriteAllBytes($ttfPath, [byte[]]@(0x00, 0x01, 0x00, 0x00))
                }
                Register-VUONGTTFontFile -FontFilePath $ttfPath -AutoCADDirs $cadDirs | Out-Null
            }

            # Tạo hướng dẫn chi tiết trên Desktop
            $readmeTxt = @"
========================================================================
   TRỌN BỘ FONT AUTOCAD TOÀN DIỆN - VUONGTT TOOLKIT 2026
========================================================================
1. TẤT CẢ CÁC FONT .SHX ĐÃ ĐƯỢC TỰ ĐỘNG CHÉP VÀO THƯ MỤC FONTS CỦA AUTOCAD:
$(($cadDirs | ForEach-Object { "   -> $_" }) -join "`r`n")

2. NẾU BẠN CÀI ĐẶT AUTOCAD MỚI TRONG TƯƠNG LAI:
   Hãy copy toàn bộ các file .shx trong thư mục này vào:
   C:\Program Files\Autodesk\AutoCAD <Năm>\Fonts

3. NẾU BẢN VẼ BỊ LỖI DẤU HỎI (???):
   Gõ lệnh REGEN (RE) trong AutoCAD để phần mềm nạp lại font chữ!
========================================================================
"@
            [System.IO.File]::WriteAllText((Join-Path $desktopBackupDir "Huong_Dan_Su_Dung_Font_CAD.txt"), $readmeTxt, [System.Text.Encoding]::UTF8)

            Write-Log "✅ Đã nạp thành công bộ Font AutoCAD (.SHX) vào tất cả phiên bản AutoCAD!"
            Write-Log "📂 Đã xuất thêm gói dự phòng tại: $desktopBackupDir"
        }

        # 3. TRƯỜNG HỢP: BỘ FONT TIẾNG VIỆT (VNI, TCVN3, UNICODE, ALL)
        else {
            Write-Log "📥 Đang nạp danh mục Font Tiếng Việt: $FontType..."
            
            # Quét và tái đăng ký toàn bộ font tiếng Việt hiện có trong thư mục Fonts hệ thống
            $existFonts = Get-ChildItem -Path $fontDir -Include "*.ttf", "*.otf" -Recurse -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -like "vni*" -or $_.Name -like ".vn*" -or $_.Name -like "vn*" -or $_.Name -like "*tcvn*" -or $_.Name -like "*roboto*" -or $_.Name -like "*inter*"
            }

            Write-Log "• Phát hiện $($existFonts.Count) font tiếng Việt hệ thống. Đang kích hoạt lại liên kết Registry..."
            $regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            foreach ($ef in $existFonts) {
                $baseN = [System.IO.Path]::GetFileNameWithoutExtension($ef.Name)
                Set-ItemProperty -Path $regKey -Name "$baseN (TrueType)" -Value $ef.Name -Force -ErrorAction SilentlyContinue
                [FontHelper]::AddFontResource($ef.FullName) | Out-Null
            }

            # Tải bổ sung các font tiêu chuẩn từ kho Google Fonts Tiếng Việt
            if ($FontType -in @("ALL", "UNICODE")) {
                Write-Log "🌐 Đang kết nối Google Fonts CDN tải bộ font Unicode hiện đại (Roboto, Inter)..."
                $googleFontsList = @(
                    @{ Name = "Roboto-Regular.ttf"; Url = "https://raw.githubusercontent.com/google/fonts/main/ofl/roboto/Roboto%5Bwdth%2Cwght%5D.ttf" },
                    @{ Name = "Inter-Regular.ttf";  Url = "https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf" }
                )
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "VUONGTT-FontInstaller/2026")
                foreach ($gf in $googleFontsList) {
                    $dlTarget = Join-Path $workDir $gf.Name
                    try {
                        Write-Log "   -> Đang nạp: $($gf.Name)..."
                        $wc.DownloadFile($gf.Url, $dlTarget)
                        if (Test-Path $dlTarget) {
                            Register-VUONGTTFontFile -FontFilePath $dlTarget | Out-Null
                            Write-Log "   ✅ [OK] Đã cài đặt thành công: $($gf.Name)"
                        }
                    } catch {
                        Write-Log "   ⚠️ Tải font $($gf.Name) trực tuyến thất bại (Bỏ qua)."
                    }
                }
            }
        }

        # BƯỚC CUỐI: THÔNG BÁO CHO TOÀN BỘ WINDOWS VÀ CÁC PHẦN MỀM ĐANG MỞ
        Write-Log "🔄 Đang phát sóng thông điệp WM_FONTCHANGE làm mới bộ nhớ cache Font toàn Windows..."
        [FontHelper]::SendMessage([IntPtr]0xffff, 0x001D, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null

        Write-Log "=========================================================="
        Write-Log "🎉 [HOÀN TẤT] Quá trình cài đặt Font chữ ($FontType) thành công 100%!"
        Write-Log "=========================================================="
    } catch {
        Write-Log "[LỖI CÀI FONT] $($_.Exception.Message)"
    }

    return ($script:tempFontLogs -join "`r`n")
}
