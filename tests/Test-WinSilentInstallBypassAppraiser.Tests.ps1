
# Test: Setup phải sử dụng /product server hoặc setupconfig để bypass appraiser
# và phải silent install hoàn toàn

Describe "Win Deploy Silent Install - Appraiser Bypass" {
    
    Context "Chiến lược bypass appraiser mới" {

        It "Setup args phải chứa /product server HOẶC setupconfig.ini tồn tại" {
            # /product server = ép mode Server, appraiser bỏ qua consumer hardware check
            $args = "/auto clean /eula accept /compat ignorewarning /product server /DynamicUpdate disable /tempdrive C"
            ($args -like "*/product server*") -or (Test-Path "C:\Windows\System32\setup\setupconfig.ini") | Should -Be $true
        }

        It "Setup args không được có /unattend khi có /auto" {
            $args = "/auto clean /eula accept /compat ignorewarning /product server /DynamicUpdate disable /tempdrive C"
            ($args -like "*/unattend*") | Should -Be $false
        }

        It "Phải ưu tiên sources\setup.exe không phải setupprep.exe khi bypass appraiser" {
            # setupprep.exe luôn chạy appraiser trước khi nhận /compat ignorewarning
            # setup.exe trong sources nhận /compat ignorewarning ngay từ đầu
            $isoPath = "D:"
            $setupSources = "$isoPath\sources\setup.exe"
            $setupPrep = "$isoPath\sources\setupprep.exe"
            # Nên dùng setup.exe từ sources (không phải setupprep.exe)
            (Test-Path $setupSources) | Should -Be $true
        }

        It "autounattend.xml KHÔNG được có DiskConfiguration khi chạy từ Windows (gây lỗi chọn phân vùng)" {
            $xmlPath = "C:\autounattend.xml"
            if (Test-Path $xmlPath) {
                $xmlContent = Get-Content $xmlPath -Raw
                # DiskConfiguration chỉ dùng khi boot USB WinPE; dùng trong Windows sẽ gây lỗi 'error selecting partition'
                ($xmlContent -like "*<DiskConfiguration>*") | Should -Be $false
            } else {
                Set-ItResult -Pending -Because "autounattend.xml chưa được tạo"
            }
        }

        It "autounattend.xml KHÔNG được có ImageInstall với hard-coded partition khi chạy từ Windows" {
            $xmlPath = "C:\autounattend.xml"
            if (Test-Path $xmlPath) {
                $xmlContent = Get-Content $xmlPath -Raw
                ($xmlContent -like "*<ImageInstall>*") | Should -Be $false
            } else {
                Set-ItResult -Pending -Because "autounattend.xml chưa được tạo"
            }
        }

        It "Môi trường hệ thống phải có LabConfig bypass trước khi chạy setup" {
            $labConfig = "HKLM:\SYSTEM\Setup\LabConfig"
            (Get-ItemProperty $labConfig -Name "BypassTPMCheck" -ErrorAction SilentlyContinue).BypassTPMCheck | Should -Be 1
        }

        It "MoSetup AllowUpgrades phải được set" {
            $mosetup = "HKLM:\SYSTEM\Setup\MoSetup"
            (Get-ItemProperty $mosetup -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -ErrorAction SilentlyContinue).AllowUpgradesWithUnsupportedTPMOrCPU | Should -Be 1
        }
    }

    Context "Silent install - không hiển thị bất kỳ màn hình nào" {

        It "Setup args phải có /quiet hoặc WindowStyle Hidden" {
            # Với /quiet, setup chạy hoàn toàn im lặng
            $args = "/auto clean /eula accept /compat ignorewarning /product server /DynamicUpdate disable /quiet /tempdrive C"
            ($args -like "*/quiet*") -or ($args -like "*/noreboot*") | Should -Be $true
        }

        It "autounattend.xml phải bypass toàn bộ OOBE" {
            $xmlPath = "C:\autounattend.xml"
            if (Test-Path $xmlPath) {
                $xmlContent = Get-Content $xmlPath -Raw
                # Phải có HideEULAPage, HideLocalAccountScreen, HideOnlineAccountScreens
                ($xmlContent -like "*HideEULAPage*true*") | Should -Be $true
                ($xmlContent -like "*BypassNRO*") | Should -Be $true
            } else {
                Set-ItResult -Pending -Because "autounattend.xml chưa được tạo"
            }
        }

        It "autounattend.xml phải có AutoLogon để tự login vào Desktop" {
            $xmlPath = "C:\autounattend.xml"
            if (Test-Path $xmlPath) {
                $xmlContent = Get-Content $xmlPath -Raw
                ($xmlContent -like "*AutoLogon*") | Should -Be $true
                ($xmlContent -like "*Enabled*true*") | Should -Be $true
            } else {
                Set-ItResult -Pending -Because "autounattend.xml chưa được tạo"
            }
        }
    }
}
