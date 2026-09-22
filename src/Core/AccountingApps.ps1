# VUONGTT Toolkit 2026 - Accounting & Tax Applications Module
# Tự động tải từ trang chủ chính thức, tự động update khi có phiên bản mới, tự cài đặt và ghi log

$script:VUONGTT_ACCOUNTING_APPS = @(
    [PSCustomObject]@{
        Id          = "htkk"
        Name        = "HTKK (Hỗ Trợ Kê Khai Thuế Mới Nhất)"
        Publisher   = "Tổng cục Thuế Việt Nam"
        HomeUrl     = "https://www.gdt.gov.vn/wps/portal/home/hotrokekhai"
        Urls        = @(
            "https://download.gdt.gov.vn/htkk/HTKK_v5.2.6.zip",
            "https://thuedientu.gdt.gov.vn/download/HTKK_Setup.zip",
            "https://dtechvn.com/download/HTKK_Setup.zip"
        )
        IsZip       = $true
        ExeName     = "setup.exe"
        SilentArgs  = "/VERYSILENT /NORESTART /SP-"
        DetectPath  = "C:\Program Files (x86)\HTKK\HTKK.exe"
    },
    [PSCustomObject]@{
        Id          = "itaxviewer"
        Name        = "iTaxViewer (Đọc Tờ Khai Thuế XML Mới Nhất)"
        Publisher   = "Tổng cục Thuế Việt Nam"
        HomeUrl     = "https://thuedientu.gdt.gov.vn"
        Urls        = @(
            "https://download.gdt.gov.vn/itaxviewer/iTaxViewer2.4.6.exe",
            "https://thuedientu.gdt.gov.vn/download/iTaxViewer_Setup.exe",
            "https://dtechvn.com/download/iTaxViewer_Setup.exe"
        )
        IsZip       = $false
        ExeName     = "iTaxViewer.exe"
        SilentArgs  = "/VERYSILENT /NORESTART /SP-"
        DetectPath  = "C:\Program Files (x86)\iTaxViewer\iTaxViewer.exe"
    },
    [PSCustomObject]@{
        Id          = "misasme"
        Name        = "MISA SME (Kế Toán Doanh Nghiệp MISA)"
        Publisher   = "Công ty Cổ phần MISA"
        HomeUrl     = "https://www.misa.vn"
        Urls        = @(
            "https://download.misa.vn/misasme/misasme.exe",
            "https://product.misa.vn/misasme/setup.exe"
        )
        IsZip       = $false
        ExeName     = "setup.exe"
        SilentArgs  = "/silent"
        DetectPath  = "C:\MISA JSC\MISA SME\Bin\MISA.exe"
    },
    [PSCustomObject]@{
        Id          = "meinvoice"
        Name        = "MISA meInvoice (Hóa Đơn Điện Tử MISA)"
        Publisher   = "Công ty Cổ phần MISA"
        HomeUrl     = "https://www.meinvoice.vn"
        Urls        = @(
            "https://download.misa.vn/meinvoice/meInvoice.exe",
            "https://product.misa.vn/meinvoice/setup.exe"
        )
        IsZip       = $false
        ExeName     = "setup.exe"
        SilentArgs  = "/silent"
        DetectPath  = "C:\Program Files (x86)\MISA JSC\meInvoice\meInvoice.exe"
    },
    [PSCustomObject]@{
        Id          = "kbhxh"
        Name        = "KBHXH (Kê Khai Bảo Hiểm Xã Hội Điện Tử)"
        Publisher   = "Bảo hiểm Xã hội Việt Nam"
        HomeUrl     = "https://gddt.baohiemxahoi.gov.vn"
        Urls        = @(
            "https://gddt.baohiemxahoi.gov.vn/Download/KBHXH_Setup.exe",
            "https://baohiemxahoi.gov.vn/download/KBHXH_Setup.exe"
        )
        IsZip       = $false
        ExeName     = "KBHXH_Setup.exe"
        SilentArgs  = "/VERYSILENT /NORESTART"
        DetectPath  = "C:\Program Files (x86)\TSD\KBHXH\KBHXH.exe"
    },
    [PSCustomObject]@{
        Id          = "javatax"
        Name        = "Java Token JRE (Môi Trường Ký Số Thuế Điện Tử)"
        Publisher   = "Oracle Corporation / Tax Portal"
        HomeUrl     = "https://www.java.com"
        WingetId    = "Oracle.JavaRuntimeEnvironment"
        Urls        = @(
            "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=249553_4d245f9418eb4ec4978736adb133d549"
        )
        IsZip       = $false
        ExeName     = "jre_setup.exe"
        SilentArgs  = "/s"
        DetectPath  = "C:\Program Files (x86)\Java\jre*\bin\java.exe"
    },
    [PSCustomObject]@{
        Id          = "dvcplugin"
        Name        = "Plugin Ký Số Cổng Dịch Vụ Công Quốc Gia"
        Publisher   = "Cổng Dịch Vụ Công Quốc Gia (dichvucong.gov.vn)"
        HomeUrl     = "https://dichvucong.gov.vn"
        Urls        = @(
            "https://dichvucong.gov.vn/pki/VNPT_Plugin.exe"
        )
        IsZip       = $false
        ExeName     = "VNPT_Plugin.exe"
        SilentArgs  = "/VERYSILENT /NORESTART /SP-"
        DetectPath  = "C:\Program Files (x86)\VNPT\VNPT Plugin\VNPT_Plugin.exe"
    },
    [PSCustomObject]@{
        Id          = "vietteltoken"
        Name        = "Viettel-CA Token Manager v2 (Ký Số Nhà Nước & Thuế)"
        Publisher   = "Tập đoàn Viễn thông Quân đội (Viettel)"
        HomeUrl     = "https://viettel-ca.vn"
        Urls        = @(
            "https://viettel-ca.vn/download/Viettel-CA_v2_setup.exe",
            "https://viettel-ca.vn/download/viettel-ca_v2.exe"
        )
        IsZip       = $false
        ExeName     = "Viettel-CA_v2_setup.exe"
        SilentArgs  = "/S"
        DetectPath  = "C:\Program Files (x86)\Viettel-CA\Viettel-CA Token Manager v2\Viettel-CA_v2.exe"
    },
    [PSCustomObject]@{
        Id          = "vnpttoken"
        Name        = "VNPT-CA Token Manager AN (Ký Số Thuế, BHXH, DVC)"
        Publisher   = "Tập đoàn Bưu chính Viễn thông Việt Nam (VNPT)"
        HomeUrl     = "https://vnpt-ca.vn"
        Urls        = @(
            "https://vnpt-ca.vn:443/documents/download?fileNameDownload=documents/15012026160533.exe",
            "https://vnpt-ca.vn/download/VNPT-CA_Plugin.exe"
        )
        IsZip       = $false
        ExeName     = "VNPT_Token_Manager_Setup.exe"
        SilentArgs  = "/S"
        DetectPath  = "C:\Program Files (x86)\VNPT-CA\VNPT-CA Token Manager\vnpt-ca_cl.exe"
    },
    [PSCustomObject]@{
        Id          = "misakyso"
        Name        = "MISA Ký Số (Hóa Đơn, Thuế & Dịch Vụ Công)"
        Publisher   = "Công ty Cổ phần MISA"
        HomeUrl     = "https://esign.misa.vn"
        Urls        = @(
            "https://product.misa.vn/misasoftware/MISAKyso/MISA.KySo_Setup_latest.exe",
            "https://product.misa.com.vn/misasoftware/misaca/remote/misa_esign_setup.exe"
        )
        IsZip       = $false
        ExeName     = "MISA.KySo_Setup_latest.exe"
        SilentArgs  = "/silent"
        DetectPath  = "C:\Program Files (x86)\MISA JSC\MISA KySo\MISA.KySo.exe"
    },
    [PSCustomObject]@{
        Id          = "esigner"
        Name        = "eSigner TCT (Ký Số Thuế Điện Tử Tổng Cục Thuế)"
        Publisher   = "Tổng cục Thuế Việt Nam"
        HomeUrl     = "https://thuedientu.gdt.gov.vn"
        Urls        = @(
            "https://thuedientu.gdt.gov.vn/download/eSigner_1.0.8_setup.exe",
            "https://thuedientu.gdt.gov.vn"
        )
        IsZip       = $false
        ExeName     = "eSigner_setup.exe"
        SilentArgs  = "/VERYSILENT /NORESTART /SP-"
        DetectPath  = "C:\Program Files (x86)\eSigner\eSigner.exe"
    }
)

function Get-VUONGTTAccountingApps {
    return $script:VUONGTT_ACCOUNTING_APPS
}

# Tim link tai truc tiep tu may chu chinh hang
function Get-VUONGTTActiveAccountingUrl {
    param($App)

    if ($App -is [string]) {
        $id = $App
        $App = $script:VUONGTT_ACCOUNTING_APPS | Where-Object { $_.Id -eq $id }
    }
    if (-not $App) { return $null }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    if (-not $App.Urls -or $App.Urls.Count -eq 0) {
        return $App.HomeUrl
    }

    foreach ($u in $App.Urls) {
        try {
            $req = [System.Net.HttpWebRequest]::Create($u)
            $req.Method = "HEAD"
            $req.Timeout = 3000
            $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) VUONGTT-Toolkit/2026"
            $resp = $req.GetResponse()
            if ($resp.StatusCode -eq [System.Net.HttpStatusCode]::OK -or $resp.StatusCode -eq [System.Net.HttpStatusCode]::Found) {
                $resp.Close()
                return $u
            }
            $resp.Close()
        } catch {
            # Thu URL tiep theo
        }
    }
    # Tra ve URL mac dinh cua nha phat hanh
    return $App.Urls[0]
}

function Invoke-VUONGTTDownloadWithLog {
    param(
        [string]$Url,
        [string]$DestPath,
        [scriptblock]$OnProgress = $null
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    $tempDir = [System.IO.Path]::GetDirectoryName($DestPath)
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

    if ($OnProgress) { & $OnProgress "  -> Đang kết nối tới máy chủ chính hãng: $Url..." }

    try {
        $client = New-Object System.Net.WebClient
        $client.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36")
        
        $script:VUONGTT_DlPct = 0
        $script:VUONGTT_DlBytes = 0
        $script:VUONGTT_DlTotal = 0
        $script:VUONGTT_DlCompleted = $false
        $script:VUONGTT_DlError = $null

        Register-ObjectEvent -InputObject $client -EventName "DownloadProgressChanged" -Action {
            $script:VUONGTT_DlPct = $EventArgs.ProgressPercentage
            $script:VUONGTT_DlBytes = $EventArgs.BytesReceived
            $script:VUONGTT_DlTotal = $EventArgs.TotalBytesToReceive
        } | Out-Null

        Register-ObjectEvent -InputObject $client -EventName "DownloadFileCompleted" -Action {
            $script:VUONGTT_DlCompleted = $true
            if ($EventArgs.Error) { $script:VUONGTT_DlError = $EventArgs.Error }
        } | Out-Null

        $client.DownloadFileAsync((New-Object System.Uri($Url)), $DestPath)

        $lastReport = 0
        $lastMb = 0
        while (-not $script:VUONGTT_DlCompleted) {
            Start-Sleep -Milliseconds 60
            if (Get-Command Invoke-VUONGTTDoEvents -ErrorAction SilentlyContinue) {
                Invoke-VUONGTTDoEvents
            }
            $now = [Environment]::TickCount
            if ($now - $lastReport -ge 1500) {
                $lastReport = $now
                $mbRecv = [math]::Round($script:VUONGTT_DlBytes / 1MB, 1)
                if ($script:VUONGTT_DlTotal -gt 0) {
                    $mbTot = [math]::Round($script:VUONGTT_DlTotal / 1MB, 1)
                    if ($OnProgress -and $mbRecv -ne $lastMb) {
                        & $OnProgress "  -> [Đang tải] $mbRecv MB / $mbTot MB ($($script:VUONGTT_DlPct)%)..."
                        $lastMb = $mbRecv
                    }
                } elseif ($mbRecv -gt 0 -and $mbRecv -ne $lastMb) {
                    if ($OnProgress) {
                        & $OnProgress "  -> [Đang tải] $mbRecv MB..."
                        $lastMb = $mbRecv
                    }
                }
            }
        }

        Get-EventSubscriber | Where-Object { $_.SourceObject -eq $client } | Unregister-Event -Force -ErrorAction SilentlyContinue
        $client.Dispose()

        if ($script:VUONGTT_DlError) {
            throw $script:VUONGTT_DlError
        }
        
        if (Test-Path $DestPath) {
            $len = (Get-Item $DestPath).Length
            $mb = [math]::Round($len / 1MB, 2)
            if ($OnProgress) { & $OnProgress "  -> [OK] Tải về thành công! Kích thước: $mb MB." }
            return $true
        }
        return $false
    } catch {
        if ($OnProgress) { & $OnProgress "  -> [CHÚ Ý] Lỗi khi tải trực tiếp: $($_.Exception.Message)" }
        # Fallback qua Invoke-WebRequest
        try {
            Invoke-WebRequest -Uri $Url -OutFile $DestPath -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36" -TimeoutSec 45
            return (Test-Path $DestPath)
        } catch {
            return $false
        }
    }
}

function Install-VUONGTTAccountingApp {
    param(
        [string]$AppId,
        [scriptblock]$OnProgress = $null,
        [switch]$AutoLaunch = $true
    )

    $app = $script:VUONGTT_ACCOUNTING_APPS | Where-Object { $_.Id -eq $AppId }
    if (-not $app) { return "[LỖI] Không tìm thấy phần mềm kế toán mã: $AppId" }

    $timestamp = (Get-Date).ToString("HH:mm:ss")
    if ($OnProgress) { & $OnProgress "[$timestamp] [BẮT ĐẦU XỬ LÝ] $($app.Name)" }
    if ($OnProgress) { & $OnProgress "  -> Nhà phát hành: $($app.Publisher)" }
    if ($OnProgress) { & $OnProgress "  -> Trang chủ chính thức: $($app.HomeUrl)" }

    # Kiem tra ho tro Winget cho Java
    if ($app.WingetId) {
        $hasWinget = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($hasWinget) {
            if ($OnProgress) { & $OnProgress "  -> Đang kiểm tra và cập nhật phiên bản mới nhất qua Winget ($($app.WingetId))..." }
            try {
                $arg = "install --id `"$($app.WingetId)`" -e --silent --accept-package-agreements --accept-source-agreements --force"
                $exitCode = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
                    Start-VUONGTTProcessResponsive -FilePath "winget.exe" -ArgumentList $arg -TimeoutSeconds 600 -NoNewWindow $true
                } else {
                    $p = Start-Process -FilePath "winget.exe" -ArgumentList $arg -Wait -PassThru -NoNewWindow
                    $p.ExitCode
                }
                $wingetOkCodes = @(0, -1978335189, -1978335215, -1978335188, 3010, 1641, 2316632065)
                if ($exitCode -in $wingetOkCodes) {
                    if ($OnProgress) { & $OnProgress "  -> [THÀNH CÔNG] Đã cài đặt/cập nhật $($app.Name) qua Winget!" }
                    if ($AutoLaunch -and (Get-Command Start-VUONGTTInstalledApp -ErrorAction SilentlyContinue)) {
                        Start-VUONGTTInstalledApp -AppId $app.Id -HintName $app.Name -OnLog $OnProgress
                    }
                    return "[OK] Cài đặt $($app.Name) hoàn tất 100%!"
                }
            } catch {}
        }
    }

    # Lay link truc tiep tu may chu chinh hang
    if ($OnProgress) { & $OnProgress "  -> Đang kiểm tra liên kết tải gói cài đặt mới nhất..." }
    $activeUrl = Get-VUONGTTActiveAccountingUrl -App $app
    if ($OnProgress) { & $OnProgress "  -> Tìm thấy máy chủ cung cấp: $activeUrl" }

    $destFolder = "$env:TEMP\VUONGTT_AccountingApps"
    $ext = if ($app.IsZip) { ".zip" } else { ".exe" }
    $destFile = Join-Path $destFolder "$($app.Id)_setup$ext"

    $dlSuccess = Invoke-VUONGTTDownloadWithLog -Url $activeUrl -DestPath $destFile -OnProgress $OnProgress
    if (-not $dlSuccess -or -not (Test-Path $destFile)) {
        if ($OnProgress) { & $OnProgress "  -> [CHUYỂN HƯỚNG] Máy chủ yêu cầu xác thực hoặc giới hạn tải trực tiếp. Đang tự động mở cổng chính thức..." }
        try {
            Start-Process $app.HomeUrl
        } catch {}
        return "[CHÚ Ý] Đã mở trang chủ chính thức ($($app.HomeUrl)) để tải bản mới nhất $($app.Name)!"
    }

    # Giai nen hoac Cai dat
    if ($app.IsZip) {
        $extractDir = Join-Path $destFolder $app.Id
        if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }
        if ($OnProgress) { & $OnProgress "  -> Đang giải nén gói cài đặt $($app.Name)..." }
        try {
            Expand-Archive -Path $destFile -DestinationPath $extractDir -Force
            if ($OnProgress) { & $OnProgress "  -> [OK] Giải nén thành công." }

            # Tim setup.exe trong thu muc giai nen
            $setupExe = Get-ChildItem -Path $extractDir -Filter "Setup.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($setupExe) {
                if ($OnProgress) { & $OnProgress "  -> Đang khởi chạy trình cài đặt tự động: $($setupExe.FullName)..." }
                $exitCode = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
                    Start-VUONGTTProcessResponsive -FilePath $setupExe.FullName -ArgumentList $app.SilentArgs -TimeoutSeconds 900 -NoNewWindow $true
                } else {
                    $p = Start-Process -FilePath $setupExe.FullName -ArgumentList $app.SilentArgs -Wait -PassThru -NoNewWindow
                    $p.ExitCode
                }
                if ($OnProgress) { & $OnProgress "  -> [THÀNH CÔNG] Quá trình cài đặt $($app.Name) đã hoàn tất!" }
                if ($AutoLaunch -and (Get-Command Start-VUONGTTInstalledApp -ErrorAction SilentlyContinue)) {
                    Start-VUONGTTInstalledApp -AppId $app.Id -HintName $app.Name -OnLog $OnProgress
                }
                return "[OK] Đã hoàn tất cài đặt $($app.Name) phiên bản mới nhất!"
            } else {
                Start-Process "explorer.exe" -ArgumentList "`"$extractDir`""
                return "[OK] Đã giải nén bộ cài $($app.Name) vào: $extractDir"
            }
        } catch {
            return "[LỖI GIẢI NÉN / CÀI ĐẶT] $($_.Exception.Message)"
        }
    } else {
        if ($OnProgress) { & $OnProgress "  -> Đang tự động cài đặt ngầm $($app.Name) với tham số '$($app.SilentArgs)'..." }
        try {
            $exitCode = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
                Start-VUONGTTProcessResponsive -FilePath $destFile -ArgumentList $app.SilentArgs -TimeoutSeconds 900 -NoNewWindow $false
            } else {
                $p = Start-Process -FilePath $destFile -ArgumentList $app.SilentArgs -Wait -PassThru
                $p.ExitCode
            }
            if ($OnProgress) { & $OnProgress "  -> [THÀNH CÔNG] Cài đặt $($app.Name) hoàn tất với mã trả về: $exitCode!" }
            if ($AutoLaunch -and (Get-Command Start-VUONGTTInstalledApp -ErrorAction SilentlyContinue)) {
                Start-VUONGTTInstalledApp -AppId $app.Id -HintName $app.Name -OnLog $OnProgress
            }
            return "[OK] Đã hoàn tất cài đặt $($app.Name) phiên bản mới nhất từ trang chủ!"
        } catch {
            return "[LỖI KHỞI CHẠY BỘ CÀI] $($_.Exception.Message)"
        }
    }
}

function Update-VUONGTTAccountingApps {
    param(
        [string[]]$AppIds = @(),
        [string[]]$AppsToUpdate = @(),
        [scriptblock]$OnProgress = $null
    )

    if ($AppsToUpdate.Count -gt 0 -and $AppIds.Count -eq 0) {
        $AppIds = $AppsToUpdate
    }

    $targetApps = if ($AppIds.Count -gt 0) {
        $script:VUONGTT_ACCOUNTING_APPS | Where-Object { $AppIds -contains $_.Id }
    } else {
        $script:VUONGTT_ACCOUNTING_APPS
    }

    $timestamp = (Get-Date).ToString("HH:mm:ss")
    if ($OnProgress) { & $OnProgress "[$timestamp] [BẮT ĐẦU KIỂM TRA VÀ CẬP NHẬT $($targetApps.Count) PHẦN MỀM KẾ TOÁN]" }

    $results = @()
    foreach ($app in $targetApps) {
        if ($OnProgress) { & $OnProgress "`n--- ĐANG KIỂM TRA PHIÊN BẢN MỚI CHO: $($app.Name) ---" }
        $res = Install-VUONGTTAccountingApp -AppId $app.Id -OnProgress $OnProgress
        $results += "$($app.Name): $res"
    }

    if ($OnProgress) { & $OnProgress "`n[HOÀN TẤT TOÀN BỘ] Đã kiểm tra và nâng cấp các phần mềm kế toán lên bản mới nhất!" }
    return ($results -join "`n")
}
