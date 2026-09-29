# =========================================================================
# VUONGTT TOOLKIT 2026 - PRODUCT KEY & OEM BIOS VIEWER ENGINE
# Module tra cứu Product Key Windows, Office & BIOS OEM Key nhúng phần cứng
# =========================================================================

function Get-VUONGTTOemBiosKey {
    try {
        # 1. Tra cứu qua WMI / CIM SoftwareLicensingService
        $oemKey = (Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue).OA3xOriginalProductKey
        if (-not [string]::IsNullOrWhiteSpace($oemKey)) {
            return $oemKey.Trim()
        }

        # 2. Dự phòng qua ACPI MSDM Table
        $msdm = Get-CimInstance -Namespace root\wmi -ClassName MSDM_Table -ErrorAction SilentlyContinue
        if ($msdm -and $msdm.MSDM_Table) {
            $rawBytes = $msdm.MSDM_Table
            if ($rawBytes.Length -ge 56) {
                $asciiKey = [System.Text.Encoding]::ASCII.GetString($rawBytes, 56, 29).Trim()
                if ($asciiKey -match '^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$') {
                    return $asciiKey
                }
            }
        }

        return "Không có (Máy tự ráp / Không nhúng Key BIOS OEM)"
    } catch {
        return "Không có (Máy tự ráp / Không nhúng Key BIOS OEM)"
    }
}

function Decode-DigitalProductId {
    param([byte[]]$digitalProductId)
    if (-not $digitalProductId -or $digitalProductId.Length -lt 67) { return "" }
    try {
        $digits = "BCDFGHJKMPQRTVWXY2346789"
        $isWin8Plus = [int]([math]::Floor($digitalProductId[66] / 6)) -band 1
        $digitalProductId[66] = [byte](($digitalProductId[66] -band 0xF7) -bor (($isWin8Plus -band 2) * 4))

        $keyChars = @()
        $last = 0
        for ($i = 24; $i -ge 0; $i--) {
            $cur = 0
            for ($j = 14; $j -ge 0; $j--) {
                $cur = ($cur * 256) -bxor $digitalProductId[52 + $j]
                $digitalProductId[52 + $j] = [byte][math]::Floor($cur / 24)
                $cur = $cur % 24
            }
            $keyChars = @($digits[$cur]) + $keyChars
            $last = $cur
        }

        if ($isWin8Plus -ne 0) {
            $keyCharsStr = -join $keyChars
            $keyPart1 = $keyCharsStr.Substring(1, $last)
            $insertChar = "N"
            $keyPart2 = $keyCharsStr.Substring($last + 1, $keyCharsStr.Length - ($last + 1))
            $rawKey = $keyPart1 + $insertChar + $keyPart2
        } else {
            $rawKey = -join $keyChars
        }

        # Định dạng nhóm 5-5-5-5-5
        $formatted = @()
        for ($k = 0; $k -lt 25; $k += 5) {
            $formatted += $rawKey.Substring($k, 5)
        }
        return ($formatted -join "-")
    } catch {
        return ""
    }
}

function Get-VUONGTTInstalledWindowsKey {
    $info = [PSCustomObject]@{
        ProductName = ""
        EditionId   = ""
        Key         = "Không thể trích xuất (Bản quyền kỹ thuật số Digital License)"
        PartialKey  = ""
        Status      = "Không rõ"
    }

    try {
        $cv = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
        if ($cv) {
            $info.ProductName = if ($cv.ProductName) { $cv.ProductName } else { "Windows 10/11" }
            $info.EditionId   = if ($cv.EditionID) { $cv.EditionID } else { "" }
            
            # Giải mã DigitalProductId
            if ($cv.DigitalProductId) {
                $decoded = Decode-DigitalProductId -digitalProductId $cv.DigitalProductId
                if ($decoded -and $decoded -match '^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$') {
                    $info.Key = $decoded
                }
            }
        }

        # Trích xuất 5 ký tự cuối từ SoftwareLicensingProduct
        $lic = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL AND ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($lic) {
            $info.PartialKey = $lic.PartialProductKey
            $info.Status = if ($lic.LicenseStatus -eq 1) { "Đã kích hoạt vĩnh viễn (Licensed)" } else { "Chưa kích hoạt hoặc dùng thử" }
        }
    } catch {}

    return $info
}

function Get-VUONGTTOfficeLicenseStatus {
    $results = @()
    try {
        $osppCandidates = @(
            "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
            "$env:ProgramFiles\Microsoft Office\Office15\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office15\OSPP.VBS",
            "$env:ProgramFiles\Microsoft Office\Office14\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office14\OSPP.VBS"
        )

        $osppPath = ""
        foreach ($cand in $osppCandidates) {
            if (Test-Path $cand) {
                $osppPath = $cand
                break
            }
        }

        if (-not $osppPath) {
            return @([PSCustomObject]@{
                Name        = "Microsoft Office"
                Status      = "Chưa cài đặt Microsoft Office trên máy tính này"
                PartialKey  = "N/A"
            })
        }

        # Chạy ospp.vbs
        $output = cscript.exe //nologo "$osppPath" /dstatus 2>&1
        $currentName = ""
        $currentStatus = ""
        $currentKey = ""

        foreach ($line in ($output -split "`r?`n")) {
            $t = $line.Trim()
            if ($t -match "^LICENSE NAME:\s*(.*)$") {
                if ($currentName) {
                    $results += [PSCustomObject]@{ Name=$currentName; Status=$currentStatus; PartialKey=$currentKey }
                }
                $currentName = $Matches[1].Trim()
                $currentStatus = ""
                $currentKey = ""
            } elseif ($t -match "^LICENSE STATUS:\s*(.*)$") {
                $currentStatus = $Matches[1].Trim()
            } elseif ($t -match "Last 5 characters of installed product key:\s*(.*)$") {
                $currentKey = $Matches[1].Trim()
            }
        }

        if ($currentName) {
            $results += [PSCustomObject]@{ Name=$currentName; Status=$currentStatus; PartialKey=$currentKey }
        }

        if ($results.Count -eq 0) {
            $results += [PSCustomObject]@{
                Name        = "Microsoft Office"
                Status      = "Đã cài Office (Chưa nạp key hoặc bản quyền Click-to-Run)"
                PartialKey  = "N/A"
            }
        }
    } catch {
        $results += [PSCustomObject]@{
            Name        = "Microsoft Office"
            Status      = "Lỗi khi kiểm tra: $($_.Exception.Message)"
            PartialKey  = "N/A"
        }
    }

    return $results
}
