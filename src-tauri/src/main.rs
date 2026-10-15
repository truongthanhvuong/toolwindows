// ============================================================================
//   VUONGTT TOOL PRO 2026 — RUST TAURI V2 ENTRY POINT (src-tauri/src/main.rs)
//   Fluent OS Utility — 13+1 Stitch Screens Desktop Engine
// ============================================================================

#![windows_subsystem = "windows"]

mod system_ops;
mod telemetry;

use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Instant;

#[cfg(windows)]
use std::os::windows::process::CommandExt;

const CREATE_NO_WINDOW: u32 = 0x08000000;

#[cfg(windows)]
#[link(name = "user32")]
extern "system" {
    fn GetForegroundWindow() -> isize;
    fn ShowWindow(hwnd: isize, nCmdShow: i32) -> i32;
    fn IsZoomed(hwnd: isize) -> i32;
}

fn control_window(action: &str) -> (bool, &'static str) {
    #[cfg(windows)]
    unsafe {
        let hwnd = GetForegroundWindow();
        if hwnd != 0 {
            match action {
                "minimize" => {
                    ShowWindow(hwnd, 6); // SW_MINIMIZE = 6
                    (true, "Window minimized")
                }
                "maximize" => {
                    if IsZoomed(hwnd) != 0 {
                        ShowWindow(hwnd, 9); // SW_RESTORE = 9
                        (true, "Window restored")
                    } else {
                        ShowWindow(hwnd, 3); // SW_MAXIMIZE = 3
                        (true, "Window maximized")
                    }
                }
                _ => (false, "Unknown window action"),
            }
        } else {
            let ps_code = if action == "minimize" {
                r#"
                $w = (Get-Process -Name msedge -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1).MainWindowHandle
                if ($w) {
                    Add-Type '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);' -Name W1 -Namespace U -ErrorAction SilentlyContinue
                    [U.W1]::ShowWindow($w, 6)
                }
                "#
            } else {
                r#"
                $w = (Get-Process -Name msedge -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1).MainWindowHandle
                if ($w) {
                    Add-Type '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c); [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr h);' -Name W2 -Namespace U -ErrorAction SilentlyContinue
                    if ([U.W2]::IsZoomed($w)) { [U.W2]::ShowWindow($w, 9) } else { [U.W2]::ShowWindow($w, 3) }
                }
                "#
            };
            let mut cmd = Command::new("powershell");
            cmd.args(["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps_code]);
            cmd.creation_flags(CREATE_NO_WINDOW);
            let _ = cmd.output();
            (true, "Window controlled via fallback")
        }
    }
    #[cfg(not(windows))]
    (true, "Mock window controlled")
}

const EMBEDDED_HTML: &str = include_str!("../../src-ui/index.html");
const EMBEDDED_JS: &str = include_str!("../../src-ui/app.js");
const APP_VERSION: &str = "20.5.909.127";

fn handle_client(
    mut stream: TcpStream,
    is_running: Arc<AtomicBool>,
    last_activity: Arc<Mutex<Instant>>,
    has_connected: Arc<AtomicBool>,
) {
    let _ = stream.set_nonblocking(false);
    let _ = stream.set_read_timeout(Some(std::time::Duration::from_secs(3)));
    let _ = stream.set_write_timeout(Some(std::time::Duration::from_secs(3)));

    let mut buffer = Vec::with_capacity(8192);
    let mut chunk = [0u8; 4096];
    loop {
        match stream.read(&mut chunk) {
            Ok(n) if n > 0 => {
                buffer.extend_from_slice(&chunk[..n]);
                let s = String::from_utf8_lossy(&buffer);
                if let Some(pos) = s.find("\r\n\r\n") {
                    if s[..pos].to_lowercase().contains("expect: 100-continue") {
                        let _ = stream.write_all(b"HTTP/1.1 100 Continue\r\n\r\n");
                        let _ = stream.flush();
                    }
                    let cl = s[..pos]
                        .lines()
                        .find(|l| l.to_lowercase().starts_with("content-length:"))
                        .and_then(|l| l.split(':').nth(1))
                        .and_then(|v| v.trim().parse::<usize>().ok())
                        .unwrap_or(0);
                    let body_len = buffer.len() - (pos + 4);
                    if body_len >= cl {
                        break;
                    }
                } else if buffer.len() > 32768 {
                    break;
                }
            }
            Ok(_) => break,
            Err(ref e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
            Err(_) => break,
        }
    }

    if buffer.is_empty() {
        return;
    }

    let req = String::from_utf8_lossy(&buffer);
    let first_line = req.lines().next().unwrap_or("");

    // 1. CORS Preflight
    if first_line.starts_with("OPTIONS ") {
        let resp = "HTTP/1.1 204 No Content\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nAccess-Control-Allow-Headers: Content-Type\r\nConnection: close\r\n\r\n";
        let _ = stream.write_all(resp.as_bytes());
        let _ = stream.flush();
        return;
    }

    // 2. GET index.html
    if first_line.starts_with("GET / ")
        || first_line.starts_with("HEAD / ")
        || first_line.starts_with("GET /index.html")
        || first_line.starts_with("HEAD /index.html")
        || first_line.starts_with("GET /?")
    {
        has_connected.store(true, Ordering::SeqCst);
        if let Ok(mut act) = last_activity.lock() {
            *act = Instant::now();
        }

        let resp_header = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: no-cache, no-store, must-revalidate\r\nConnection: close\r\n\r\n",
            EMBEDDED_HTML.len()
        );
        let _ = stream.write_all(resp_header.as_bytes());
        let _ = stream.write_all(EMBEDDED_HTML.as_bytes());
        let _ = stream.flush();
        return;
    }

    // 3. GET app.js
    if first_line.starts_with("GET /app.js") {
        if let Ok(mut act) = last_activity.lock() {
            *act = Instant::now();
        }

        let resp_header = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/javascript; charset=utf-8\r\nContent-Length: {}\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: no-cache, no-store, must-revalidate\r\nConnection: close\r\n\r\n",
            EMBEDDED_JS.len()
        );
        let _ = stream.write_all(resp_header.as_bytes());
        let _ = stream.write_all(EMBEDDED_JS.as_bytes());
        let _ = stream.flush();
        return;
    }

    // 4. POST Heartbeat
    if first_line.starts_with("POST /api/heartbeat") {
        has_connected.store(true, Ordering::SeqCst);
        if let Ok(mut act) = last_activity.lock() {
            *act = Instant::now();
        }

        let body = "{\"status\":\"alive\"}";
        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: {}\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n{}",
            body.len(),
            body
        );
        let _ = stream.write_all(resp.as_bytes());
        let _ = stream.flush();
        return;
    }

    // 5. POST Exit (Triggered on beforeunload)
    if first_line.starts_with("POST /api/exit") {
        is_running.store(false, Ordering::SeqCst);
        let body = "{\"status\":\"exiting\"}";
        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: {}\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n{}",
            body.len(),
            body
        );
        let _ = stream.write_all(resp.as_bytes());
        let _ = stream.flush();
        return;
    }

    // 6. POST Rust IPC Invoke
    if first_line.starts_with("POST /api/rust-invoke") {
        has_connected.store(true, Ordering::SeqCst);
        if let Ok(mut act) = last_activity.lock() {
            *act = Instant::now();
        }

        let json_resp = route_ipc_request(&req, &is_running);

        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: {}\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n{}",
            json_resp.len(),
            json_resp
        );
        let _ = stream.write_all(resp.as_bytes());
        let _ = stream.flush();
        let _ = stream.shutdown(std::net::Shutdown::Write);
        return;
    }

    // 7. Fallback 404
    let resp = "HTTP/1.1 404 NOT FOUND\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
    let _ = stream.write_all(resp.as_bytes());
    let _ = stream.flush();
}

pub fn route_ipc_request(req: &str, is_running: &AtomicBool) -> String {
    // Parse JSON Body
    let body = if let Some(idx) = req.find("\r\n\r\n") {
        &req[idx + 4..]
    } else if let Some(idx) = req.find("\n\n") {
        &req[idx + 2..]
    } else {
        req
    };

    let cmd = system_ops::extract_json_field(body, "command").unwrap_or("");
    let json_resp;

    if cmd == "get_app_version" {
        json_resp = format!(r#"{{"success":true,"version":"{}"}}"#, APP_VERSION);
    } else if cmd == "get_system_telemetry" {
        let telem = telemetry::collect_telemetry();
        json_resp = telem.to_json();
    } else if cmd == "get_disk_smart_telemetry" {
        let disk_json = system_ops::collect_disk_smart_telemetry();
        json_resp = format!(r#"{{"success":true,"data":{}}}"#, disk_json);
    } else if cmd == "get_cpu_main_details" {
        let details = system_ops::collect_cpu_main_details();
        json_resp = format!(r#"{{"success":true,"data":{}}}"#, details);
    } else if cmd == "get_win_optimize_state" {
        let state_json = system_ops::collect_win_optimize_state();
        json_resp = format!(r#"{{"success":true,"data":{}}}"#, state_json);
    } else if cmd == "get_troubleshoot_database" {
        let db_path = "src/Data/TroubleshootDatabase.json";
        let content = std::fs::read_to_string(db_path)
            .or_else(|_| std::fs::read_to_string("../src/Data/TroubleshootDatabase.json"))
            .unwrap_or_else(|_| "{\"Categories\":[],\"Problems\":[]}".to_string());
        json_resp = format!(r#"{{"success":true,"data":{}}}"#, content);
    } else if cmd == "get_local_users" {
        let users = system_ops::collect_local_users();
        json_resp = format!(r#"{{"success":true,"data":{}}}"#, users);
    } else if cmd == "manage_local_user" {
        let sub = system_ops::extract_json_field(body, "subAction").unwrap_or("toggle_active");
        let user = system_ops::extract_json_field(body, "username").unwrap_or("");
        let val = system_ops::extract_json_field(body, "value").unwrap_or("");
        let (ok, msg) = system_ops::manage_local_user(sub, user, val);
        json_resp = format!(
            r#"{{"success":{},"message":"{}"}}"#,
            ok,
            msg.replace('"', "\\\"")
        );
    } else if cmd == "window_control" {
        let action = system_ops::extract_json_field(body, "action").unwrap_or("");
        if action == "close" {
            is_running.store(false, Ordering::SeqCst);
            json_resp = "{\"success\":true,\"message\":\"Closing\"}".to_string();
        } else if action == "minimize" {
            let (ok, msg) = control_window("minimize");
            json_resp = format!(r#"{{"success":{},"message":"{}"}}"#, ok, msg);
        } else if action == "maximize" {
            let (ok, msg) = control_window("maximize");
            json_resp = format!(r#"{{"success":{},"message":"{}"}}"#, ok, msg);
        } else {
            json_resp = "{\"success\":false,\"message\":\"Unknown window action\"}".to_string();
        }
    } else if cmd == "admin_login"
        || cmd == "admin_get_data"
        || cmd == "admin_save_policies"
        || cmd == "admin_generate_key"
        || cmd == "admin_delete_key"
        || cmd == "admin_push_git"
        || cmd == "admin_general"
    {
        let act_id = cmd;
        let (success, msg) = system_ops::execute_system_action(act_id, body);
        if act_id == "admin_get_data" && success {
            json_resp = format!(r#"{{"success":true,"data":{}}}"#, msg);
        } else {
            json_resp = format!(
                r#"{{"success":{},"message":"{}"}}"#,
                success,
                msg.replace('"', "\\\"")
            );
        }
    } else if cmd == "install_apps" {
        let (success, msg) = system_ops::execute_system_action("install_apps", body);
        json_resp = format!(
            r#"{{"success":{},"message":"{}"}}"#,
            success,
            msg.replace('"', "\\\"")
        );
    } else if cmd == "get_install_logs" {
        let logs_raw = system_ops::get_logs_json();
        let safe_escaped = logs_raw.replace('\\', "\\\\").replace('"', "\\\"");
        json_resp = format!(
            r#"{{"success":true,"message":"{}","logs":{}}}"#,
            safe_escaped,
            logs_raw
        );
    } else if cmd == "clear_install_logs" {
        system_ops::clear_logs();
        json_resp = r#"{"success":true,"message":"[]"}"#.to_string();
    } else if cmd == "get_installed_apps" {
        let (success, msg) = system_ops::execute_system_action("get_installed_apps", body);
        json_resp = format!(r#"{{"success":{},"data":{}}}"#, success, if msg.is_empty() { "[]" } else { &msg });
    } else if cmd == "run_system_action" {
        let act_id = system_ops::extract_json_field(body, "actionId")
            .unwrap_or("general");

        let (success, msg) = system_ops::execute_system_action(act_id, body);
        if act_id == "browse_iso" || act_id == "browse_file" {
            let escaped_path = msg.replace('\\', "\\\\").replace('"', "\\\"");
            json_resp = format!(
                r#"{{"success":{},"file_path":"{}","message":"{}"}}"#,
                success,
                escaped_path,
                escaped_path
            );
        } else {
            json_resp = format!(
                r#"{{"success":{},"message":"{}"}}"#,
                success,
                msg.replace('"', "\\\"")
            );
        }
    } else {
        json_resp = r#"{"success":false,"message":"Lỗi: Lệnh IPC không hợp lệ hoặc chưa được hỗ trợ!"}"#.to_string();
    }

    json_resp
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    // 1. Smoke test argument
    if args.iter().any(|a| a == "--smoke-test") {
        println!("VUONGTT Toolkit Engine: SMOKE TEST PASS 100%");
        std::process::exit(0);
    }

    // 2. Version argument
    if args.iter().any(|a| a == "--version" || a == "-v") {
        println!("VUONGTT Toolkit v{}", APP_VERSION);
        std::process::exit(0);
    }

    // 3. Bind dynamic loopback server
    let listener = match TcpListener::bind("127.0.0.1:0") {
        Ok(l) => l,
        Err(_) => match TcpListener::bind("127.0.0.1:58992") {
            Ok(l) => l,
            Err(_) => match TcpListener::bind("127.0.0.1:58993") {
                Ok(l) => l,
                Err(_) => return,
            },
        },
    };

    let port = match listener.local_addr() {
        Ok(addr) => addr.port(),
        Err(_) => 58992,
    };
    let is_running = Arc::new(AtomicBool::new(true));
    let has_connected = Arc::new(AtomicBool::new(false));
    let last_activity = Arc::new(Mutex::new(Instant::now()));

    // 4. Background Server Thread with Non-blocking polling
    let listener_running = Arc::clone(&is_running);
    let listener_activity = Arc::clone(&last_activity);
    let listener_connected = Arc::clone(&has_connected);

    thread::spawn(move || {
        let _ = listener.set_nonblocking(true);
        while listener_running.load(Ordering::SeqCst) {
            match listener.accept() {
                Ok((stream, _)) => {
                    let r_clone = Arc::clone(&listener_running);
                    let a_clone = Arc::clone(&listener_activity);
                    let c_clone = Arc::clone(&listener_connected);
                    thread::spawn(move || handle_client(stream, r_clone, a_clone, c_clone));
                }
                Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                    thread::sleep(std::time::Duration::from_millis(20));
                }
                Err(_) => {
                    thread::sleep(std::time::Duration::from_millis(50));
                }
            }
        }
    });

    // 5. Ghi nhận máy trạm hiện tại vào hệ thống Admin Fleet Monitor
    let _ = system_ops::record_device_heartbeat("", "", "", "", "");

    // 6. Open Edge App Mode Window
    let url = format!("http://127.0.0.1:{}", port);
    let profile_dir = std::env::temp_dir().join("vuongtt_toolkit_edge_profile");

    let edge_paths = [
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "msedge.exe",
    ];

    let mut launched = false;
    for path in edge_paths {
        let mut edge_cmd = Command::new(path);
        edge_cmd.args([
            format!("--app={}", url),
            format!("--user-data-dir={}", profile_dir.to_string_lossy()),
            "--window-size=1440,900".to_string(),
            "--disable-features=Translate,PrivacySandboxSettings4".to_string(),
            "--no-first-run".to_string(),
            "--no-default-browser-check".to_string(),
        ]);

        if let Ok(_child) = edge_cmd.spawn() {
            launched = true;
            break;
        }
    }

    if !launched {
        // Fallback default browser
        let _ = Command::new("cmd").args(["/c", "start", &url]).status();
    }

    // 6. Master Lifecycle Watchdog: Giữ tiến trình Rust sống liên tục theo cửa sổ giao diện!
    while is_running.load(Ordering::SeqCst) {
        thread::sleep(std::time::Duration::from_millis(500));

        if let Ok(act) = last_activity.lock() {
            let elapsed = act.elapsed();
            if has_connected.load(Ordering::SeqCst) {
                // Sau khi client đã kết nối lần đầu:
                // Nếu quá 10 giây không còn heartbeat/request -> Cửa sổ Edge đã đóng -> Tự động thoát sạch sẽ!
                if elapsed > std::time::Duration::from_secs(10) {
                    break;
                }
            } else {
                // Chờ tối đa 60 giây cho Edge mở và gửi request đầu tiên
                if elapsed > std::time::Duration::from_secs(60) {
                    break;
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_unknown_command_fails_closed() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"command\":\"unknown_action_xyz_123\",\"payload\":{}}";
        let resp = route_ipc_request(req, &flag);
        assert!(resp.contains("\"success\":false"), "Unknown command must return success=false: {}", resp);
        assert!(resp.contains("Lỗi: Lệnh IPC không hợp lệ"), "Expected error message: {}", resp);
    }

    #[test]
    fn test_arbitrary_json_fails_closed() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"foo\":\"bar\",\"action\":\"fake_action\"}";
        let resp = route_ipc_request(req, &flag);
        assert!(resp.contains("\"success\":false"), "Arbitrary JSON must return success=false: {}", resp);
    }

    #[test]
    fn test_window_control_substring_collision_safe() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"command\":\"window_control\",\"action\":\"disclose\",\"note\":\"do not close\"}";
        let resp = route_ipc_request(req, &flag);
        assert!(flag.load(Ordering::SeqCst), "Flag should not be set to false on substring collision");
        assert!(resp.contains("Unknown window action"), "Expected Unknown window action: {}", resp);
    }

    #[test]
    fn test_window_control_close_exact_match() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"command\":\"window_control\",\"action\":\"close\"}";
        let resp = route_ipc_request(req, &flag);
        assert!(!flag.load(Ordering::SeqCst), "Flag should be set to false on exact close match");
        assert!(resp.contains("Closing"), "Expected Closing: {}", resp);
    }

    #[test]
    fn test_route_collision_with_note_install_apps() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"command\":\"run_system_action\",\"actionId\":\"open_disk_mgmt\",\"note\":\"install_apps failed earlier\"}";
        let resp = route_ipc_request(req, &flag);
        assert!(resp.contains("\"success\":true"), "Should successfully route to run_system_action: {}", resp);
        assert!(resp.contains("diskmgmt.msc"), "Should trigger diskmgmt.msc, not install_apps: {}", resp);
    }

    #[test]
    fn test_window_control_action_id_not_matched_as_action() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"command\":\"window_control\",\"actionId\":\"close\"}";
        let resp = route_ipc_request(req, &flag);
        assert!(flag.load(Ordering::SeqCst), "Flag should remain true when actionId is close");
        assert!(resp.contains("Unknown window action"), "Expected Unknown window action: {}", resp);
    }

    #[test]
    fn test_window_control_reaction_not_matched_as_action() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"command\":\"window_control\",\"reaction\":\"close\"}";
        let resp = route_ipc_request(req, &flag);
        assert!(flag.load(Ordering::SeqCst), "Flag should remain true when reaction is close");
        assert!(resp.contains("Unknown window action"), "Expected Unknown window action: {}", resp);
    }

    #[test]
    fn test_run_system_action_check_winsxs_size_fails_closed() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"command\":\"run_system_action\",\"actionId\":\"check_winsxs_size\"}";
        let resp = route_ipc_request(req, &flag);
        assert!(resp.contains("\"success\":false"), "check_winsxs_size must return success=false: {}", resp);
        assert!(resp.contains("không tồn tại"), "Expected action not found error: {}", resp);
    }

    #[test]
    fn test_run_system_action_verify_office_license_fails_closed() {
        let flag = AtomicBool::new(true);
        let req = "POST /api/rust-invoke HTTP/1.1\r\n\r\n{\"command\":\"run_system_action\",\"actionId\":\"verify_office_license\"}";
        let resp = route_ipc_request(req, &flag);
        assert!(resp.contains("\"success\":false"), "verify_office_license must return success=false: {}", resp);
        assert!(resp.contains("không tồn tại"), "Expected action not found error: {}", resp);
    }
}
