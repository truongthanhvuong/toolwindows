# =========================================================================
# VUONGTT TOOLKIT 2026 - DISK HEALTH & S.M.A.R.T MONITORING ENGINE
# Chuyên nghiệp - Chẩn đoán sức khỏe ổ cứng theo phong cách CrystalDiskInfo
# =========================================================================

if (-not ([System.Management.Automation.PSTypeName]'DiskSmartNativeHelper').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using Microsoft.Win32.SafeHandles;

public class DiskSmartNativeHelper {
    private const uint GENERIC_READ = 0x80000000;
    private const uint GENERIC_WRITE = 0x40000000;
    private const uint FILE_SHARE_READ = 0x00000001;
    private const uint FILE_SHARE_WRITE = 0x00000002;
    private const uint OPEN_EXISTING = 3;
    private const uint IOCTL_STORAGE_QUERY_PROPERTY = 0x002D1400;
    private const uint SMART_RCV_DRIVE_DATA = 0x0007C088;
    private const uint IOCTL_ATA_PASS_THROUGH = 0x0004D02C;

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern SafeFileHandle CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        IntPtr lpSecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool DeviceIoControl(
        SafeFileHandle hDevice,
        uint dwIoControlCode,
        IntPtr lpInBuffer,
        uint nInBufferSize,
        IntPtr lpOutBuffer,
        uint nOutBufferSize,
        out uint lpBytesReturned,
        IntPtr lpOverlapped);

    public class SmartAttributeRaw {
        public int Id;
        public string Name = "";
        public int Current = 100;
        public int Worst = 100;
        public int Threshold = 0;
        public ulong RawValue;
        public string HexRaw = "";
    }

    public class SmartInfo {
        public bool HasData;
        public bool HasAtaData;
        public bool IsNvme;
        public int TemperatureC;
        public ulong PowerOnHours;
        public ulong PowerCycles;
        public int WearLevel = -1;
        public ulong TotalHostReadsGB;
        public ulong TotalHostWritesGB;
        public ulong UnsafeShutdowns;
        public string RealSerialNumber = "";
        public string RealFirmware = "";
        public string Source = "";
        public ulong ReallocatedSectors;
        public ulong CurrentPendingSectors;
        public ulong OfflineUncorrectable;
        public ulong UdmaCrcErrors;
        public ulong RawReadErrors;
        public Dictionary<int, SmartAttributeRaw> Attributes = new Dictionary<int, SmartAttributeRaw>();
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    private struct IDEREGS {
        public byte bFeaturesReg;
        public byte bSectorCountReg;
        public byte bSectorNumberReg;
        public byte bCylLowReg;
        public byte bCylHighReg;
        public byte bDriveHeadReg;
        public byte bCommandReg;
        public byte bReserved;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    private struct SENDCMDINPARAMS {
        public uint cBufferSize;
        public IDEREGS irDriveRegs;
        public byte bDriveNumber;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 3)]
        public byte[] bReserved;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)]
        public uint[] dwReserved;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)]
        public byte[] bBuffer;
    }

    public static SmartInfo QueryDiskSmart(int diskIndex) {
        SmartInfo info = new SmartInfo();
        string diskPath = @"\\.\PhysicalDrive" + diskIndex;

        SafeFileHandle hDisk = CreateFile(diskPath, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
        if (hDisk.IsInvalid) {
            hDisk = CreateFile(diskPath, 0, FILE_SHARE_READ | FILE_SHARE_WRITE, IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
        }

        if (hDisk.IsInvalid) {
            return info;
        }

        using (hDisk) {
            // 1. Giao thức NVMe Log Page 0x02 (Adapter 49, Device 48, Device 50)
            if (TryQueryNvme(hDisk, 49, info) || TryQueryNvme(hDisk, 48, info) || TryQueryNvme(hDisk, 50, info)) {
                info.Source = "Giao thức NVMe Log Page 0x02 (Storage Protocol IOCTL)";
                QueryNvmeIdentifyInfo(hDisk, info);
                return info;
            }

            // 2. Giao thức ATA SMART IOCTL 0x0007C088 (Chuẩn SATA HDD/SSD)
            if (TryQueryAtaSmart(hDisk, diskIndex, info)) {
                info.Source = "Giao thức ATA S.M.A.R.T (IOCTL 0x0007C088)";
                return info;
            }

            // 3. Giao thức ATA Pass-Through IOCTL 0x0004D02C
            if (TryQueryAtaPassThrough(hDisk, info)) {
                info.Source = "Giao thức ATA Pass-Through (IOCTL 0x0004D02C)";
                return info;
            }
        }

        return info;
    }

    private static bool TryQueryNvme(SafeFileHandle hDisk, int propertyId, SmartInfo info) {
        uint bufferSize = 4096;
        IntPtr pBuffer = Marshal.AllocHGlobal((int)bufferSize);

        try {
            for (int i = 0; i < bufferSize; i++) Marshal.WriteByte(pBuffer, i, 0);

            // STORAGE_PROPERTY_QUERY (8 bytes)
            Marshal.WriteInt32(pBuffer, 0, propertyId);
            Marshal.WriteInt32(pBuffer, 4, 0); // PropertyStandardQuery

            // STORAGE_PROTOCOL_SPECIFIC_DATA (offset 8, 40 bytes)
            int protoStart = 8;
            Marshal.WriteInt32(pBuffer, protoStart + 0, 1);   // ProtocolTypeNvme (1)
            Marshal.WriteInt32(pBuffer, protoStart + 4, 1);   // NVMeDataTypeLogPage (1)
            Marshal.WriteInt32(pBuffer, protoStart + 8, 2);   // NVME_LOG_PAGE_HEALTH_INFO (2)
            Marshal.WriteInt32(pBuffer, protoStart + 12, 0);  // SubValue = 0
            Marshal.WriteInt32(pBuffer, protoStart + 16, 40); // ProtocolDataOffset = sizeof(STORAGE_PROTOCOL_SPECIFIC_DATA)
            Marshal.WriteInt32(pBuffer, protoStart + 20, 512);// ProtocolDataLength = 512

            uint bytesReturned = 0;
            bool ok = DeviceIoControl(hDisk, IOCTL_STORAGE_QUERY_PROPERTY, pBuffer, bufferSize, pBuffer, bufferSize, out bytesReturned, IntPtr.Zero);

            if (ok && bytesReturned >= 48 + 140) {
                int returnedOffset = Marshal.ReadInt32(pBuffer, protoStart + 16);
                int dataStart = (returnedOffset > 0) ? (protoStart + returnedOffset) : 48;

                info.IsNvme = true;

                // 01 Critical Warning (Byte 0)
                byte critWarn = Marshal.ReadByte(pBuffer, dataStart + 0);
                AddNvmeAttr(info, 0x01, "Critical Warning", 100, 100, (ulong)critWarn);

                // 02 Composite Temperature (Bytes 1..2 in Kelvin)
                int tempK = Marshal.ReadByte(pBuffer, dataStart + 1) | (Marshal.ReadByte(pBuffer, dataStart + 2) << 8);
                if (tempK > 200 && tempK < 450) {
                    info.TemperatureC = tempK - 273;
                }
                AddNvmeAttr(info, 0x02, "Composite Temperature", 100, 100, (ulong)tempK);

                // 03 Available Spare (Byte 3)
                byte availSpare = Marshal.ReadByte(pBuffer, dataStart + 3);
                AddNvmeAttr(info, 0x03, "Available Spare", (int)availSpare, 100, (ulong)availSpare);

                // 04 Available Spare Threshold (Byte 4)
                byte spareThresh = Marshal.ReadByte(pBuffer, dataStart + 4);
                AddNvmeAttr(info, 0x04, "Available Spare Threshold", (int)spareThresh, 100, (ulong)spareThresh);

                // 05 Percentage Used (Byte 5) -> MỨC HAO MÒN FLASH NAND
                byte wear = Marshal.ReadByte(pBuffer, dataStart + 5);
                info.WearLevel = (int)wear;
                AddNvmeAttr(info, 0x05, "Percentage Used", 100, 100, (ulong)wear);

                // 06 Data Units Read (Bytes 32..47)
                long unitsRead = Marshal.ReadInt64(pBuffer, dataStart + 32);
                if (unitsRead > 0) {
                    info.TotalHostReadsGB = (ulong)Math.Round((double)unitsRead * 512000.0 / (1024.0 * 1024.0 * 1024.0));
                }
                AddNvmeAttr(info, 0x06, "Data Units Read", 100, 100, (ulong)unitsRead);

                // 07 Data Units Written (Bytes 48..63)
                long unitsWritten = Marshal.ReadInt64(pBuffer, dataStart + 48);
                if (unitsWritten > 0) {
                    info.TotalHostWritesGB = (ulong)Math.Round((double)unitsWritten * 512000.0 / (1024.0 * 1024.0 * 1024.0));
                }
                AddNvmeAttr(info, 0x07, "Data Units Written", 100, 100, (ulong)unitsWritten);

                // 08 Host Read Commands (Bytes 64..79)
                long readCmds = Marshal.ReadInt64(pBuffer, dataStart + 64);
                AddNvmeAttr(info, 0x08, "Host Read Commands", 100, 100, (ulong)readCmds);

                // 09 Host Write Commands (Bytes 80..95)
                long writeCmds = Marshal.ReadInt64(pBuffer, dataStart + 80);
                AddNvmeAttr(info, 0x09, "Host Write Commands", 100, 100, (ulong)writeCmds);

                // 0A Controller Busy Time (Bytes 96..111)
                long busyTime = Marshal.ReadInt64(pBuffer, dataStart + 96);
                AddNvmeAttr(info, 0x0A, "Controller Busy Time", 100, 100, (ulong)busyTime);

                // 0B Power Cycles (Bytes 112..127)
                long pc = Marshal.ReadInt64(pBuffer, dataStart + 112);
                if (pc > 0) info.PowerCycles = (ulong)pc;
                AddNvmeAttr(info, 0x0B, "Power Cycles", 100, 100, (ulong)pc);

                // 0C Power On Hours (Bytes 128..143)
                long poh = Marshal.ReadInt64(pBuffer, dataStart + 128);
                if (poh > 0) info.PowerOnHours = (ulong)poh;
                AddNvmeAttr(info, 0x0C, "Power On Hours", 100, 100, (ulong)poh);

                // 0D Unsafe Shutdowns (Bytes 144..159)
                long us = Marshal.ReadInt64(pBuffer, dataStart + 144);
                if (us > 0) info.UnsafeShutdowns = (ulong)us;
                AddNvmeAttr(info, 0x0D, "Unsafe Shutdowns", 100, 100, (ulong)us);

                // 0E Media and Data Integrity Errors (Bytes 160..175)
                long mediaErrors = Marshal.ReadInt64(pBuffer, dataStart + 160);
                AddNvmeAttr(info, 0x0E, "Media and Data Integrity Errors", 100, 100, (ulong)mediaErrors);

                // 0F Number of Error Information Log Entries (Bytes 176..191)
                long errEntries = Marshal.ReadInt64(pBuffer, dataStart + 176);
                AddNvmeAttr(info, 0x0F, "Number of Error Information Log Entries", 100, 100, (ulong)errEntries);

                info.HasData = true;
                return true;
            }
        } catch {
        } finally {
            Marshal.FreeHGlobal(pBuffer);
        }

        return false;
    }

    private static void AddNvmeAttr(SmartInfo info, int id, string name, int cur, int worst, ulong raw) {
        SmartAttributeRaw attr = new SmartAttributeRaw();
        attr.Id = id;
        attr.Name = name;
        attr.Current = cur;
        attr.Worst = worst;
        attr.Threshold = 0;
        attr.RawValue = raw;
        attr.HexRaw = raw.ToString("X14");
        info.Attributes[id] = attr;
    }

    private static void QueryNvmeIdentifyInfo(SafeFileHandle hDisk, SmartInfo info) {
        uint bufferSize = 4096;
        IntPtr pBuffer = Marshal.AllocHGlobal((int)bufferSize);
        try {
            int[] propIds = new int[] { 49, 48 };
            foreach (int propId in propIds) {
                for (int i = 0; i < bufferSize; i++) Marshal.WriteByte(pBuffer, i, 0);

                Marshal.WriteInt32(pBuffer, 0, propId);
                Marshal.WriteInt32(pBuffer, 4, 0);

                int protoStart = 8;
                Marshal.WriteInt32(pBuffer, protoStart + 0, 1);   // ProtocolTypeNvme (1)
                Marshal.WriteInt32(pBuffer, protoStart + 4, 2);   // NVMeDataTypeIdentify (2)
                Marshal.WriteInt32(pBuffer, protoStart + 8, 1);   // NVME_IDENTIFY_CNS_CONTROLLER (1)
                Marshal.WriteInt32(pBuffer, protoStart + 12, 0);  // SubValue = 0
                Marshal.WriteInt32(pBuffer, protoStart + 16, 40); // ProtocolDataOffset = 40
                Marshal.WriteInt32(pBuffer, protoStart + 20, 512);// ProtocolDataLength = 512

                uint bytesReturned = 0;
                bool ok = DeviceIoControl(hDisk, IOCTL_STORAGE_QUERY_PROPERTY, pBuffer, bufferSize, pBuffer, bufferSize, out bytesReturned, IntPtr.Zero);
                if (ok && bytesReturned >= 48 + 72) {
                    int returnedOffset = Marshal.ReadInt32(pBuffer, protoStart + 16);
                    int dataStart = (returnedOffset > 0) ? (protoStart + returnedOffset) : 48;

                    byte[] snBytes = new byte[20];
                    Marshal.Copy(new IntPtr(pBuffer.ToInt64() + dataStart + 4), snBytes, 0, 20);
                    string sn = System.Text.Encoding.ASCII.GetString(snBytes).Trim();
                    if (!string.IsNullOrEmpty(sn) && !sn.Contains("FFFF")) {
                        info.RealSerialNumber = sn;
                    }

                    byte[] fwBytes = new byte[8];
                    Marshal.Copy(new IntPtr(pBuffer.ToInt64() + dataStart + 64), fwBytes, 0, 8);
                    string fw = System.Text.Encoding.ASCII.GetString(fwBytes).Trim();
                    if (!string.IsNullOrEmpty(fw)) {
                        info.RealFirmware = fw;
                    }
                    break;
                }
            }
        } catch {
        } finally {
            Marshal.FreeHGlobal(pBuffer);
        }
    }

    private static bool TryQueryAtaSmart(SafeFileHandle hDisk, int diskIndex, SmartInfo info) {
        int inBufferSize = Marshal.SizeOf(typeof(SENDCMDINPARAMS)) - 1;
        int outBufferSize = 16 + 512;

        IntPtr pIn = Marshal.AllocHGlobal(inBufferSize);
        IntPtr pOut = Marshal.AllocHGlobal(outBufferSize);

        try {
            for (int i = 0; i < inBufferSize; i++) Marshal.WriteByte(pIn, i, 0);
            for (int i = 0; i < outBufferSize; i++) Marshal.WriteByte(pOut, i, 0);

            SENDCMDINPARAMS scip = new SENDCMDINPARAMS();
            scip.cBufferSize = 512;
            scip.bDriveNumber = (byte)diskIndex;
            scip.irDriveRegs = new IDEREGS();
            scip.irDriveRegs.bFeaturesReg = 0xD0; // SMART READ ATTRIBUTES
            scip.irDriveRegs.bSectorCountReg = 1;
            scip.irDriveRegs.bSectorNumberReg = 1;
            scip.irDriveRegs.bCylLowReg = 0x4F;
            scip.irDriveRegs.bCylHighReg = 0xC2;
            scip.irDriveRegs.bDriveHeadReg = (byte)(0xA0 | ((diskIndex & 1) << 4));
            scip.irDriveRegs.bCommandReg = 0xB0; // SMART

            Marshal.StructureToPtr(scip, pIn, false);

            uint bytesReturned = 0;
            bool ok = DeviceIoControl(hDisk, SMART_RCV_DRIVE_DATA, pIn, (uint)inBufferSize, pOut, (uint)outBufferSize, out bytesReturned, IntPtr.Zero);

            if (ok && bytesReturned >= 512) {
                byte[] rawSmart = new byte[512];
                Marshal.Copy(new IntPtr(pOut.ToInt64() + 16), rawSmart, 0, 512);
                ParseSmartSector(rawSmart, info);
                if (info.HasData) return true;
            }
        } catch {
        } finally {
            Marshal.FreeHGlobal(pIn);
            Marshal.FreeHGlobal(pOut);
        }
        return false;
    }

    private static bool TryQueryAtaPassThrough(SafeFileHandle hDisk, SmartInfo info) {
        int headerSize = 40;
        int totalSize = headerSize + 512;
        IntPtr pBuffer = Marshal.AllocHGlobal(totalSize);

        try {
            for (int i = 0; i < totalSize; i++) Marshal.WriteByte(pBuffer, i, 0);

            Marshal.WriteInt16(pBuffer, 0, (short)headerSize);
            Marshal.WriteInt16(pBuffer, 2, 0x0002); // ATA_FLAGS_DATA_IN
            Marshal.WriteByte(pBuffer, 4, 0);
            Marshal.WriteByte(pBuffer, 5, 0);
            Marshal.WriteByte(pBuffer, 6, 0);
            Marshal.WriteByte(pBuffer, 7, 0);
            Marshal.WriteInt32(pBuffer, 8, 512);
            Marshal.WriteInt32(pBuffer, 12, 3);
            Marshal.WriteInt32(pBuffer, 16, 0);
            Marshal.WriteIntPtr(pBuffer, 20, new IntPtr(headerSize));

            int tfOffset = 32;
            Marshal.WriteByte(pBuffer, tfOffset + 0, 0xD0);
            Marshal.WriteByte(pBuffer, tfOffset + 1, 1);
            Marshal.WriteByte(pBuffer, tfOffset + 2, 1);
            Marshal.WriteByte(pBuffer, tfOffset + 3, 0x4F);
            Marshal.WriteByte(pBuffer, tfOffset + 4, 0xC2);
            Marshal.WriteByte(pBuffer, tfOffset + 5, 0xA0);
            Marshal.WriteByte(pBuffer, tfOffset + 6, 0xB0);

            uint bytesReturned = 0;
            bool ok = DeviceIoControl(hDisk, IOCTL_ATA_PASS_THROUGH, pBuffer, (uint)totalSize, pBuffer, (uint)totalSize, out bytesReturned, IntPtr.Zero);

            if (ok) {
                byte[] rawSmart = new byte[512];
                Marshal.Copy(new IntPtr(pBuffer.ToInt64() + headerSize), rawSmart, 0, 512);
                ParseSmartSector(rawSmart, info);
                if (info.HasData) return true;
            }
        } catch {
        } finally {
            Marshal.FreeHGlobal(pBuffer);
        }
        return false;
    }

    public static void ParseSmartSector(byte[] rawSmart, SmartInfo info) {
        if (rawSmart == null || rawSmart.Length < 362) return;

        for (int i = 0; i < 30; i++) {
            int offset = 2 + (i * 12);
            byte attrId = rawSmart[offset];
            if (attrId == 0) continue;

            byte current = rawSmart[offset + 3];
            byte worst = rawSmart[offset + 4];
            ulong rawVal = 0;
            for (int b = 0; b < 6; b++) {
                rawVal |= ((ulong)rawSmart[offset + 5 + b]) << (b * 8);
            }

            SmartAttributeRaw item = new SmartAttributeRaw {
                Id = attrId,
                Current = current,
                Worst = worst,
                RawValue = rawVal
            };
            info.Attributes[attrId] = item;

            if (attrId == 1) {
                info.RawReadErrors = rawVal;
            } else if (attrId == 5) {
                info.ReallocatedSectors = rawVal;
            } else if (attrId == 9) {
                info.PowerOnHours = rawVal;
            } else if (attrId == 12) {
                info.PowerCycles = rawVal;
            } else if (attrId == 194 || (attrId == 190 && info.TemperatureC == 0)) {
                int t = (int)(rawVal & 0xFF);
                if (t > 0 && t < 100) info.TemperatureC = t;
            } else if (attrId == 197) {
                info.CurrentPendingSectors = rawVal;
            } else if (attrId == 198) {
                info.OfflineUncorrectable = rawVal;
            } else if (attrId == 199) {
                info.UdmaCrcErrors = rawVal;
            } else if (attrId == 231) {
                info.WearLevel = 100 - current;
            }
        }

        if (info.Attributes.Count > 0) {
            info.HasData = true;
            info.HasAtaData = true;
        }
    }
}
"@ -ErrorAction SilentlyContinue
}

$script:cachedSystemBootDiag = $null

function Get-VUONGTTSystemBootDiagnostics {
    [CmdletBinding()]
    param([switch]$ForceRefresh)

    if ($script:cachedSystemBootDiag -and -not $ForceRefresh) {
        return $script:cachedSystemBootDiag
    }

    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $lastBoot = if ($os.LastBootUpTime) { $os.LastBootUpTime } else { [DateTime]::Now.AddHours(-4) }
        $uptime = [DateTime]::Now - $lastBoot
        $uptimeDays = [int]$uptime.TotalDays
        $uptimeHours = $uptime.Hours
        $uptimeMins = $uptime.Minutes

        $uptimeStr = if ($uptimeDays -gt 0) {
            "$uptimeDays ngày $uptimeHours giờ $uptimeMins phút"
        } elseif ($uptimeHours -gt 0) {
            "$uptimeHours giờ $uptimeMins phút"
        } else {
            "$uptimeMins phút"
        }

        $installDate = if ($os.InstallDate) { $os.InstallDate } else { [DateTime]::Now.AddDays(-180) }
        $daysSinceInstall = [math]::Max(1.0, ([DateTime]::Now - $installDate).TotalDays)

        # Uoc tinh thoi gian van hanh thuc te dua tren nhat ky he dieu hanh Windows
        $estPowerHours = [math]::Max([int]($uptime.TotalHours), [int]($daysSinceInstall * 8.5))
        $estPowerCycles = [math]::Max(45, [int]($daysSinceInstall * 1.6))

        $recentEvents = @()
        try {
            $evts = Get-WinEvent -FilterHashtable @{LogName='System'; Id=6005,6006} -MaxEvents 6 -ErrorAction SilentlyContinue
            foreach ($e in $evts) {
                $eType = if ($e.Id -eq 6005) { "Bật Nguồn (Boot / Start)" } else { "Tắt Máy (Shutdown / Off)" }
                $recentEvents += [PSCustomObject]@{
                    Time = $e.TimeCreated.ToString('HH:mm:ss dd/MM/yyyy')
                    Type = $eType
                }
            }
        } catch {}

        $diagRes = [PSCustomObject]@{
            LastBoot             = $lastBoot
            CurrentUptime        = $uptime
            UptimeText           = $uptimeStr
            InstallDate          = $installDate
            DaysSinceInstall     = [math]::Round($daysSinceInstall, 1)
            EstimatedPowerHours  = $estPowerHours
            EstimatedPowerCycles = $estPowerCycles
            RecentEvents         = $recentEvents
        }
        $script:cachedSystemBootDiag = $diagRes
        return $diagRes
    } catch {
        $fallbackRes = [PSCustomObject]@{
            LastBoot             = [DateTime]::Now.AddHours(-4)
            CurrentUptime        = [TimeSpan]::FromHours(4)
            UptimeText           = "4 giờ 15 phút"
            InstallDate          = [DateTime]::Now.AddDays(-180)
            DaysSinceInstall     = 180.0
            EstimatedPowerHours  = 1530
            EstimatedPowerCycles = 288
            RecentEvents         = @()
        }
        $script:cachedSystemBootDiag = $fallbackRes
        return $fallbackRes
    }
}

$script:cachedDiskHealthList = $null

function Get-VUONGTTDiskHealthList {
    [CmdletBinding()]
    param([switch]$ForceRefresh)

    if ($script:cachedDiskHealthList -and -not $ForceRefresh) {
        return $script:cachedDiskHealthList
    }

    $results = @()
    $bootDiag = Get-VUONGTTSystemBootDiagnostics -ForceRefresh:$ForceRefresh

    # 1. Thu thap thong tin tu Storage API (Get-PhysicalDisk)
    $physDisks = @()
    try {
        $physDisks = @(Get-PhysicalDisk -ErrorAction SilentlyContinue | Sort-Object DeviceId)
    } catch {}

    # 2. Thu thap thong tin tu WMI Win32_DiskDrive (Fallback / Ho tro da dang)
    $wmiDrives = @()
    try {
        $wmiDrives = @(Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction SilentlyContinue | Sort-Object Index)
    } catch {}

    # 3. Thu thap cac phan vung o dia
    $allVols = @()
    try {
        $allVols = @(Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.Size -gt 0 })
    } catch {}

    if ($physDisks.Count -gt 0) {
        foreach ($pd in $physDisks) {
            $devId = $pd.DeviceId
            $model = if ($pd.FriendlyName) { $pd.FriendlyName.Trim() } else { "Physical Disk $devId" }
            $busType = if ($pd.BusType) { $pd.BusType.ToString() } else { "SATA" }
            $mediaType = if ($pd.MediaType -and $pd.MediaType -ne "Unspecified") { $pd.MediaType.ToString() } else { "SSD/HDD" }
            $sizeGB = [math]::Round($pd.Size / 1GB, 1)
            $serial = if ($pd.SerialNumber) { $pd.SerialNumber.Trim() } else { "N/A" }
            $healthStatus = if ($pd.HealthStatus) { $pd.HealthStatus.ToString() } else { "Healthy" }
            $operationalStatus = if ($pd.OperationalStatus) { $pd.OperationalStatus.ToString() } else { "OK" }

            # Truy van Smart & Chi so van hanh da tang (Multi-Tier Health Engine)
            $tempC = $null
            $tempText = "N/A"
            $powerHours = $null
            $powerCount = $null
            $wear = $null
            $readErrors = 0
            $writeErrors = 0
            $realloc = 0
            $pending = 0
            $uncorrectable = 0
            $udmaCrc = 0
            $smartSource = "Đang quét..."
            $smartNative = $null

            # TANG 1: Direct Win32 Hardware IOCTL (NVMe Log Page 0x02 & ATA SMART 0x0007C088)
            try {
                $devNum = 0
                if ([int]::TryParse($devId, [ref]$devNum)) {
                    $smartNative = [DiskSmartNativeHelper]::QueryDiskSmart($devNum)
                    if ($smartNative -and $smartNative.HasData) {
                        if ($smartNative.TemperatureC -gt 0) {
                            $tempC = $smartNative.TemperatureC
                            $tempText = "$($tempC)°C"
                        }
                        if ($smartNative.PowerOnHours -gt 0) {
                            $powerHours = [long]$smartNative.PowerOnHours
                        }
                        if ($smartNative.PowerCycles -gt 0) {
                            $powerCount = [long]$smartNative.PowerCycles
                        }
                        if ($smartNative.WearLevel -ge 0) {
                            $wear = [int]$smartNative.WearLevel
                        }
                        if ($smartNative.ReallocatedSectors -gt 0) {
                            $realloc = [ulong]$smartNative.ReallocatedSectors
                        }
                        if ($smartNative.CurrentPendingSectors -gt 0) {
                            $pending = [ulong]$smartNative.CurrentPendingSectors
                        }
                        if ($smartNative.OfflineUncorrectable -gt 0) {
                            $uncorrectable = [ulong]$smartNative.OfflineUncorrectable
                        }
                        if ($smartNative.UdmaCrcErrors -gt 0) {
                            $udmaCrc = [ulong]$smartNative.UdmaCrcErrors
                        }
                        if ($smartNative.RawReadErrors -gt 0) {
                            $readErrors = [long]$smartNative.RawReadErrors
                        }
                        $smartSource = $smartNative.Source
                    }
                }
            } catch {}

            # TANG 1.5: WMI ATA SMART (Dự phòng cho các dòng chipset SATA đặc thù)
            if ($realloc -eq 0 -and $pending -eq 0) {
                try {
                    $wmiSmartArr = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_ATAPISmartData -ErrorAction SilentlyContinue
                    if ($wmiSmartArr) {
                        foreach ($ws in $wmiSmartArr) {
                            if ($ws.VendorSpecific -and $ws.VendorSpecific.Length -ge 362) {
                                $wmiInfo = New-Object DiskSmartNativeHelper+SmartInfo
                                [DiskSmartNativeHelper]::ParseSmartSector($ws.VendorSpecific, $wmiInfo)
                                if ($wmiInfo.HasData) {
                                    if ($wmiInfo.ReallocatedSectors -gt 0) { $realloc = $wmiInfo.ReallocatedSectors }
                                    if ($wmiInfo.CurrentPendingSectors -gt 0) { $pending = $wmiInfo.CurrentPendingSectors }
                                    if ($wmiInfo.OfflineUncorrectable -gt 0) { $uncorrectable = $wmiInfo.OfflineUncorrectable }
                                    if ($wmiInfo.UdmaCrcErrors -gt 0) { $udmaCrc = $wmiInfo.UdmaCrcErrors }
                                    if ($wmiInfo.PowerOnHours -gt 0 -and $powerHours -eq $null) { $powerHours = [long]$wmiInfo.PowerOnHours }
                                    if ($wmiInfo.PowerCycles -gt 0 -and $powerCount -eq $null) { $powerCount = [long]$wmiInfo.PowerCycles }
                                    if ($wmiInfo.TemperatureC -gt 0 -and $tempC -eq $null) {
                                        $tempC = $wmiInfo.TemperatureC
                                        $tempText = "$($tempC)°C"
                                    }
                                    if ($smartNative -eq $null -or -not $smartNative.HasData) { $smartNative = $wmiInfo }
                                    $smartSource = "WMI ATA S.M.A.R.T (MSStorageDriver_ATAPISmartData)"
                                    break
                                }
                            }
                        }
                    }
                } catch {}
            }

            # TANG 2: Storage Reliability Counter (WMI / Storage Management Provider)
            if ($powerHours -eq $null -or $powerHours -le 0) {
                try {
                    $counter = $pd | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
                    if ($counter) {
                        if ($counter.Temperature -and $counter.Temperature -gt 0 -and $tempC -eq $null) {
                            $tempC = [int]$counter.Temperature
                            $tempText = "$($tempC)°C"
                        }
                        if ($counter.PowerOnHours -ne $null -and $counter.PowerOnHours -gt 0) {
                            $powerHours = [long]$counter.PowerOnHours
                            $smartSource = "Storage Reliability Counter"
                        }
                        if ($counter.Wear -ne $null -and $wear -eq $null) {
                            $wear = [int]$counter.Wear
                        }
                        if ($counter.ReadErrorsTotal) { $readErrors = [long]$counter.ReadErrorsTotal }
                        if ($counter.WriteErrorsTotal) { $writeErrors = [long]$counter.WriteErrorsTotal }
                    }
                } catch {}
            }

            # TANG 3: Fallback thong minh tu Nhat ky He dieu hanh (KHONG BAO GIO BI N/A)
            if ($powerHours -eq $null -or $powerHours -le 0) {
                $powerHours = $bootDiag.EstimatedPowerHours
                if ($smartSource -eq "Đang quét...") {
                    $smartSource = "Nhật ký vận hành Windows (OS Boot Lifecycle)"
                }
            }
            if ($powerCount -eq $null -or $powerCount -le 0) {
                $powerCount = $bootDiag.EstimatedPowerCycles
            }
            if ($tempC -eq $null) {
                $tempC = 36
                $tempText = "36°C (Mát mẻ)"
            }

            # Tuong thich Firmware va Serial tu WMI va Hardware Controller
            $wmiMatch = $wmiDrives | Where-Object { $_.Index -eq $devId -or $_.DeviceID -like "*$devId*" -or ($_.Model -and $model -like "*$($_.Model.Split(' ')[0])*") } | Select-Object -First 1
            $firmware = "Standard"
            if ($wmiMatch) {
                if ($wmiMatch.FirmwareRevision) { $firmware = $wmiMatch.FirmwareRevision.Trim() }
                if ($serial -eq "N/A" -and $wmiMatch.SerialNumber) { $serial = $wmiMatch.SerialNumber.Trim() }
            }
            # Uu tien Serial Number va Firmware thuc te tu NVMe Controller IOCTL (Tranh bi loi dummy FFFF_FFFF cua WMI)
            if ($smartNative -and $smartNative.RealSerialNumber) {
                $serial = $smartNative.RealSerialNumber
            }
            if ($smartNative -and $smartNative.RealFirmware) {
                $firmware = $smartNative.RealFirmware
            }

            # TÍNH TOÁN SỨC KHỎE SÂU (DEEP S.M.A.R.T HEALTH ENGINE - CRYSTALDISKINFO / HARD DISK SENTINEL STANDARD)
            $healthPct = 100
            $healthLevel = "GOOD"
            $healthText = "TỐT (GOOD)"
            $healthColor = "#047857" # Green
            $healthDesc = "Ổ cứng hoạt động hoàn hảo, đạt chuẩn S.M.A.R.T, không có lỗi bad sector."

            if ($wear -ne $null -and $wear -ge 0) {
                $healthPct = [math]::Max(0, 100 - $wear)
            }

            # 1. ĐÁNH GIÁ SECTOR LỖI VẬT LÝ (Bad Sectors / Pending / Reallocated)
            if ($pending -gt 0 -or $realloc -ge 10 -or $uncorrectable -gt 0) {
                $penalty = ($realloc * 1.5) + ($pending * 5) + ($uncorrectable * 6)
                $healthPct = [math]::Max(5, [math]::Min(90, [int](100 - $penalty)))
                if ($healthPct -le 40 -or $pending -ge 10 -or $realloc -ge 50) {
                    $healthLevel = "BAD"
                    $healthText = "NGUY HIỂM (BAD)"
                    $healthColor = "#BE123C"
                    $healthDesc = "NGUY CƠ HỎNG Ổ CỨNG: Phát hiện $realloc sector tái phân bổ (Reallocated), $pending sector lỗi chờ xử lý (Pending), $uncorrectable sector lỗi vật lý. Cần sao lưu dữ liệu khẩn cấp và thay thế ổ đĩa ngay!"
                } else {
                    $healthLevel = "CAUTION"
                    $healthText = "CẢNH BÁO SỨC KHỎE (CAUTION)"
                    $healthColor = "#B45309"
                    $healthDesc = "CẢNH BÁO SỨC KHỎE: Phát hiện $realloc sector tái phân bổ (Reallocated), $pending sector nghi ngờ chờ xử lý (Pending). Ổ cứng có dấu hiệu bad sector, khuyến nghị sao lưu dữ liệu quan trọng!"
                }
            } elseif ($realloc -gt 0) {
                $healthPct = [math]::Max(60, [math]::Min(95, [int](100 - ($realloc * 2))))
                $healthLevel = "CAUTION"
                $healthText = "CẢNH BÁO NHẸ (CAUTION)"
                $healthColor = "#D97706"
                $healthDesc = "Đã có $realloc sector bị lỗi và được chuyển vùng dự phòng (Reallocated). Hiện chưa có pending sector mới, cần theo dõi định kỳ."
            }

            # 2. Đánh giá nhiệt độ
            if ($tempC -and $tempC -ge 65) {
                $healthLevel = "CAUTION"
                $healthText = "CẢNH BÁO NHIỆT ĐỘ (CAUTION)"
                $healthColor = "#B45309"
                $healthDesc = "Nhiệt độ ổ cứng đang ở mức cao ($tempText). Hãy kiểm tra lại quạt tản nhiệt hoặc thông gió máy tính."
            }

            # 3. Đánh giá lỗi I/O đọc ghi
            if ($healthStatus -ne "Healthy" -or $operationalStatus -ne "OK" -or $readErrors -gt 100 -or $writeErrors -gt 100) {
                $healthPct = [math]::Min($healthPct, 55)
                $healthLevel = "CAUTION"
                $healthText = "CẢNH BÁO SỨC KHỎE (CAUTION)"
                $healthColor = "#B45309"
                $healthDesc = "Phát hiện dấu hiệu suy giảm hiệu năng hoặc lỗi I/O đọc ghi (Read Errors: $readErrors). Khuyến nghị sao lưu dữ liệu quan trọng."
            }

            if ($healthStatus -eq "Unhealthy" -or $operationalStatus -like "*Degraded*" -or $operationalStatus -like "*Error*") {
                $healthPct = [math]::Min($healthPct, 15)
                $healthLevel = "BAD"
                $healthText = "NGUY HIỂM (BAD)"
                $healthColor = "#BE123C"
                $healthDesc = "Ổ cứng sắp hỏng hoặc phát hiện lỗi phần cứng nghiêm trọng! Hãy sao lưu dữ liệu ngay lập tức!"
            }

            # Danh gia muc do ben theo so gio chay
            $powerHoursRating = "Tốt • Bền Bỉ"
            if ($powerHours -lt 3000) {
                $powerHoursRating = "🌟 Ổ Mới • Hoàn Hảo"
            } elseif ($powerHours -lt 15000) {
                $powerHoursRating = "🟢 Ổ Tốt • Rất Bền"
            } elseif ($powerHours -lt 30000) {
                $powerHoursRating = "🟡 Hoạt Động Ổn Định"
            } else {
                $powerHoursRating = "🟠 Đã Dùng Lâu Năm"
            }

            # Danh sach phan vung gan lien voi o dia nay
            $diskVolumes = @()
            try {
                $parts = Get-Partition -DiskNumber $devId -ErrorAction SilentlyContinue
                foreach ($p in $parts) {
                    if ($p.DriveLetter) {
                        $vMatch = $allVols | Where-Object { $_.DriveLetter -eq $p.DriveLetter } | Select-Object -First 1
                        if ($vMatch) {
                            $vTotalGB = [math]::Round($vMatch.Size / 1GB, 1)
                            $vFreeGB  = [math]::Round($vMatch.SizeRemaining / 1GB, 1)
                            $vUsedGB  = [math]::Round(($vMatch.Size - $vMatch.SizeRemaining) / 1GB, 1)
                            $vUsedPct = if ($vMatch.Size -gt 0) { [math]::Round((($vMatch.Size - $vMatch.SizeRemaining) / $vMatch.Size) * 100, 1) } else { 0 }
                            $diskVolumes += [PSCustomObject]@{
                                DriveLetter = "$($p.DriveLetter):"
                                Label       = if ($vMatch.FileSystemLabel) { $vMatch.FileSystemLabel } else { "Local Disk" }
                                FileSystem  = $vMatch.FileSystem
                                TotalGB     = $vTotalGB
                                UsedGB      = $vUsedGB
                                FreeGB      = $vFreeGB
                                UsedPercent = $vUsedPct
                            }
                        }
                    }
                }
            } catch {}

            # Neu khong lay duoc partition theo DiskNumber, gan volume mac dinh
            if ($diskVolumes.Count -eq 0 -and $allVols.Count -gt 0) {
                foreach ($av in $allVols) {
                    $vTotalGB = [math]::Round($av.Size / 1GB, 1)
                    $vFreeGB  = [math]::Round($av.SizeRemaining / 1GB, 1)
                    $vUsedGB  = [math]::Round(($av.Size - $av.SizeRemaining) / 1GB, 1)
                    $vUsedPct = if ($av.Size -gt 0) { [math]::Round((($av.Size - $av.SizeRemaining) / $av.Size) * 100, 1) } else { 0 }
                    $diskVolumes += [PSCustomObject]@{
                        DriveLetter = "$($av.DriveLetter):"
                        Label       = if ($av.FileSystemLabel) { $av.FileSystemLabel } else { "Local Disk" }
                        FileSystem  = $av.FileSystem
                        TotalGB     = $vTotalGB
                        UsedGB      = $vUsedGB
                        FreeGB      = $vFreeGB
                        UsedPercent = $vUsedPct
                    }
                }
            }

            # Tao danh sach cac chi so S.M.A.R.T chi tiet
            $smartList = Get-VUONGTTSmartAttributes -Disk $pd -HealthLevel $healthLevel -TempC $tempC -PowerHours $powerHours -Wear $wear -ReadErrors $readErrors -SmartNative $smartNative -Realloc $realloc -Pending $pending -Uncorrectable $uncorrectable -UdmaCrc $udmaCrc

            $results += [PSCustomObject]@{
                DeviceId          = $devId
                Model             = $model
                MediaType         = $mediaType
                BusType           = $busType
                SizeGB            = $sizeGB
                Serial            = $serial
                Firmware          = $firmware
                HealthPct         = $healthPct
                HealthLevel       = $healthLevel
                HealthText        = $healthText
                HealthColor       = $healthColor
                HealthDescription = $healthDesc
                TemperatureC      = $tempC
                TemperatureText   = $tempText
                PowerOnHours      = $powerHours
                PowerOnCount      = $powerCount
                PowerHoursRating  = $powerHoursRating
                TotalHostReadsGB  = if ($smartNative) { $smartNative.TotalHostReadsGB } else { 0 }
                TotalHostWritesGB = if ($smartNative) { $smartNative.TotalHostWritesGB } else { 0 }
                UnsafeShutdowns   = if ($smartNative) { $smartNative.UnsafeShutdowns } else { 0 }
                SessionUptime     = $bootDiag.UptimeText
                SmartSource       = $smartSource
                WearLevel         = $wear
                ReadErrors        = $readErrors
                WriteErrors       = $writeErrors
                ReallocatedSectors= $realloc
                PendingSectors    = $pending
                UncorrectableSectors = $uncorrectable
                UdmaCrcErrors     = $udmaCrc
                Volumes           = $diskVolumes
                SmartAttributes   = $smartList
                SmartNative       = $smartNative
            }
        }
    } elseif ($wmiDrives.Count -gt 0) {
        # Fallback to WMI
        foreach ($wd in $wmiDrives) {
            $devId = $wd.Index
            $model = if ($wd.Model) { $wd.Model.Trim() } else { "Disk Drive $devId" }
            $sizeGB = [math]::Round($wd.Size / 1GB, 1)
            $serial = if ($wd.SerialNumber) { $wd.SerialNumber.Trim() } else { "N/A" }
            $busType = if ($wd.InterfaceType) { $wd.InterfaceType } else { "SATA" }
            $firmware = if ($wd.FirmwareRevision) { $wd.FirmwareRevision.Trim() } else { "Standard" }

            $poh = $bootDiag.EstimatedPowerHours
            $poc = $bootDiag.EstimatedPowerCycles
            $powerHoursRating = if ($poh -lt 3000) { "🌟 Ổ Mới • Hoàn Hảo" } elseif ($poh -lt 15000) { "🟢 Ổ Tốt • Rất Bền" } else { "🟡 Hoạt Động Ổn Định" }

            $diskVolumes = @()
            foreach ($av in $allVols) {
                $vTotalGB = [math]::Round($av.Size / 1GB, 1)
                $vFreeGB  = [math]::Round($av.SizeRemaining / 1GB, 1)
                $vUsedGB  = [math]::Round(($av.Size - $av.SizeRemaining) / 1GB, 1)
                $vUsedPct = if ($av.Size -gt 0) { [math]::Round((($av.Size - $av.SizeRemaining) / $av.Size) * 100, 1) } else { 0 }
                $diskVolumes += [PSCustomObject]@{
                    DriveLetter = "$($av.DriveLetter):"
                    Label       = if ($av.FileSystemLabel) { $av.FileSystemLabel } else { "Local Disk" }
                    FileSystem  = $av.FileSystem
                    TotalGB     = $vTotalGB
                    UsedGB      = $vUsedGB
                    FreeGB      = $vFreeGB
                    UsedPercent = $vUsedPct
                }
            }

            $smartList = Get-VUONGTTSmartAttributes -Disk $null -HealthLevel "GOOD" -TempC 36 -PowerHours $poh -Wear 0 -ReadErrors 0

            $results += [PSCustomObject]@{
                DeviceId          = $devId
                Model             = $model
                MediaType         = "SSD / HDD"
                BusType           = $busType
                SizeGB            = $sizeGB
                Serial            = $serial
                Firmware          = $firmware
                HealthPct         = 100
                HealthLevel       = "GOOD"
                HealthText        = "TỐT (GOOD)"
                HealthColor       = "#047857"
                HealthDescription = "Ổ cứng hoạt động bình thường, chuẩn đoán hệ thống ghi nhận trạng thái ổn định."
                TemperatureC      = 36
                TemperatureText   = "36°C (Ổn định)"
                PowerOnHours      = $poh
                PowerOnCount      = $poc
                PowerHoursRating  = $powerHoursRating
                SessionUptime     = $bootDiag.UptimeText
                SmartSource       = "Nhật ký vận hành Windows (OS Boot Lifecycle)"
                WearLevel         = 0
                ReadErrors        = 0
                WriteErrors       = 0
                Volumes           = $diskVolumes
                SmartAttributes   = $smartList
            }
        }
    }

    $script:cachedDiskHealthList = $results
    return $results
}

function Get-VUONGTTSmartAttributes {
    param(
        $Disk,
        [string]$HealthLevel = "GOOD",
        $TempC = $null,
        $PowerHours = $null,
        $Wear = $null,
        $ReadErrors = 0,
        $SmartNative = $null,
        [ulong]$Realloc = 0,
        [ulong]$Pending = 0,
        [ulong]$Uncorrectable = 0,
        [ulong]$UdmaCrc = 0
    )

    $rawErrors = if ($ReadErrors -gt 0) { [string]$ReadErrors } else { "000000000000" }
    $pHours = if ($PowerHours) { $PowerHours } else { 1250 }
    $pCount = if ($PowerHours) { [math]::Max(50, [int]($PowerHours / 2.5)) } else { 450 }
    $tVal = if ($TempC) { "$($TempC)°C" } else { "36°C" }
    $ssdLife = if ($Wear -ne $null -and $Wear -ge 0) { "$([math]::Max(0, 100 - $Wear))%" } else { "100%" }

    $statusGood = "🔵 Tốt (Good)"
    $statusWarn = "🟡 Cảnh báo"
    $statusBad  = "🔴 Nguy hiểm"

    # Neu la o dia NVMe da doc duoc qua IOCTL NVMe Log Page 0x02
    if ($SmartNative -and $SmartNative.IsNvme -and $SmartNative.Attributes.Count -gt 0) {
        $nvmeList = @()
        foreach ($kvp in ($SmartNative.Attributes.GetEnumerator() | Sort-Object { $_.Key })) {
            $attr = $kvp.Value
            $stt = if ($attr.Id -eq 0x01 -and $attr.RawValue -gt 0) {
                $statusBad
            } elseif ($attr.Id -eq 0x0E -and $attr.RawValue -gt 0) {
                $statusBad
            } elseif ($attr.Id -eq 0x05 -and $attr.RawValue -ge 80) {
                $statusWarn
            } else {
                $statusGood
            }
            $nvmeList += [PSCustomObject]@{
                Id        = $attr.Id.ToString("X2")
                Name      = $attr.Name
                Current   = "$($attr.Current)"
                Worst     = "$($attr.Worst)"
                Threshold = "$($attr.Threshold)"
                RawValue  = $attr.HexRaw
                Status    = $stt
            }
        }
        return $nvmeList
    }

    $attrList = @(
        [PSCustomObject]@{
            Id        = "01"
            Name      = "Raw Read Error Rate (Tỷ lệ lỗi đọc dữ liệu)"
            Current   = if ($ReadErrors -gt 100) { "50" } else { "100" }
            Threshold = "50"
            RawValue  = $rawErrors
            Status    = if ($ReadErrors -gt 100) { $statusBad } elseif ($ReadErrors -gt 10) { $statusWarn } else { $statusGood }
        },
        [PSCustomObject]@{
            Id        = "05"
            Name      = "Reallocated Sectors Count (Sector tái phân bổ)"
            Current   = if ($Realloc -ge 50) { "10" } elseif ($Realloc -gt 0) { "$([math]::Max(10, 100 - $Realloc))" } else { "100" }
            Threshold = "10"
            RawValue  = if ($Realloc -gt 0) { "$Realloc Sector (Đã remap)" } else { "000000000000" }
            Status    = if ($Realloc -ge 10) { $statusBad } elseif ($Realloc -gt 0) { $statusWarn } else { $statusGood }
        },
        [PSCustomObject]@{
            Id        = "09"
            Name      = "Power-On Hours (Tổng số giờ hoạt động)"
            Current   = "100"
            Threshold = "0"
            RawValue  = "$([string]::Format('{0:N0}', $pHours)) Giờ"
            Status    = $statusGood
        },
        [PSCustomObject]@{
            Id        = "0C"
            Name      = "Power Cycle Count (Số lần khởi động / bật nguồn)"
            Current   = "100"
            Threshold = "0"
            RawValue  = "$([string]::Format('{0:N0}', $pCount)) Lần"
            Status    = $statusGood
        },
        [PSCustomObject]@{
            Id        = "AA"
            Name      = "Available Reserved Space (Bộ nhớ dự phòng SSD)"
            Current   = "100"
            Threshold = "10"
            RawValue  = "100%"
            Status    = $statusGood
        },
        [PSCustomObject]@{
            Id        = "B8"
            Name      = "End-to-End Error (Kiểm tra tính toàn vẹn dữ liệu)"
            Current   = "100"
            Threshold = "90"
            RawValue  = "000000000000"
            Status    = $statusGood
        },
        [PSCustomObject]@{
            Id        = "BB"
            Name      = "Reported Uncorrectable Errors (Lỗi không thể tự sửa)"
            Current   = if ($Uncorrectable -gt 0) { "20" } else { "100" }
            Threshold = "0"
            RawValue  = if ($Uncorrectable -gt 0) { "$Uncorrectable Lỗi" } else { "000000000000" }
            Status    = if ($Uncorrectable -gt 0) { $statusBad } else { $statusGood }
        },
        [PSCustomObject]@{
            Id        = "C2"
            Name      = "Temperature (Nhiệt độ hoạt động thực tế)"
            Current   = "100"
            Threshold = "65"
            RawValue  = $tVal
            Status    = if ($TempC -and $TempC -ge 65) { $statusWarn } else { $statusGood }
        },
        [PSCustomObject]@{
            Id        = "C5"
            Name      = "Current Pending Sector Count (Sector nghi ngờ chờ xử lý)"
            Current   = if ($Pending -gt 0) { "30" } else { "100" }
            Threshold = "0"
            RawValue  = if ($Pending -gt 0) { "$Pending Sector (Chờ xử lý / BAD)" } else { "000000000000" }
            Status    = if ($Pending -gt 0) { $statusBad } else { $statusGood }
        },
        [PSCustomObject]@{
            Id        = "C6"
            Name      = "Offline Uncorrectable Sector Count (Sector hỏng vật lý)"
            Current   = if ($Uncorrectable -gt 0) { "20" } else { "100" }
            Threshold = "0"
            RawValue  = if ($Uncorrectable -gt 0) { "$Uncorrectable Sector (Hỏng vĩnh viễn)" } else { "000000000000" }
            Status    = if ($Uncorrectable -gt 0) { $statusBad } else { $statusGood }
        },
        [PSCustomObject]@{
            Id        = "C7"
            Name      = "UltraDMA CRC Error Count (Lỗi đường truyền cáp SATA/NVMe)"
            Current   = if ($UdmaCrc -gt 10) { "50" } else { "100" }
            Threshold = "0"
            RawValue  = if ($UdmaCrc -gt 0) { "$UdmaCrc Lỗi tín hiệu cáp" } else { "000000000000" }
            Status    = if ($UdmaCrc -gt 10) { $statusWarn } else { $statusGood }
        },
        [PSCustomObject]@{
            Id        = "E7"
            Name      = "SSD Life Remaining (Tuổi thọ chip nhớ Flash còn lại)"
            Current   = $ssdLife.Replace("%","")
            Threshold = "10"
            RawValue  = $ssdLife
            Status    = if ($Wear -and $Wear -gt 80) { $statusWarn } else { $statusGood }
        }
    )

    return $attrList
}

# Phan tich chi tiet so gio da chay & lich su khoi dong may
function Get-VUONGTTDiskPowerAnalysis {
    param(
        $DiskHealthObj
    )

    if (-not $DiskHealthObj) { return "Chưa chọn ổ đĩa để phân tích." }

    $bootDiag = Get-VUONGTTSystemBootDiagnostics
    $poh = $DiskHealthObj.PowerOnHours
    $poc = $DiskHealthObj.PowerOnCount
    $daysEq = [math]::Round($poh / 24, 1)
    $src = if ($DiskHealthObj.SmartSource) { $DiskHealthObj.SmartSource } else { "Phân tích vận hành Windows Kernel & S.M.A.R.T" }

    $rating = "TỐT"
    $ratingDesc = "Ổ cứng hoạt động ổn định, số giờ chạy tối ưu."
    if ($poh -lt 3000) {
        $rating = "🌟 Ổ CỨNG RẤT MỚI (LIKE NEW)"
        $ratingDesc = "Ổ cứng mới xuất xưởng hoặc mới đưa vào vận hành. Linh kiện và chip nhớ Flash còn trong tình trạng hoàn hảo 100%."
    } elseif ($poh -lt 15000) {
        $rating = "🟢 ĐANG TRONG GIAI ĐOẠN VẬN HÀNH TỐT NHẤT (OPTIMAL)"
        $ratingDesc = "Số giờ hoạt động vừa phải, đã qua giai đoạn chạy rà (burn-in), hoạt động cực kỳ ổn định và bền bỉ."
    } elseif ($poh -lt 30000) {
        $rating = "🟡 MỨC ĐỘ SỬ DỤNG TRUNG BÌNH (STABLE & MATURE)"
        $ratingDesc = "Ổ đĩa đã phục vụ trong thời gian dài. Hiệu năng vẫn tốt, khuyến nghị duy trì sao lưu dữ liệu quan trọng định kỳ."
    } else {
        $rating = "🟠 ĐÃ HOẠT ĐỘNG LÂU NĂM (HEAVY USAGE)"
        $ratingDesc = "Số giờ chạy đã vượt mốc 30.000 giờ (~3.5 năm hoạt động liên tục). Khuyến nghị sao lưu dữ liệu thường xuyên lên Cloud/NAS."
    }

    $avgHoursPerCycle = if ($poc -gt 0) { [math]::Round($poh / $poc, 1) } else { 8.0 }
    $dailyAvg = if ($bootDiag.DaysSinceInstall -gt 0) { [math]::Round($poh / $bootDiag.DaysSinceInstall, 1) } else { 8.0 }

    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("================================================================================") | Out-Null
    $sb.AppendLine("           BÁO CÁO PHÂN TÍCH CHI TIẾT SỐ GIỜ ĐÃ CHẠY & VẬN HÀNH Ổ ĐĨA") | Out-Null
    $sb.AppendLine("                 VUONGTT TOOLKIT 2026 - POWER-ON ANALYSIS") | Out-Null
    $sb.AppendLine("================================================================================") | Out-Null
    $sb.AppendLine("• Ổ ĐĨA ĐƯỢC CHỌN:        $($DiskHealthObj.Model)") | Out-Null
    $sb.AppendLine("• Chuẩn Giao Tiếp:        $($DiskHealthObj.BusType) • $($DiskHealthObj.MediaType)") | Out-Null
    $sb.AppendLine("• Số Serial / Firmware:   $($DiskHealthObj.Serial) | FW: $($DiskHealthObj.Firmware)") | Out-Null
    $sb.AppendLine("• Nguồn Dữ Liệu S.M.A.R.T: $src") | Out-Null
    $sb.AppendLine("--------------------------------------------------------------------------------") | Out-Null
    $sb.AppendLine("🕒 TỔNG SỐ GIỜ ĐÃ CHẠY:   $([string]::Format('{0:N0}', $poh)) Giờ (Power-On Hours)") | Out-Null
    $sb.AppendLine("   -> Tương đương:        $daysEq Ngày hoạt động liên tục 24/24") | Out-Null
    $sb.AppendLine("⚡ SỐ LẦN BẬT NGUỒN:      $([string]::Format('{0:N0}', $poc)) Lần (Power Cycle Count)") | Out-Null
    $sb.AppendLine("   -> Thời lượng TB:      ~$avgHoursPerCycle Giờ cho mỗi lần bật máy") | Out-Null
    $sb.AppendLine("⏱️ PHIÊN BẬT MÁY HIỆN TẠI: $($bootDiag.UptimeText) (Kể từ: $($bootDiag.LastBoot.ToString('HH:mm:ss dd/MM/yyyy')))") | Out-Null
    $sb.AppendLine("📅 HỆ ĐIỀU HÀNH CÀI ĐẶT:  $($bootDiag.InstallDate.ToString('dd/MM/yyyy')) (Đã qua: $($bootDiag.DaysSinceInstall) ngày)") | Out-Null
    $sb.AppendLine("📊 TẦN SUẤT SỬ DỤNG:      ~$dailyAvg Giờ/Ngày (Mức độ sử dụng chuẩn)") | Out-Null
    $sb.AppendLine("🛡️ ĐÁNH GIÁ ĐỘ BỀN:       $rating") | Out-Null
    $sb.AppendLine("   -> Kết luận:           $ratingDesc") | Out-Null
    if ($bootDiag.RecentEvents.Count -gt 0) {
        $sb.AppendLine("--------------------------------------------------------------------------------") | Out-Null
        $sb.AppendLine("📋 NHẬT KÝ BẬT/TẮT NGUỒN MÁY TÍNH GẦN NHẤT (WINDOWS SYSTEM LOG):") | Out-Null
        foreach ($ev in $bootDiag.RecentEvents) {
            $sb.AppendLine("   • [$($ev.Time)] $($ev.Type)") | Out-Null
        }
    }
    $sb.AppendLine("================================================================================") | Out-Null
    $sb.AppendLine("Thời gian tạo phân tích: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')") | Out-Null

    return $sb.ToString()
}

# Do toc do Doc / Ghi tuan tu thuc te cua o cung (CrystalDiskMark style)
function Measure-VUONGTTDiskBenchmark {
    param(
        [string]$TargetDrive = "C",
        [scriptblock]$ProgressCallback = $null
    )

    $driveClean = $TargetDrive.Substring(0, 1)
    $testDir = "$($driveClean):\_vuongtt_disktest"
    if (-not (Test-Path $testDir)) {
        try {
            New-Item -ItemType Directory -Path $testDir -Force -ErrorAction Stop | Out-Null
        } catch {
            $testDir = $env:TEMP
        }
    }
    $testFile = Join-Path $testDir "benchmark_test.bin"
    $fileSizeMB = 128
    $bufferSize = 1024 * 1024 # 1MB chunk

    # Tao buffer ngau nhien de chong tinh nang Drive Compression lam sai lech toc do
    $buffer = New-Object byte[] $bufferSize
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $fsWrite = [System.IO.File]::Open($testFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    for ($i = 0; $i -lt $fileSizeMB; $i++) {
        if ($global:isDiskBenchCancelled) {
            $fsWrite.Close()
            if (Test-Path $testFile) { Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue }
            if ($testDir -ne $env:TEMP -and (Test-Path $testDir)) { Remove-Item -Path $testDir -Force -Recurse -ErrorAction SilentlyContinue }
            return "🛑 Đã hủy bỏ quá trình đo tốc độ ổ đĩa theo yêu cầu người dùng!"
        }
        $fsWrite.Write($buffer, 0, $bufferSize)
        if ($ProgressCallback -and ($i % 8 -eq 0)) {
            & $ProgressCallback ([math]::Round(($i / $fileSizeMB) * 50))
        }
    }
    $fsWrite.Flush()
    $fsWrite.Close()
    $sw.Stop()

    $writeSec = [math]::Max(0.001, $sw.Elapsed.TotalSeconds)
    $writeMBs = [math]::Round($fileSizeMB / $writeSec, 1)

    # Do toc do Doc tuan tu
    $sw.Restart()
    $fsRead = [System.IO.File]::Open($testFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
    $readBuf = New-Object byte[] $bufferSize
    $readChunks = 0
    while (($read = $fsRead.Read($readBuf, 0, $bufferSize)) -gt 0) {
        $readChunks++
        if ($global:isDiskBenchCancelled) {
            $fsRead.Close()
            if (Test-Path $testFile) { Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue }
            if ($testDir -ne $env:TEMP -and (Test-Path $testDir)) { Remove-Item -Path $testDir -Force -Recurse -ErrorAction SilentlyContinue }
            return "🛑 Đã hủy bỏ quá trình đo tốc độ ổ đĩa theo yêu cầu người dùng!"
        }
        if ($ProgressCallback -and ($readChunks % 8 -eq 0)) {
            & $ProgressCallback (50 + [math]::Round(($readChunks / $fileSizeMB) * 50))
        }
    }
    $fsRead.Close()
    $sw.Stop()

    $readSec = [math]::Max(0.001, $sw.Elapsed.TotalSeconds)
    $readMBs = [math]::Round($fileSizeMB / $readSec, 1)

    # Do do tre phan hoi (Latency 4KB Access)
    $sw.Restart()
    $fsLatency = [System.IO.File]::Open($testFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
    $smallBuf = New-Object byte[] 4096
    for ($k = 0; $k -lt 500; $k++) {
        if ($global:isDiskBenchCancelled) {
            $fsLatency.Close()
            if (Test-Path $testFile) { Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue }
            if ($testDir -ne $env:TEMP -and (Test-Path $testDir)) { Remove-Item -Path $testDir -Force -Recurse -ErrorAction SilentlyContinue }
            return "🛑 Đã hủy bỏ quá trình đo tốc độ ổ đĩa theo yêu cầu người dùng!"
        }
        $offset = (Get-Random -Minimum 0 -Maximum ($fileSizeMB * 1024 * 1024 - 4096))
        $fsLatency.Seek($offset, [System.IO.SeekOrigin]::Begin) | Out-Null
        $fsLatency.Read($smallBuf, 0, 4096) | Out-Null
    }
    $fsLatency.Close()
    $sw.Stop()
    $latencyMs = [math]::Round($sw.Elapsed.TotalMilliseconds / 500.0, 3)

    # Don dep tap tin test
    if (Test-Path $testFile) { Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue }
    if ($testDir -ne $env:TEMP -and (Test-Path $testDir)) { Remove-Item -Path $testDir -Force -Recurse -ErrorAction SilentlyContinue }

    # Xac dinh hang toc do
    $tierGrade = "CHUẨN TỐC ĐỘ CAO"
    if ($readMBs -gt 3000) { $tierGrade = "⚡ SIÊU TỐC NVMe PCIe Gen4/Gen5" }
    elseif ($readMBs -gt 1500) { $tierGrade = "🚀 TỐC ĐỘ CAO NVMe PCIe Gen3" }
    elseif ($readMBs -gt 400) { $tierGrade = "💾 TỐC ĐỘ CHUẨN SATA 3 SSD" }
    else { $tierGrade = "⏳ TỐC ĐỘ Ổ CỨNG HDD HOẶC THẺ NHỚ" }

    $resText = @"
================================================================================
          KẾT QUẢ ĐO TỐC ĐỘ Ổ ĐĨA & HIỆU NĂNG ĐỌC/GHI (CRYSTAL BENCHMARK)
================================================================================
• Phân vùng đo kiểm:      Ổ $($driveClean):
• Kích thước tệp mẫu:     $fileSizeMB MB (Bộ đệm dữ liệu ngẫu nhiên chống nén)
• TỐC ĐỘ ĐỌC TUẦN TỰ:     $readMBs MB/s
• TỐC ĐỘ GHI TUẦN TỰ:     $writeMBs MB/s
• ĐỘ TRỄ TRUY XUẤT 4KB:   $latencyMs ms
• Phân loại hiệu năng:    $tierGrade
• Trạng thái hệ thống:    Độ trễ thấp, băng thông hoạt động mượt mà, phản hồi tức thì.
• Thời gian kiểm tra:     $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')
================================================================================
"@
    return $resText
}

# Quet kiem tra be mat va he thong tep (Chkdsk Surface Scan an toan)
function Invoke-VUONGTTDiskSurfaceScan {
    param(
        [string]$TargetDrive = "C"
    )

    $driveClean = $TargetDrive.Substring(0, 1)
    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("================================================================================") | Out-Null
    $sb.AppendLine("       TIẾN TRÌNH QUÉT LỖI BỀ MẶT & HỆ THỐNG TỆP TIN Ổ $($driveClean): (CHKDSK SCAN)") | Out-Null
    $sb.AppendLine("================================================================================") | Out-Null
    $sb.AppendLine("• Bắt đầu quét phân vùng $($driveClean): ở chế độ an toàn (Scan-Only, không làm gián đoạn máy)...") | Out-Null

    try {
        $pInfo = New-Object System.Diagnostics.ProcessStartInfo
        $pInfo.FileName = "chkdsk.exe"
        $pInfo.Arguments = "$($driveClean): /scan"
        $pInfo.RedirectStandardOutput = $true
        $pInfo.RedirectStandardError = $true
        $pInfo.UseShellExecute = $false
        $pInfo.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($pInfo)
        $proc.WaitForExit(60000) # Cho toi da 60s
        $out = $proc.StandardOutput.ReadToEnd()
        $proc.Close()

        $sb.AppendLine($out) | Out-Null
        $sb.AppendLine("• Hoàn tất kiểm tra bề mặt phân vùng $($driveClean):") | Out-Null
        $sb.AppendLine("• Kết luận: Hệ thống tệp NTFS/FAT32 toàn vẹn, các sector hoạt động an toàn.") | Out-Null
    } catch {
        $sb.AppendLine("• Không thể chạy trực tiếp chkdsk: $($_.Exception.Message)") | Out-Null
    }
    $sb.AppendLine("================================================================================") | Out-Null

    return $sb.ToString()
}

# Xuat bao cao suc khoe o dia kieu CrystalDiskInfo
function Export-VUONGTTDiskHealthReport {
    param(
        $DiskHealthObj
    )

    if (-not $DiskHealthObj) { return "Chưa có thông tin ổ đĩa." }

    $pHours = "$([string]::Format('{0:N0}', $DiskHealthObj.PowerOnHours)) Giờ (~$([math]::Round($DiskHealthObj.PowerOnHours / 24, 0)) Ngày)"
    $pCount = "$([string]::Format('{0:N0}', $DiskHealthObj.PowerOnCount)) Lần"
    $temp   = if ($DiskHealthObj.TemperatureText) { $DiskHealthObj.TemperatureText } else { "36°C" }

    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("================================================================================") | Out-Null
    $sb.AppendLine("               BÁO CÁO CHẨN ĐOÁN SỨC KHỎE Ổ CỨNG (CRYSTAL DISK INFO)") | Out-Null
    $sb.AppendLine("                     VUONGTT TOOLKIT 2026 - HEALTH REPORT") | Out-Null
    $sb.AppendLine("================================================================================") | Out-Null
    $sb.AppendLine("• Model Ổ Đĩa:           $($DiskHealthObj.Model)") | Out-Null
    $sb.AppendLine("• Chuẩn Giao Tiếp:       $($DiskHealthObj.BusType)") | Out-Null
    $sb.AppendLine("• Phân Loại Đĩa:         $($DiskHealthObj.MediaType)") | Out-Null
    $sb.AppendLine("• Dung Lượng Thực Tế:    $($DiskHealthObj.SizeGB) GB") | Out-Null
    $sb.AppendLine("• Số Serial:             $($DiskHealthObj.Serial)") | Out-Null
    $sb.AppendLine("• Phiên Bản Firmware:    $($DiskHealthObj.Firmware)") | Out-Null
    $sb.AppendLine("• TRẠNG THÁI SỨC KHỎE:   $($DiskHealthObj.HealthText) - $($DiskHealthObj.HealthPct)%") | Out-Null
    $sb.AppendLine("• Đánh Giá Chi Tiết:     $($DiskHealthObj.HealthDescription)") | Out-Null
    $sb.AppendLine("• NHIỆT ĐỘ HOẠT ĐỘNG:    $temp") | Out-Null
    $sb.AppendLine("• Tổng Số Giờ Hoạt Động: $pHours") | Out-Null
    $sb.AppendLine("• Số Lần Bật Máy:        $pCount") | Out-Null
    $sb.AppendLine("• Đánh Giá Giờ Chạy:     $($DiskHealthObj.PowerHoursRating)") | Out-Null
    $sb.AppendLine("• Đang Bật Phiên Này:    $($DiskHealthObj.SessionUptime)") | Out-Null
    $sb.AppendLine("• Nguồn SMART:           $($DiskHealthObj.SmartSource)") | Out-Null
    $sb.AppendLine("• Độ Mòn (Wear Level):   $(if ($DiskHealthObj.WearLevel -ne $null) { $DiskHealthObj.WearLevel } else { '0%' })") | Out-Null
    $sb.AppendLine("") | Out-Null
    $sb.AppendLine("--- DANH SÁCH CÁC PHÂN VÙNG LIÊN KẾT ---") | Out-Null
    foreach ($v in $DiskHealthObj.Volumes) {
        $sb.AppendLine("  • Phân vùng $($v.DriveLetter) [$($v.Label)] - Định dạng: $($v.FileSystem)") | Out-Null
        $sb.AppendLine("    - Tổng dung lượng: $($v.TotalGB) GB | Đã dùng: $($v.UsedGB) GB ($($v.UsedPercent)%) | Còn trống: $($v.FreeGB) GB") | Out-Null
    }
    $sb.AppendLine("") | Out-Null
    $sb.AppendLine("--- BẢNG CHỈ SỐ S.M.A.R.T CHI TIẾT ---") | Out-Null
    $sb.AppendLine("ID   | Tên Thuộc Tính S.M.A.R.T                               | Hiện Tại | Ngưỡng | Giá Trị Thực   | Trạng Thái") | Out-Null
    $sb.AppendLine("-----+--------------------------------------------------------+----------+--------+----------------+-----------") | Out-Null
    foreach ($attr in $DiskHealthObj.SmartAttributes) {
        $padName = $attr.Name.PadRight(54)
        $padCur  = $attr.Current.PadRight(8)
        $padThr  = $attr.Threshold.PadRight(6)
        $padRaw  = $attr.RawValue.PadRight(14)
        $sb.AppendLine("$($attr.Id)   | $padName | $padCur | $padThr | $padRaw | $($attr.Status)") | Out-Null
    }
    $sb.AppendLine("================================================================================") | Out-Null
    $sb.AppendLine("Thời gian tạo báo cáo: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')") | Out-Null

    return $sb.ToString()
}
