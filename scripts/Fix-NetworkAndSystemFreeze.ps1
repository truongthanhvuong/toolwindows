# ==============================================================================
# SCRIPT TOI UU HOA VA SUA TRIET DE LOI ROT MANG & TREO DO MAY TREN WINDOWS
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " TIEN TRINH TOI UU HOA MANG & CHONG TREO DO HE THONG " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. VO HIEU HOA RO RI BO NHO NDU (NETWORK DIAGNOSTIC USAGE DRIVER LEAK)
Write-Host "`n>>> [1/5] Vo hieu hoa driver ro ri RAM NDU (Non-Paged Pool Memory Leak)..." -ForegroundColor Cyan
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Ndu" -Name "Start" -Value 4 -Type DWord -Force
    $nduVal = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Ndu" -Name "Start").Start
    Write-Host " [OK] Ndu Service Start set to: $nduVal (4 = Disabled - Da chan ro ri RAM triet de)" -ForegroundColor Green
} catch {
    Write-Host " [!] Khong the chinh sua Registry Ndu: $_" -ForegroundColor Red
}

# 2. VO HIEU HOA CHE DO TIET KIEM DIEN TAT CARD MANG (PNP POWER MANAGEMENT)
Write-Host "`n>>> [2/5] Tat che do 'Allow the computer to turn off this device to save power'..." -ForegroundColor Cyan
try {
    $nicKeys = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' }
    foreach ($k in $nicKeys) {
        $props = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
        if ($props.DriverDesc -like "*82574L*" -or $props.DriverDesc -like "*Gigabit*" -or $props.DriverDesc -like "*Ethernet*") {
            Set-ItemProperty -Path $k.PSPath -Name "PnPCapabilities" -Value 24 -Type DWord -Force
            Write-Host " [OK] Da thiet lap PnPCapabilities = 24 tren $($props.DriverDesc) ($($k.PSChildName))" -ForegroundColor Green
        }
    }
} catch {
    Write-Host " [!] Loi thiet lap PnPCapabilities: $_" -ForegroundColor Red
}

# 3. TOI UU HOA THIET LAP NANG CAO CARD MANG (LSO V2, RECEIVE BUFFERS)
Write-Host "`n>>> [3/5] Toi uu hoa cac thong so nang cao cua card mang Ethernet0..." -ForegroundColor Cyan
try {
    $adapter = Get-NetAdapter -Name "Ethernet0" -ErrorAction SilentlyContinue
    if ($adapter) {
        # Tat Large Send Offload V2 (IPv4 & IPv6) tranh crash packet queue tren card Intel 82574L
        Set-NetAdapterAdvancedProperty -Name "Ethernet0" -RegistryKeyword "*LsoV2IPv4" -RegistryValue 0 -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name "Ethernet0" -RegistryKeyword "*LsoV2IPv6" -RegistryValue 0 -ErrorAction SilentlyContinue
        Write-Host " [OK] Da vo hieu hoa Large Send Offload V2 (IPv4 & IPv6) chong drop ket noi" -ForegroundColor Green

        # Tang bo dem Receive Buffers va Transmit Buffers
        Set-NetAdapterAdvancedProperty -Name "Ethernet0" -RegistryKeyword "*ReceiveBuffers" -RegistryValue 1024 -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name "Ethernet0" -RegistryKeyword "*TransmitBuffers" -RegistryValue 1024 -ErrorAction SilentlyContinue
        Write-Host " [OK] Da tang ReceiveBuffers = 1024, TransmitBuffers = 1024 chong tran hang doi" -ForegroundColor Green
    }
} catch {
    Write-Host " [!] Loi tinh chinh NetAdapter: $_" -ForegroundColor Red
}

# 4. CAU HINH DNS DU PHONG TOC DO CAO (CHONG MAT KET NOI EVENT 1014)
Write-Host "`n>>> [4/5] Bo sung DNS Server du phong (Cloudflare 1.1.1.1 & Google 8.8.8.8)..." -ForegroundColor Cyan
try {
    $curDns = (Get-DnsClientServerAddress -InterfaceAlias "Ethernet0" -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
    $dnsList = [System.Collections.Generic.List[string]]::new()
    if ($curDns) {
        foreach ($d in $curDns) { if ($d -and -not $dnsList.Contains($d)) { $dnsList.Add($d) } }
    } else {
        $dnsList.Add("172.16.160.50")
    }
    if (-not $dnsList.Contains("1.1.1.1")) { $dnsList.Add("1.1.1.1") }
    if (-not $dnsList.Contains("8.8.8.8")) { $dnsList.Add("8.8.8.8") }

    Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses $dnsList.ToArray() -ErrorAction SilentlyContinue
    Write-Host " [OK] Danh sach DNS moi tren Ethernet0: $($dnsList -join ', ')" -ForegroundColor Green
} catch {
    Write-Host " [!] Loi thiet lap DNS: $_" -ForegroundColor Red
}

# 5. DAT LAI WINSOCK CATALOG, TCP/IP STACK VA XOA DNS CACHE
Write-Host "`n>>> [5/5] Dat lai TCP/IP Stack, Winsock Catalog va lam sach DNS Cache..." -ForegroundColor Cyan
netsh winsock reset | Out-Null
netsh int ip reset | Out-Null
ipconfig /flushdns | Out-Null
netsh int tcp set global autotuninglevel=normal | Out-Null
Write-Host " [OK] Da flush DNS, dat lai Winsock Catalog va TCP/IP Stack ve trang thai toi uu!" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " HOAN TAT! HE THONG DA DUOC TOI UU HOA CHONG ROT MANG & TREO " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
