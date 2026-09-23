using System;
using System.IO;
using System.Reflection;
using System.Diagnostics;
using System.Security.Principal;
using System.Windows.Forms;
using System.Threading;
using System.Drawing;
using System.Net;

[assembly: AssemblyTitle("VUONGTT Tool Pro 2026")]
[assembly: AssemblyDescription("Bộ công cụ kỹ thuật viên đa năng VUONGTT Tool Pro 2026")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("VUONGTT Software")]
[assembly: AssemblyProduct("VUONGTT Tool Pro 2026")]
[assembly: AssemblyCopyright("Copyright © 2026 VUONGTT. All rights reserved.")]
[assembly: AssemblyTrademark("VUONGTT")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyVersion("20.5.909.13")]
[assembly: AssemblyFileVersion("20.5.909.13")]

namespace VUONGTT
{
    static class Program
    {
        private static Form splash = null;

        private static void ShowSplash()
        {
            Thread t = new Thread(() =>
            {
                try
                {
                    splash = new Form();
                    splash.FormBorderStyle = FormBorderStyle.None;
                    splash.StartPosition = FormStartPosition.CenterScreen;
                    splash.Size = new Size(390, 130);
                    splash.BackColor = Color.FromArgb(15, 23, 42); // Dark Slate
                    splash.TopMost = true;

                    Label lblTitle = new Label();
                    lblTitle.Text = "⚡ VUONGTT TOOL PRO 2026";
                    lblTitle.ForeColor = Color.FromArgb(245, 158, 11); // Warm Amber
                    lblTitle.Font = new Font("Segoe UI", 12, FontStyle.Bold);
                    lblTitle.Location = new Point(20, 18);
                    lblTitle.AutoSize = true;

                    Label lblSub = new Label();
                    lblSub.Text = "Đang khởi động hệ thống siêu tốc... Vui lòng chờ!";
                    lblSub.ForeColor = Color.FromArgb(226, 232, 240);
                    lblSub.Font = new Font("Segoe UI", 9, FontStyle.Regular);
                    lblSub.Location = new Point(22, 48);
                    lblSub.AutoSize = true;

                    ProgressBar pb = new ProgressBar();
                    pb.Style = ProgressBarStyle.Marquee;
                    pb.MarqueeAnimationSpeed = 15;
                    pb.Size = new Size(346, 6);
                    pb.Location = new Point(22, 78);

                    Label lblVer = new Label();
                    string verStr = Assembly.GetExecutingAssembly().GetName().Version.ToString();
                    lblVer.Text = "v" + verStr + " • Professional Standalone (All-in-One)";
                    lblVer.ForeColor = Color.FromArgb(148, 163, 184);
                    lblVer.Font = new Font("Segoe UI", 7.5f, FontStyle.Regular);
                    lblVer.Location = new Point(22, 98);
                    lblVer.AutoSize = true;

                    splash.Controls.Add(lblTitle);
                    splash.Controls.Add(lblSub);
                    splash.Controls.Add(pb);
                    splash.Controls.Add(lblVer);

                    splash.Paint += (s, pe) =>
                    {
                        using (Pen pen = new Pen(Color.FromArgb(217, 119, 6), 2f))
                        {
                            pe.Graphics.DrawRectangle(pen, 0, 0, splash.Width - 1, splash.Height - 1);
                        }
                    };

                    Application.Run(splash);
                }
                catch { }
            });
            t.SetApartmentState(ApartmentState.STA);
            t.IsBackground = true;
            t.Start();
        }

        private static void CloseSplash()
        {
            try
            {
                if (splash != null && splash.IsHandleCreated && splash.InvokeRequired)
                {
                    splash.Invoke(new MethodInvoker(() =>
                    {
                        splash.Close();
                        splash.Dispose();
                        splash = null;
                    }));
                }
                else if (splash != null)
                {
                    splash.Close();
                    splash.Dispose();
                    splash = null;
                }
            }
            catch { }
        }

        [STAThread]
        static void Main(string[] args)
        {
            bool isSmokeTest = false;
            if (args != null && args.Length > 0)
            {
                for (int i = 0; i < args.Length; i++)
                {
                    if (string.Equals(args[i], "--smoke-test", StringComparison.OrdinalIgnoreCase))
                    {
                        isSmokeTest = true;
                        break;
                    }
                }
            }

            try
            {
                // Kiểm tra và tự động yêu cầu quyền Administrator
                WindowsPrincipal principal = new WindowsPrincipal(WindowsIdentity.GetCurrent());
                if (!principal.IsInRole(WindowsBuiltInRole.Administrator))
                {
                    ProcessStartInfo startInfo = new ProcessStartInfo();
                    startInfo.UseShellExecute = true;
                    startInfo.WorkingDirectory = AppDomain.CurrentDomain.BaseDirectory;
                    startInfo.FileName = Application.ExecutablePath;
                    if (args != null && args.Length > 0)
                    {
                        startInfo.Arguments = string.Join(" ", args);
                    }
                    startInfo.Verb = "runas";
                    try
                    {
                        Process elevated = Process.Start(startInfo);
                        if (isSmokeTest && elevated != null)
                        {
                            elevated.WaitForExit();
                            Environment.Exit(elevated.ExitCode);
                            return;
                        }
                    }
                    catch
                    {
                        if (!isSmokeTest)
                        {
                            MessageBox.Show("Vui lòng đồng ý cấp quyền Quản trị viên (Run as Administrator) để sử dụng VUONGTT Tool Pro 2026.", "Yêu cầu quyền Administrator", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        }
                        else
                        {
                            Environment.Exit(1);
                        }
                    }
                    return;
                }

                // Hiển thị Splash Screen tức thì trong 50ms đầu tiên
                ShowSplash();

                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string scriptPath = Path.Combine(baseDir, "VUONGTT_Toolkit.ps1");

                // Nếu chạy file .exe độc lập (không có source cạnh bên), giải nén tài nguyên vào thư mục Temp
                if (!File.Exists(scriptPath))
                {
                    string tempDir = Path.Combine(Path.GetTempPath(), "VUONGTT_Toolkit_Runtime");
                    if (!Directory.Exists(tempDir))
                    {
                        Directory.CreateDirectory(tempDir);
                    }

                    Assembly asm = Assembly.GetExecutingAssembly();
                    string[] resNames = asm.GetManifestResourceNames();

                    foreach (string name in resNames)
                    {
                        string relPath = "";
                        if (name.Contains("VUONGTT_Toolkit.ps1")) relPath = "VUONGTT_Toolkit.ps1";
                        else if (name.Contains("MainWindow.xaml")) relPath = Path.Combine("src", "UI", "MainWindow.xaml");
                        else if (name.Contains("OfficeAIOModal.xaml")) relPath = Path.Combine("src", "UI", "OfficeAIOModal.xaml");
                        else if (name.Contains("HardwareInfo.ps1")) relPath = Path.Combine("src", "Core", "HardwareInfo.ps1");
                        else if (name.Contains("OfficeInstaller.ps1")) relPath = Path.Combine("src", "Core", "OfficeInstaller.ps1");
                        else if (name.Contains("Activator.ps1")) relPath = Path.Combine("src", "Core", "Activator.ps1");
                        else if (name.Contains("NetworkPrinterFix.ps1")) relPath = Path.Combine("src", "Core", "NetworkPrinterFix.ps1");
                        else if (name.Contains("SystemTweaks.ps1")) relPath = Path.Combine("src", "Core", "SystemTweaks.ps1");
                        else if (name.Contains("BitLockerManager.ps1")) relPath = Path.Combine("src", "Core", "BitLockerManager.ps1");
                        else if (name.Contains("SoftwareInstaller.ps1")) relPath = Path.Combine("src", "Core", "SoftwareInstaller.ps1");
                        else if (name.Contains("SystemCustomizer.ps1")) relPath = Path.Combine("src", "Core", "SystemCustomizer.ps1");
                        else if (name.Contains("UserManager.ps1")) relPath = Path.Combine("src", "Core", "UserManager.ps1");
                        else if (name.Contains("CpuMainDatabase.ps1")) relPath = Path.Combine("src", "Core", "CpuMainDatabase.ps1");
                        else if (name.Contains("LaptopTester.ps1")) relPath = Path.Combine("src", "Core", "LaptopTester.ps1");
                        else if (name.Contains("FontInstaller.ps1")) relPath = Path.Combine("src", "Core", "FontInstaller.ps1");
                        else if (name.Contains("PartitionManager.ps1")) relPath = Path.Combine("src", "Core", "PartitionManager.ps1");
                        else if (name.Contains("AccountingApps.ps1")) relPath = Path.Combine("src", "Core", "AccountingApps.ps1");
                        else if (name.Contains("AppUpdater.ps1")) relPath = Path.Combine("src", "Core", "AppUpdater.ps1");
                        else if (name.Contains("LicenseManager.ps1")) relPath = Path.Combine("src", "Core", "LicenseManager.ps1");
                        else if (name.Contains("IpScanner.ps1")) relPath = Path.Combine("src", "Core", "IpScanner.ps1");
                        else if (name.Contains("ConfigManager.ps1")) relPath = Path.Combine("src", "Core", "ConfigManager.ps1");
                        else if (name.Contains("DiskHealthManager.ps1")) relPath = Path.Combine("src", "Core", "DiskHealthManager.ps1");
                        else if (name.Contains("AutoWinDeployer.ps1")) relPath = Path.Combine("src", "Core", "AutoWinDeployer.ps1");
                        else if (name.Contains("SystemBackupManager.ps1")) relPath = Path.Combine("src", "Core", "SystemBackupManager.ps1");
                        else if (name.Contains("licenses_vault.json")) relPath = Path.Combine("src", "Config", "licenses_vault.json");
                        else if (name.Contains("feature_policy.json")) relPath = Path.Combine("src", "Config", "feature_policy.json");
                        else if (name.Contains("SoftwareDatabase.json")) relPath = Path.Combine("src", "Data", "SoftwareDatabase.json");
                        else if (name.Contains("version.json")) relPath = "version.json";
                        else if (name.StartsWith("VUONGTT.AppIcons."))
                        {
                            string iconFileName = name.Substring("VUONGTT.AppIcons.".Length);
                            relPath = Path.Combine("src", "Assets", "AppIcons", iconFileName);
                        }

                        if (!string.IsNullOrEmpty(relPath))
                        {
                            string dest = Path.Combine(tempDir, relPath);
                            string destSubDir = Path.GetDirectoryName(dest);
                            if (!Directory.Exists(destSubDir)) Directory.CreateDirectory(destSubDir);

                            using (Stream s = asm.GetManifestResourceStream(name))
                            using (FileStream fs = new FileStream(dest, FileMode.Create, FileAccess.Write))
                            {
                                s.CopyTo(fs);
                            }
                        }
                    }
                    scriptPath = Path.Combine(tempDir, "VUONGTT_Toolkit.ps1");
                }

                string currentExe = Application.ExecutablePath;

                // CƠ CHẾ NÂNG CẤP TỰ ĐỘNG TẦNG C# (NATIVE AUTO-UPDATE APPLIER)
                // Kiểm tra nếu có bản cập nhật đã tải sẵn trong Temp từ phiên làm việc trước
                try
                {
                    string tempPath = Path.GetTempPath();
                    string[] readyFiles = Directory.GetFiles(tempPath, "VUONGTT_Toolkit_v*_READY.exe");
                    if (readyFiles != null && readyFiles.Length > 0)
                    {
                        Array.Sort(readyFiles);
                        string newestReady = readyFiles[readyFiles.Length - 1];
                        FileInfo fi = new FileInfo(newestReady);
                        if (fi.Exists && fi.Length > 1000000)
                        {
                            FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(newestReady);
                            Version readyVer = null;
                            Version curVer = Assembly.GetExecutingAssembly().GetName().Version;
                            if (Version.TryParse(fvi.FileVersion, out readyVer) && readyVer > curVer)
                            {
                                CloseSplash();
                                string updaterCmd = Path.Combine(tempPath, "VUONGTT_HotSwap_Staged.cmd");
                                string cmdLines = "@echo off\r\n" +
                                    "title VUONGTT Toolkit Auto Update Apply\r\n" +
                                    "taskkill /f /im \"VUONGTT_Toolkit.exe\" >nul 2>&1\r\n" +
                                    "timeout /t 1 /nobreak >nul\r\n" +
                                    "copy /y \"" + newestReady + "\" \"" + currentExe + "\" >nul\r\n" +
                                    "del /f /q \"" + newestReady + "\" >nul 2>&1\r\n" +
                                    "start \"\" \"" + currentExe + "\"\r\n" +
                                    "del /f /q \"%~f0\" >nul 2>&1\r\n" +
                                    "exit\r\n";
                                File.WriteAllText(updaterCmd, cmdLines, System.Text.Encoding.Default);
                                ProcessStartInfo cmdPsi = new ProcessStartInfo();
                                cmdPsi.FileName = updaterCmd;
                                cmdPsi.WindowStyle = ProcessWindowStyle.Hidden;
                                cmdPsi.UseShellExecute = true;
                                Process.Start(cmdPsi);
                                Environment.Exit(0);
                                return;
                            }
                        }
                    }
                }
                catch { }

                string runtimeDir = Path.GetDirectoryName(scriptPath);
                try
                {
                    File.WriteAllText(Path.Combine(runtimeDir, "launcher_info.txt"), currentExe);
                    string tempRuntime = Path.Combine(Path.GetTempPath(), "VUONGTT_Toolkit_Runtime");
                    if (Directory.Exists(tempRuntime))
                    {
                        File.WriteAllText(Path.Combine(tempRuntime, "launcher_info.txt"), currentExe);
                    }
                    Environment.SetEnvironmentVariable("VUONGTT_ORIGINAL_EXE", currentExe);
                }
                catch { }

                // Khởi động PowerShell với chế độ Single Thread Apartment (-Sta) và thực thi ẩn Console
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";
                psi.Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File \"{0}\" \"{1}\"", scriptPath, currentExe);
                psi.WorkingDirectory = runtimeDir;
                psi.WindowStyle = ProcessWindowStyle.Hidden;
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                psi.EnvironmentVariables["VUONGTT_ORIGINAL_EXE"] = currentExe;

                DateTime startTime = DateTime.UtcNow;
                Process proc = Process.Start(psi);

                // Giữ Splash Screen trong khoảng 2.0 giây cho đến khi cửa sổ chính WPF sẵn sàng
                Thread.Sleep(2000);
                CloseSplash();

                if (proc != null)
                {
                    // Tự động đóng tiến trình con PowerShell nếu tiến trình C# launcher bị tắt
                    AppDomain.CurrentDomain.ProcessExit += delegate
                    {
                        try
                        {
                            if (proc != null && !proc.HasExited)
                            {
                                proc.Kill();
                            }
                        }
                        catch { }
                    };

                    // Giai đoạn giám sát tiền khởi động (Early Boot Phase: 3.5 giây tiếp theo):
                    // Theo dõi tiến trình PowerShell xem có bị crash đột ngột do lỗi cú pháp, thiếu module hoặc lỗi XAML không
                    bool earlyExited = proc.WaitForExit(3500);
                    if (earlyExited)
                    {
                        int exitCode = 0;
                        try { exitCode = proc.ExitCode; } catch { }

                        // Chỉ kích hoạt Self-Healing nếu tiến trình thực sự bị văng lỗi (exitCode != 0)
                        if (exitCode != 0)
                        {
                            if (isSmokeTest)
                            {
                                // Chế độ Smoke Test: Thoát ngay với mã lỗi để CI/Release script bắt được tức thì
                                Environment.Exit(exitCode);
                                return;
                            }

                            PerformSelfHealingPrompt(currentExe, exitCode);
                            return;
                        }
                        else
                        {
                            // Tiến trình PowerShell đã chủ động kết thúc hợp lệ (ví dụ: chuyển giao cho kịch bản Self-Update)
                            Environment.Exit(0);
                            return;
                        }
                    }
                    else
                    {
                        // Ứng dụng đã vượt qua giai đoạn khởi động an toàn và đang chạy bình thường.
                        // Tiếp tục giữ tiến trình C# đồng hành cho đến khi người dùng chủ động đóng tool.
                        proc.WaitForExit();
                    }
                }
            }
            catch (Exception ex)
            {
                CloseSplash();
                MessageBox.Show("Lỗi khởi chạy VUONGTT Tool Pro 2026: " + ex.Message, "Lỗi VUONGTT", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private static void PerformSelfHealingPrompt(string currentExe, int exitCode)
        {
            CloseSplash();
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            bool isDevRepo = Directory.Exists(Path.Combine(baseDir, ".git")) ||
                             File.Exists(Path.Combine(baseDir, "Publish-Update.ps1"));

            if (isDevRepo)
            {
                string devMsg = string.Format(
                    "CẢNH BÁO: Phát hiện tiến trình PowerShell bị văng khi khởi chạy (ExitCode: {0}).\n\n" +
                    "Bạn đang chạy trực tiếp từ thư mục mã nguồn phát triển (Dev Environment).\n" +
                    "Khuyến nghị: Kiểm tra lại mã nguồn PowerShell, lỗi cú pháp hoặc XAML trước khi biên dịch lại.\n\n" +
                    "Bạn có muốn kích hoạt C# Self-Healing để tải bản chuẩn từ GitHub về khôi phục không?",
                    exitCode);
                DialogResult dr = MessageBox.Show(devMsg, "VUONGTT Dev - Phát Hiện Crash Khởi Động", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
                if (dr != DialogResult.Yes) return;
            }
            else
            {
                string clientMsg = string.Format(
                    "HỆ THỐNG PHÁT HIỆN SỰ CỐ KHỞI ĐỘNG (Mã lỗi: {0})!\n\n" +
                    "Tiến trình giao diện bị gián đoạn hoặc crash đột ngột trong những giây đầu.\n\n" +
                    "Cơ chế Tự Phục Hồi (C# Self-Healing Emergency Recovery) sẵn sàng kết nối\n" +
                    "trực tiếp tới máy chủ GitHub để tải bản vá sửa lỗi mới nhất và khôi phục ứng dụng.\n\n" +
                    "Bạn có muốn phục hồi ứng dụng ngay bây giờ không?",
                    exitCode);
                DialogResult dr = MessageBox.Show(clientMsg, "VUONGTT Tool Pro 2026 - C# Self-Healing Recovery", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button1);
                if (dr != DialogResult.Yes) return;
            }

            PerformSelfHealing(currentExe);
        }

        private static void PerformSelfHealing(string currentExe)
        {
            Form healForm = null;
            Label lblStatus = null;
            ProgressBar pb = null;

            try
            {
                healForm = new Form();
                healForm.FormBorderStyle = FormBorderStyle.FixedDialog;
                healForm.StartPosition = FormStartPosition.CenterScreen;
                healForm.MaximizeBox = false;
                healForm.MinimizeBox = false;
                healForm.Size = new Size(480, 165);
                healForm.BackColor = Color.FromArgb(15, 23, 42);
                healForm.ForeColor = Color.White;
                healForm.Text = "VUONGTT C# Self-Healing Emergency Recovery";
                healForm.TopMost = true;

                Label lblTitle = new Label();
                lblTitle.Text = "⚡ C# SELF-HEALING EMERGENCY RECOVERY";
                lblTitle.ForeColor = Color.FromArgb(245, 158, 11);
                lblTitle.Font = new Font("Segoe UI", 11, FontStyle.Bold);
                lblTitle.Location = new Point(20, 18);
                lblTitle.AutoSize = true;

                lblStatus = new Label();
                lblStatus.Text = "Đang kết nối GitHub và kiểm tra bản vá sửa lỗi...";
                lblStatus.ForeColor = Color.FromArgb(226, 232, 240);
                lblStatus.Font = new Font("Segoe UI", 9, FontStyle.Regular);
                lblStatus.Location = new Point(22, 48);
                lblStatus.Size = new Size(420, 25);

                pb = new ProgressBar();
                pb.Style = ProgressBarStyle.Marquee;
                pb.MarqueeAnimationSpeed = 20;
                pb.Size = new Size(420, 10);
                pb.Location = new Point(22, 80);

                Label lblFoot = new Label();
                lblFoot.Text = "Hệ thống tự động thay thế binary lỗi và hồi sinh ứng dụng không làm gián đoạn công việc.";
                lblFoot.ForeColor = Color.FromArgb(148, 163, 184);
                lblFoot.Font = new Font("Segoe UI", 7.5f, FontStyle.Regular);
                lblFoot.Location = new Point(22, 102);
                lblFoot.AutoSize = true;

                healForm.Controls.Add(lblTitle);
                healForm.Controls.Add(lblStatus);
                healForm.Controls.Add(pb);
                healForm.Controls.Add(lblFoot);

                healForm.Show();
                healForm.Refresh();
                Application.DoEvents();

                // Bật giao thức bảo mật mạng TLS 1.2
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 | (SecurityProtocolType)768 | SecurityProtocolType.Tls;
                ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };

                string downloadUrl = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/VUONGTT_Toolkit.exe";

                // Thử lấy link tải trực tiếp từ version.json nếu có
                try
                {
                    lblStatus.Text = "Đang truy vấn thông tin phát hành mới nhất từ Cloud...";
                    healForm.Refresh();
                    Application.DoEvents();

                    string verUrl = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/version.json?t=" + DateTime.UtcNow.Ticks;
                    using (WebClient wcVer = new WebClient())
                    {
                        wcVer.Headers.Add("User-Agent", "VUONGTT-Toolkit-SelfHealing/2026");
                        wcVer.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate");
                        string verJson = wcVer.DownloadString(verUrl);
                        if (!string.IsNullOrEmpty(verJson) && verJson.Contains("\"downloadUrl\""))
                        {
                            int idx = verJson.IndexOf("\"downloadUrl\"");
                            int colon = verJson.IndexOf(":", idx);
                            int quote1 = verJson.IndexOf("\"", colon);
                            int quote2 = verJson.IndexOf("\"", quote1 + 1);
                            if (quote1 > 0 && quote2 > quote1)
                            {
                                string extractedUrl = verJson.Substring(quote1 + 1, quote2 - quote1 - 1).Trim();
                                if (extractedUrl.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                                {
                                    downloadUrl = extractedUrl;
                                }
                            }
                        }
                    }
                }
                catch { }

                lblStatus.Text = "Đang tải bản vá sửa lỗi mới nhất từ máy chủ GitHub...";
                healForm.Refresh();
                Application.DoEvents();

                string tempExe = Path.Combine(Path.GetTempPath(), "VUONGTT_SelfHealed_" + Guid.NewGuid().ToString("N").Substring(0, 8) + ".exe");
                string downloadUrlBust = downloadUrl + (downloadUrl.Contains("?") ? "&" : "?") + "t=" + DateTime.UtcNow.Ticks;

                using (WebClient wc = new WebClient())
                {
                    wc.Headers.Add("User-Agent", "VUONGTT-Toolkit-SelfHealing/2026");
                    wc.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate");
                    wc.Headers.Add("Pragma", "no-cache");
                    wc.DownloadFile(downloadUrlBust, tempExe);
                }

                FileInfo fi = new FileInfo(tempExe);
                if (!fi.Exists || fi.Length < 50000)
                {
                    if (healForm != null) healForm.Close();
                    MessageBox.Show("Tải bản vá thất bại hoặc tập tin nhận về không hợp lệ! Vui lòng kiểm tra lại kết nối mạng Internet.", "Lỗi Phục Hồi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                lblStatus.Text = "Đã tải xong (" + Math.Round(fi.Length / 1024.0, 1) + " KB)! Đang tự động khôi phục và tái khởi động...";
                healForm.Refresh();
                Application.DoEvents();
                Thread.Sleep(800);

                string updaterCmd = Path.Combine(Path.GetTempPath(), "VUONGTT_SelfHealing_HotSwap.cmd");
                string cmdLines = "@echo off\r\n" +
                    "title VUONGTT Self-Healing Recovery\r\n" +
                    "echo ========================================================\r\n" +
                    "echo   VUONGTT TOOLKIT 2026 - C# SELF-HEALING RECOVERY\r\n" +
                    "echo ========================================================\r\n" +
                    "echo 1. Dang dong tien trinh cu de giai phong file lock...\r\n" +
                    "taskkill /f /im \"VUONGTT_Toolkit.exe\" >nul 2>&1\r\n" +
                    "timeout /t 2 /nobreak >nul\r\n\r\n" +
                    ":wait_loop\r\n" +
                    "tasklist /fi \"imagename eq VUONGTT_Toolkit.exe\" 2>nul | find /i \"VUONGTT_Toolkit.exe\" >nul\r\n" +
                    "if not errorlevel 1 (\r\n" +
                    "    timeout /t 1 /nobreak >nul\r\n" +
                    "    goto wait_loop\r\n" +
                    ")\r\n\r\n" +
                    "echo 2. Dang ghi de phien ban phuc hoi moi nhat...\r\n" +
                    "copy /y \"" + tempExe + "\" \"" + currentExe + "\" >nul\r\n" +
                    "if errorlevel 1 (\r\n" +
                    "    set \"FALLBACK_EXE=%USERPROFILE%\\Downloads\\VUONGTT_Toolkit_Healed.exe\"\r\n" +
                    "    copy /y \"" + tempExe + "\" \"%FALLBACK_EXE%\" >nul\r\n" +
                    "    del /f /q \"" + tempExe + "\" >nul 2>&1\r\n" +
                    "    start \"\" \"%FALLBACK_EXE%\"\r\n" +
                    "    del /f /q \"%~f0\" >nul 2>&1\r\n" +
                    "    exit\r\n" +
                    ")\r\n\r\n" +
                    "del /f /q \"" + tempExe + "\" >nul 2>&1\r\n" +
                    "echo 3. Khoi dong lai VUONGTT Tool Pro 2026 da duoc phuc hoi...\r\n" +
                    "start \"\" \"" + currentExe + "\"\r\n" +
                    "del /f /q \"%~f0\" >nul 2>&1\r\n" +
                    "exit\r\n";

                File.WriteAllText(updaterCmd, cmdLines, System.Text.Encoding.Default);

                ProcessStartInfo cmdPsi = new ProcessStartInfo();
                cmdPsi.FileName = updaterCmd;
                cmdPsi.WindowStyle = ProcessWindowStyle.Normal;
                cmdPsi.UseShellExecute = true;
                Process.Start(cmdPsi);

                if (healForm != null) healForm.Close();
                Environment.Exit(0);
            }
            catch (Exception ex)
            {
                if (healForm != null) healForm.Close();
                MessageBox.Show("Không thể thực hiện Tự Phục Hồi: " + ex.Message, "Lỗi Self-Healing", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}

