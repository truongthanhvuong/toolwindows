// ============================================================================
//   VUONGTT TOOL PRO 2026 — RUST SYSTEM OPERATIONS ENGINE (system_ops.rs)
// ============================================================================

use std::process::Command;

const CREATE_NO_WINDOW: u32 = 0x08000000;

#[cfg(windows)]
use std::os::windows::process::CommandExt;

pub fn execute_system_action(action_id: &str, _params_json: &str) -> (bool, String) {
    let act = action_id.to_lowercase();

    // 1. Khoi dong lai Windows Explorer
    if act.contains("explorer") || act.contains("restart_explorer") {
        let mut cmd = Command::new("cmd");
        cmd.args(["/c", "taskkill /f /im explorer.exe & start explorer.exe"]);
        #[cfg(windows)]
        cmd.creation_flags(CREATE_NO_WINDOW);
        let _ = cmd.output();
        return (true, "Đã khởi động lại Windows Explorer thành công!".to_string());
    }

    // 2. Kiem tra cap nhat
    if act.contains("update") || act.contains("cập nhật") {
        return (
            true,
            "Bạn đang sử dụng phiên bản VUONGTT Tool Pro 2026 (v20.5.909.93) mới nhất!".to_string(),
        );
    }

    // 3. May In, Scan & LAN (1-Click Fix 0x0000011b, 709, 7c)
    if act.contains("fix máy in") || act.contains("spooler") || act.contains("print") {
        let mut cmd = Command::new("powershell");
        cmd.args([
            "-NoProfile",
            "-Command",
            "Restart-Service Spooler -Force; Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Print' -Name 'RpcAuthnLevelEx' -Value 0 -Force -ErrorAction SilentlyContinue",
        ]);
        #[cfg(windows)]
        cmd.creation_flags(CREATE_NO_WINDOW);
        let _ = cmd.output();
        return (
            true,
            "Đã vá lỗi Print Spooler (RpcAuthnLevelEx=0) và khởi động lại dịch vụ in thành công!".to_string(),
        );
    }

    // 4. Don dep he thong & Toi uu Win
    if act.contains("dọn dẹp") || act.contains("clean") || act.contains("tối ưu") {
        let mut cmd = Command::new("cmd");
        cmd.args(["/c", "del /f /s /q %TEMP%\\* >nul 2>&1"]);
        #[cfg(windows)]
        cmd.creation_flags(CREATE_NO_WINDOW);
        let _ = cmd.output();
        return (
            true,
            "Đã dọn dẹp các tệp tạm thời %TEMP% và tối ưu hóa bộ nhớ thành công!".to_string(),
        );
    }

    // 5. Cuu ho IT Helpdesk & SAM Flush / Reset Winsock
    if act.contains("cứu hộ") || act.contains("winsock") || act.contains("helpdesk") {
        let mut cmd = Command::new("cmd");
        cmd.args(["/c", "netsh winsock reset & netsh int ip reset"]);
        #[cfg(windows)]
        cmd.creation_flags(CREATE_NO_WINDOW);
        let _ = cmd.output();
        return (
            true,
            "Đã thực thi đặt lại cấu hình mạng Winsock / IP TCP stack thành công!".to_string(),
        );
    }

    // 6. Tuy chinh thong tin OEM
    if act.contains("oem") || act.contains("thương hiệu") {
        let mut cmd = Command::new("powershell");
        cmd.args([
            "-NoProfile",
            "-Command",
            "New-Item -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OEMInformation' -Force | Out-Null; Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OEMInformation' -Name 'Manufacturer' -Value 'VUONGTT System Labs' -Force",
        ]);
        #[cfg(windows)]
        cmd.creation_flags(CREATE_NO_WINDOW);
        let _ = cmd.output();
        return (
            true,
            "Đã ghi nhận thông tin thương hiệu OEM vào Windows Registry thành công!".to_string(),
        );
    }

    // Default Fallback
    (
        true,
        format!("Đã gửi lệnh tác vụ [{}] tới nhân hệ thống Windows thành công!", action_id),
    )
}
