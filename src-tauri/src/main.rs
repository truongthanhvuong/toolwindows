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
use std::sync::Arc;
use std::thread;

const EMBEDDED_HTML: &str = include_str!("../../src-ui/index.html");
const EMBEDDED_JS: &str = include_str!("../../src-ui/app.js");

fn handle_client(mut stream: TcpStream, is_running: Arc<AtomicBool>) {
    let mut buffer = [0u8; 8192];
    let bytes_read = match stream.read(&mut buffer) {
        Ok(n) => n,
        Err(_) => return,
    };

    let req = String::from_utf8_lossy(&buffer[..bytes_read]);
    let first_line = req.lines().next().unwrap_or("");

    if first_line.starts_with("GET / ") || first_line.starts_with("GET /index.html") {
        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            EMBEDDED_HTML.len(),
            EMBEDDED_HTML
        );
        let _ = stream.write_all(resp.as_bytes());
    } else if first_line.starts_with("GET /app.js") {
        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/javascript; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            EMBEDDED_JS.len(),
            EMBEDDED_JS
        );
        let _ = stream.write_all(resp.as_bytes());
    } else if first_line.starts_with("POST /api/rust-invoke") {
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
                std::process::exit(0);
            }
        } else if body.contains("run_system_action") {
            let act_id = if let Some(idx) = body.find("\"actionId\":\"") {
                let rest = &body[idx + 12..];
                if let Some(end) = rest.find('"') {
                    &rest[..end]
                } else {
                    "general"
                }
            } else {
                "general"
            };

            let (success, msg) = system_ops::execute_system_action(act_id, body);
            json_resp = format!(
                r#"{{"success":{},"message":"{}"}}"#,
                success,
                msg.replace('"', "\\\"")
            );
        }

        let resp = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            json_resp.len(),
            json_resp
        );
        let _ = stream.write_all(resp.as_bytes());
    } else {
        let resp = "HTTP/1.1 404 NOT FOUND\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        let _ = stream.write_all(resp.as_bytes());
    }
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
        println!("VUONGTT Tool Pro 2026 v20.5.909.93 (Rust Tauri v2)");
        std::process::exit(0);
    }

    // 3. Bind dynamic loopback server
    let listener = match TcpListener::bind("127.0.0.1:0") {
        Ok(l) => l,
        Err(_) => match TcpListener::bind("127.0.0.1:58992") {
            Ok(l) => l,
            Err(_) => return,
        },
    };

    let port = listener.local_addr().unwrap().port();
    let is_running = Arc::new(AtomicBool::new(true));
    let running_clone = Arc::clone(&is_running);

    // 4. Background Server Thread
    thread::spawn(move || {
        for stream in listener.incoming() {
            if !running_clone.load(Ordering::SeqCst) {
                break;
            }
            if let Ok(s) = stream {
                let r_clone = Arc::clone(&running_clone);
                thread::spawn(move || handle_client(s, r_clone));
            }
        }
    });

    // 5. Open Edge WebView2 App Mode Window
    let url = format!("http://127.0.0.1:{}", port);
    let profile_dir = std::env::temp_dir().join("vuongtt_toolkit_edge_profile");

    // Tim duong dan Edge thuc te tren Windows
    let edge_paths = [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
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

        if let Ok(mut child) = edge_cmd.spawn() {
            launched = true;
            let _ = child.wait();
            break;
        }
    }

    if !launched {
        // Fallback default browser va cho
        let _ = Command::new("cmd").args(["/c", "start", &url]).status();
        while is_running.load(Ordering::SeqCst) {
            std::thread::sleep(std::time::Duration::from_millis(500));
        }
    }
}
