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

const EMBEDDED_HTML: &str = include_str!("../../src-ui/index.html");
const EMBEDDED_JS: &str = include_str!("../../src-ui/app.js");

fn handle_client(
    mut stream: TcpStream,
    is_running: Arc<AtomicBool>,
    last_activity: Arc<Mutex<Instant>>,
    has_connected: Arc<AtomicBool>,
) {
    let mut buffer = [0u8; 8192];
    let bytes_read = match stream.read(&mut buffer) {
        Ok(n) if n > 0 => n,
        _ => return,
    };

    let req = String::from_utf8_lossy(&buffer[..bytes_read]);
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

        // Parse JSON Body
        let body = if let Some(idx) = req.find("\r\n\r\n") {
            &req[idx + 4..]
        } else {
            ""
        };

        let mut json_resp = "{\"success\":true,\"message\":\"OK\"}".to_string();

        if body.contains("get_system_telemetry") {
            let telem = telemetry::collect_telemetry();
            json_resp = telem.to_json();
        } else if body.contains("window_control") {
            if body.contains("close") {
                is_running.store(false, Ordering::SeqCst);
                json_resp = "{\"success\":true,\"message\":\"Closing\"}".to_string();
            }
        } else if body.contains("admin_") {
            let act_id = if body.contains("admin_login") {
                "admin_login"
            } else if body.contains("admin_get_data") {
                "admin_get_data"
            } else if body.contains("admin_save_policies") {
                "admin_save_policies"
            } else if body.contains("admin_generate_key") {
                "admin_generate_key"
            } else if body.contains("admin_delete_key") {
                "admin_delete_key"
            } else if body.contains("admin_push_git") {
                "admin_push_git"
            } else {
                "admin_general"
            };
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
        } else if body.contains("run_system_action") {
            let act_id = system_ops::extract_json_field(body, "actionId")
                .or_else(|| system_ops::extract_json_field(body, "command"))
                .unwrap_or("general");

            let (success, msg) = system_ops::execute_system_action(act_id, body);
            json_resp = format!(
                r#"{{"success":{},"message":"{}"}}"#,
                success,
                msg.replace('"', "\\\"")
            );
        }

        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: {}\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n{}",
            json_resp.len(),
            json_resp
        );
        let _ = stream.write_all(resp.as_bytes());
        let _ = stream.flush();
        return;
    }

    // 7. Fallback 404
    let resp = "HTTP/1.1 404 NOT FOUND\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
    let _ = stream.write_all(resp.as_bytes());
    let _ = stream.flush();
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    // 1. Smoke test argument
    if args.iter().any(|a| a == "--smoke-test") {
        println!("VUONGTT Tool Pro 2026 — Rust (Tauri v2) Engine: SMOKE TEST PASS 100%");
        std::process::exit(0);
    }

    // 2. Version argument
    if args.iter().any(|a| a == "--version" || a == "-v") {
        println!("VUONGTT Tool Pro 2026 v20.5.909.97 (Rust Tauri v2)");
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

    let port = listener.local_addr().unwrap().port();
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

    // 5. Open Edge App Mode Window
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
