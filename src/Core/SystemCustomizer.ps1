# VUONGTT Toolkit 2026 - System & OEM Customizer Module

function Get-SystemCustomizerInfo {
    [CmdletBinding()]
    param()

    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue

    # Registry Windows NT CurrentVersion
    $winNtReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $regOwner = ""
    $regOrg = ""
    if (Test-Path $winNtReg) {
        $regOwner = (Get-ItemProperty -Path $winNtReg -Name "RegisteredOwner" -ErrorAction SilentlyContinue).RegisteredOwner
        $regOrg   = (Get-ItemProperty -Path $winNtReg -Name "RegisteredOrganization" -ErrorAction SilentlyContinue).RegisteredOrganization
    }

    # OEM Information in System Properties
    $oemReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
    $oemManufacturer = ""
    $oemModel        = ""
    $oemSupportPhone = ""
    $oemSupportURL   = ""
    $oemLogo         = ""

    if (Test-Path $oemReg) {
        $props = Get-ItemProperty -Path $oemReg -ErrorAction SilentlyContinue
        if ($props) {
            $oemManufacturer = $props.Manufacturer
            $oemModel        = $props.Model
            $oemSupportPhone = $props.SupportPhone
            $oemSupportURL   = $props.SupportURL
            $oemLogo         = $props.Logo
        }
    }

    # Computer Description
    $srvReg = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    $srvDesc = ""
    if (Test-Path $srvReg) {
        $srvDesc = (Get-ItemProperty -Path $srvReg -Name "srvcomment" -ErrorAction SilentlyContinue).srvcomment
    }

    return [PSCustomObject]@{
        ComputerName         = $cs.Name
        Workgroup            = $cs.Workgroup
        ComputerDescription  = $srvDesc
        RegisteredOwner      = $regOwner
        RegisteredOrganization = $regOrg
        Manufacturer         = $oemManufacturer
        Model                = $oemModel
        SupportPhone         = $oemSupportPhone
        SupportURL           = $oemSupportURL
        Logo                 = $oemLogo
    }
}

function Set-SystemCustomizerInfo {
    param(
        [string]$ComputerName,
        [string]$Workgroup,
        [string]$ComputerDescription,
        [string]$RegisteredOwner,
        [string]$RegisteredOrganization,
        [string]$Manufacturer,
        [string]$Model,
        [string]$SupportPhone,
        [string]$SupportURL,
        [string]$LogoPath = ""
    )

    $log = @()

    try {
        # 1. RegisteredOwner & RegisteredOrganization
        $winNtReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        if (Test-Path $winNtReg) {
            if (-not [string]::IsNullOrEmpty($RegisteredOwner)) {
                Set-ItemProperty -Path $winNtReg -Name "RegisteredOwner" -Value $RegisteredOwner -Force
                $log += "[OK] Cập nhật Chủ sở hữu Windows: $RegisteredOwner"
            }
            if (-not [string]::IsNullOrEmpty($RegisteredOrganization)) {
                Set-ItemProperty -Path $winNtReg -Name "RegisteredOrganization" -Value $RegisteredOrganization -Force
                $log += "[OK] Cập nhật Tổ chức: $RegisteredOrganization"
            }
        }

        # 2. OEM Information
        $oemReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
        if (-not (Test-Path $oemReg)) { New-Item -Path $oemReg -Force | Out-Null }

        if (-not [string]::IsNullOrEmpty($Manufacturer)) {
            Set-ItemProperty -Path $oemReg -Name "Manufacturer" -Value $Manufacturer -Force
            $log += "[OK] Cập nhật Hãng OEM: $Manufacturer"
        }
        if (-not [string]::IsNullOrEmpty($Model)) {
            Set-ItemProperty -Path $oemReg -Name "Model" -Value $Model -Force
            $log += "[OK] Cập nhật Model OEM: $Model"
        }
        if (-not [string]::IsNullOrEmpty($SupportPhone)) {
            Set-ItemProperty -Path $oemReg -Name "SupportPhone" -Value $SupportPhone -Force
            $log += "[OK] Cập nhật Điện thoại hỗ trợ: $SupportPhone"
        }
        if (-not [string]::IsNullOrEmpty($SupportURL)) {
            Set-ItemProperty -Path $oemReg -Name "SupportURL" -Value $SupportURL -Force
            $log += "[OK] Cập nhật Link hỗ trợ: $SupportURL"
        }
        if (-not [string]::IsNullOrEmpty($LogoPath) -and (Test-Path $LogoPath)) {
            Set-ItemProperty -Path $oemReg -Name "Logo" -Value $LogoPath -Force
            $log += "[OK] Cập nhật OEM Logo: $LogoPath"
        }

        # 3. Computer Description
        if (-not [string]::IsNullOrEmpty($ComputerDescription)) {
            $srvReg = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
            if (-not (Test-Path $srvReg)) { New-Item -Path $srvReg -Force | Out-Null }
            Set-ItemProperty -Path $srvReg -Name "srvcomment" -Value $ComputerDescription -Force
            $log += "[OK] Cập nhật Mô tả máy: $ComputerDescription"
        }

        # 4. Computer Name & Workgroup (If changed)
        if (-not [string]::IsNullOrEmpty($ComputerName) -and $ComputerName -ne $env:COMPUTERNAME) {
            try {
                Rename-Computer -NewName $ComputerName -Force -ErrorAction Stop
                $log += "[OK] Đã đổi tên máy tính sang: $ComputerName (Sẽ có hiệu lực sau khi khởi động lại)."
            } catch {
                $log += "[CẢNH BÁO] Không thể đổi tên máy ngay: $($_.Exception.Message)"
            }
        }

        if (-not [string]::IsNullOrEmpty($Workgroup)) {
            try {
                Add-Computer -WorkGroupName $Workgroup -ErrorAction SilentlyContinue
                $log += "[OK] Cập nhật Workgroup: $Workgroup"
            } catch {}
        }

        $log += "=== Hoàn tất áp dụng tùy chỉnh thông tin thiết bị! ==="
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }

    return ($log -join "`n")
}

function Backup-SystemCustomizerInfo {
    param([string]$FilePath = "$env:TEMP\VUONGTT_SystemInfo_Backup.json")
    try {
        $info = Get-SystemCustomizerInfo
        $json = $info | ConvertTo-Json -Depth 4
        $json | Set-Content -Path $FilePath -Encoding UTF8 -Force
        return "Đã sao lưu thông tin cấu hình vào: $FilePath"
    } catch {
        return "Lỗi khi sao lưu: $($_.Exception.Message)"
    }
}

function Restore-SystemCustomizerInfo {
    param([string]$FilePath = "$env:TEMP\VUONGTT_SystemInfo_Backup.json")
    if (-not (Test-Path $FilePath)) {
        return "Không tìm thấy file sao lưu tại: $FilePath"
    }
    try {
        $json = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $obj = $json | ConvertFrom-Json
        $res = Set-SystemCustomizerInfo -ComputerName $obj.ComputerName `
                                        -Workgroup $obj.Workgroup `
                                        -ComputerDescription $obj.ComputerDescription `
                                        -RegisteredOwner $obj.RegisteredOwner `
                                        -RegisteredOrganization $obj.RegisteredOrganization `
                                        -Manufacturer $obj.Manufacturer `
                                        -Model $obj.Model `
                                        -SupportPhone $obj.SupportPhone `
                                        -SupportURL $obj.SupportURL `
                                        -LogoPath $obj.Logo
        return "Đã khôi phục thành công cấu hình từ bản sao lưu!`n$res"
    } catch {
        return "Lỗi khi khôi phục: $($_.Exception.Message)"
    }
}

function Invoke-VUONGTTRenameComputer {
    param(
        [string]$NewName,
        [string]$DomainName = "",
        [string]$DomainUser = "",
        [string]$DomainPassword = "",
        [System.Management.Automation.PSCredential]$Credential = $null
    )
    if ([string]::IsNullOrWhiteSpace($NewName)) {
        return @{ Success = $false; Message = "Tên máy tính không được để trống!" }
    }
    $cleanName = $NewName.Trim()
    if ($cleanName.Length -gt 15) {
        return @{ Success = $false; Message = "Tên máy tính không được vượt quá 15 ký tự theo chuẩn Windows NetBIOS!" }
    }
    if ($cleanName -match '[\/\\:\*\?"<>\|]') {
        return @{ Success = $false; Message = "Tên máy tính không được chứa các ký tự đặc biệt: \ / : * ? `" < > |" }
    }
    if ($cleanName -eq $env:COMPUTERNAME) {
        return @{ Success = $true; Message = "Tên máy tính hiện tại đã là '$cleanName'." }
    }

    # 1. Chuẩn bị Credential nếu có
    $targetCred = $Credential
    if (-not $targetCred -and -not [string]::IsNullOrWhiteSpace($DomainUser)) {
        try {
            $formattedUser = $DomainUser.Trim()
            if (-not [string]::IsNullOrWhiteSpace($DomainName) -and $formattedUser -notmatch '[\@\\]') {
                $formattedUser = "$($DomainName.Trim())\$formattedUser"
            }
            $secPass = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
            $targetCred = New-Object System.Management.Automation.PSCredential($formattedUser, $secPass)
        } catch {
            $targetCred = $null
        }
    }

    # 2. Kiểm tra máy có đang thuộc Domain không
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
    $isPartOfDomain = if ($cs) { [bool]$cs.PartOfDomain } else { $false }

    try {
        if ($targetCred) {
            # Khi có credential, truyền vào -DomainCredential
            Rename-Computer -NewName $cleanName -DomainCredential $targetCred -Force -ErrorAction Stop
        } elseif ($isPartOfDomain) {
            # Máy thuộc domain nhưng chưa có credential -> thử lệnh chuẩn, nếu lỗi sẽ catch và hướng dẫn
            Rename-Computer -NewName $cleanName -Force -ErrorAction Stop
        } else {
            # Máy Workgroup thông thường
            Rename-Computer -NewName $cleanName -Force -ErrorAction Stop
        }

        return @{
            Success = $true
            Message = "ĐÃ ĐỔI TÊN MÁY TÍNH THÀNH CÔNG SANG: $cleanName`n(Lưu ý: Tên mới sẽ có hiệu lực sau khi bạn khởi động lại máy tính)."
        }
    } catch {
        $errMsg = $_.Exception.Message
        $helpNote = ""
        if ($errMsg -match 'user name or password' -or $errMsg -match 'Access is denied' -or $errMsg -match 'credential' -or $isPartOfDomain) {
            $helpNote = "`n`n💡 GỢI Ý KHẮC PHỤC:`n1. Máy tính này đang thuộc mạng Domain (Active Directory). Để đổi tên máy, bạn cần nhập tài khoản Domain Admin (ví dụ: Administrator hoặc TênDomain\UserAdmin) và mật khẩu chính xác.`n2. Bạn có thể bấm nút '🌐 Hộp Thoại Windows' phía trên để đổi tên máy trực tiếp bằng giao diện gốc của Windows (SystemPropertiesComputerName.exe hoặc sysdm.cpl).`n3. Kiểm tra kết nối mạng LAN/Wi-Fi tới máy chủ Domain Controller."
        }
        return @{
            Success = $false
            Message = "Lỗi khi đổi tên máy tính: $errMsg$helpNote"
        }
    }
}

function Invoke-VUONGTTJoinDomain {
    param(
        [string]$DomainName,
        [string]$DomainUser,
        [string]$DomainPassword
    )

    if ([string]::IsNullOrWhiteSpace($DomainName)) {
        return @{ Success = $false; Message = "Vui lòng nhập tên Domain (ví dụ: company.local)!" }
    }
    if ([string]::IsNullOrWhiteSpace($DomainUser)) {
        return @{ Success = $false; Message = "Vui lòng nhập tài khoản quản trị Domain (Domain Admin)!" }
    }

    try {
        $secPass = ConvertTo-SecureString $DomainPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($DomainUser, $secPass)

        Add-Computer -DomainName $DomainName.Trim() -Credential $cred -Force -Restart:$false -ErrorAction Stop
        return @{
            Success = $true
            Message = "CHÚC MỪNG! ĐÃ GIA NHẬP DOMAIN '$DomainName' THÀNH CÔNG!`n`nMáy tính đã trở thành thành viên của Domain. Hãy khởi động lại máy để áp dụng chính sách Active Directory."
        }
    } catch {
        return @{
            Success = $false
            Message = "Không thể gia nhập Domain '$DomainName':`n$($_.Exception.Message)`n`nGợi ý kiểm tra:`n1. Máy tính đã trỏ đúng DNS Server của Domain Controller chưa?`n2. Tài khoản và mật khẩu Domain Admin đã chính xác chưa?`n3. Kiểm tra kết nối mạng nội bộ LAN tới máy chủ DC."
        }
    }
}

function Invoke-VUONGTTJoinWorkgroup {
    param([string]$WorkgroupName)
    if ([string]::IsNullOrWhiteSpace($WorkgroupName)) { $WorkgroupName = "WORKGROUP" }
    try {
        Add-Computer -WorkGroupName $WorkgroupName.Trim() -Force -ErrorAction Stop
        return @{
            Success = $true
            Message = "Đã chuyển máy tính về Workgroup '$WorkgroupName' thành công!`n(Có hiệu lực sau khi khởi động lại)."
        }
    } catch {
        return @{
            Success = $false
            Message = "Lỗi khi thiết lập Workgroup: $($_.Exception.Message)"
        }
    }
}

function Open-VUONGTTSystemPropertiesComputerNameDialog {
    try {
        Start-Process "SystemPropertiesComputerName.exe" -ErrorAction SilentlyContinue
        return $true
    } catch {
        try {
            Start-Process "control.exe" -ArgumentList "sysdm.cpl,,1" -ErrorAction SilentlyContinue
            return $true
        } catch {
            return $false
        }
    }
}

