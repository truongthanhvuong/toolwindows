using System;
using System.IO;
using System.Reflection;
using System.Diagnostics;
using System.Security.Principal;
using System.Windows.Forms;
using System.Threading;
using System.Drawing;

[assembly: AssemblyTitle("VUONGTT Tool Pro 2026")]
[assembly: AssemblyDescription("Bộ công cụ kỹ thuật viên đa năng VUONGTT Tool Pro 2026")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("VUONGTT Software")]
[assembly: AssemblyProduct("VUONGTT Tool Pro 2026")]
[assembly: AssemblyCopyright("Copyright © 2026 VUONGTT. All rights reserved.")]
[assembly: AssemblyTrademark("VUONGTT")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyVersion("20.5.908.47")]
[assembly: AssemblyFileVersion("20.5.908.47")]

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
                    lblVer.Text = "v20.5.908.64 • Professional Standalone (All-in-One)";
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
                    startInfo.Verb = "runas";
                    try
                    {
                        Process.Start(startInfo);
                    }
                    catch
                    {
                        MessageBox.Show("Vui lòng đồng ý cấp quyền Quản trị viên (Run as Administrator) để sử dụng VUONGTT Tool Pro 2026.", "Yêu cầu quyền Administrator", MessageBoxButtons.OK, MessageBoxIcon.Warning);
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

                Process.Start(psi);

                // Giữ Splash Screen trong khoảng 1.8 giây cho đến khi cửa sổ chính WPF sẵn sàng
                Thread.Sleep(1800);
                CloseSplash();
            }
            catch (Exception ex)
            {
                CloseSplash();
                MessageBox.Show("Lỗi khởi chạy VUONGTT Tool Pro 2026: " + ex.Message, "Lỗi VUONGTT", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
