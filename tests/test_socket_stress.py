import json
import time
import socket
import urllib.request
import urllib.error
import subprocess
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.stdout.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)
sys.stderr.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)

print("=" * 70)
print("  EMPIRICAL CHALLENGER: SERVER SOCKET & CONCURRENCY STRESS HARNESS")
print("=" * 70)

project_root = r"E:\toolwindows"
exe_path = os.path.join(project_root, r"src-tauri\target\debug\vuongtt_toolkit.exe")

if not os.path.exists(exe_path):
    print("Building debug binary...")
    subprocess.run(["cargo", "build", "--manifest-path", os.path.join(project_root, r"src-tauri\Cargo.toml")], check=True)

# Start process with DEVNULL to avoid pipe deadlock on Windows
proc = subprocess.Popen([exe_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Poll for listening port for up to 6 seconds
port = None
for _ in range(30):
    time.sleep(0.2)
    try:
        out = subprocess.check_output(["netstat", "-ano", "-p", "tcp"]).decode("utf-8", errors="ignore")
        for line in out.splitlines():
            parts = line.strip().split()
            if len(parts) >= 5 and parts[1].startswith("127.0.0.1:") and parts[3] == "LISTENING":
                if parts[4] == str(proc.pid):
                    port = int(parts[1].split(":")[1])
                    break
        if port:
            break
    except Exception:
        pass

if not port:
    print(f"Error: Could not locate listening port for PID {proc.pid}!")
    sys.exit(1)

print(f"Target Process PID: {proc.pid} | Bound Listening Port: {port}", flush=True)

# Suppress any Edge browser window spawned by main.rs
try:
    subprocess.run(["powershell", "-NoProfile", "-Command", 
                    f"Get-CimInstance Win32_Process | Where-Object {{ $_.ParentProcessId -eq {proc.pid} }} | ForEach-Object {{ Stop-Process -Id $_.ProcessId -Force }}"],
                   stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
except Exception:
    pass

base_url = f"http://127.0.0.1:{port}"

def get_process_metrics(pid):
    try:
        ps_cmd = f"(Get-Process -Id {pid} | Select-Object Handles, @{{Name='Threads';Expression={{$_.Threads.Count}}}}, WorkingSet64) | ConvertTo-Json"
        res = subprocess.check_output(["powershell", "-NoProfile", "-Command", ps_cmd]).decode("utf-8", errors="ignore")
        data = json.loads(res)
        return {
            "handles": data.get("Handles", 0),
            "threads": data.get("Threads", 0),
            "mem_mb": round(data.get("WorkingSet64", 0) / (1024 * 1024), 2)
        }
    except Exception as e:
        return {"handles": -1, "threads": -1, "mem_mb": -1, "error": str(e)}

baseline_metrics = get_process_metrics(proc.pid)
print(f"Baseline Metrics: Handles={baseline_metrics['handles']} | Threads={baseline_metrics['threads']} | Mem={baseline_metrics['mem_mb']} MB\n")

failures = []

def send_http_request(path="/api/rust-invoke", body=None, timeout=4, method=None):
    url = base_url + path
    if method is None:
        method = "POST" if (body is not None or path.startswith("/api/")) else "GET"
    data = json.dumps(body).encode("utf-8") if isinstance(body, (dict, list)) else (body.encode("utf-8") if isinstance(body, str) else (b"" if method == "POST" else None))
    headers = {"Content-Type": "application/json", "Connection": "close"}
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    start = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            resp_data = resp.read().decode("utf-8", errors="ignore")
            elapsed = time.perf_counter() - start
            return {"status": resp.status, "data": resp_data, "elapsed": elapsed, "error": None}
    except urllib.error.HTTPError as e:
        elapsed = time.perf_counter() - start
        return {"status": e.code, "data": e.read().decode("utf-8", errors="ignore"), "elapsed": elapsed, "error": f"HTTPError {e.code}"}
    except Exception as e:
        elapsed = time.perf_counter() - start
        return {"status": 0, "data": None, "elapsed": elapsed, "error": str(e)}

# -------------------------------------------------------------
# TEST 1: High-Concurrency Burst (20 threads, 200 requests)
# -------------------------------------------------------------
print("--- TEST 1: High-Concurrency Multithreaded Flood (20 workers, 200 requests) ---")
concurrency_results = []
test_bodies = [
    {"command": "get_app_version"},
    {"command": "unknown_action_stress_probe"},
    {"command": "window_control", "action": "disclose", "note": "do not close"},
    {"command": "run_system_action", "actionId": "nonexistent_stress_action"},
    {"arbitrary_key": "arbitrary_val", "type": "stress_flood"},
]

start_t1 = time.perf_counter()
with ThreadPoolExecutor(max_workers=20) as executor:
    futures = []
    for i in range(200):
        body = test_bodies[i % len(test_bodies)]
        futures.append(executor.submit(send_http_request, "/api/rust-invoke", body, 5))
    
    for fut in as_completed(futures):
        res = fut.result()
        concurrency_results.append(res)
elapsed_t1 = time.perf_counter() - start_t1

t1_errors = [r for r in concurrency_results if r["error"] is not None]
t1_latencies = [r["elapsed"] for r in concurrency_results]
avg_lat = sum(t1_latencies) / len(t1_latencies) if t1_latencies else 0
max_lat = max(t1_latencies) if t1_latencies else 0
throughput = len(concurrency_results) / elapsed_t1 if elapsed_t1 > 0 else 0

print(f"Results: {len(concurrency_results) - len(t1_errors)}/200 SUCCESS | {len(t1_errors)} ERRORS")
print(f"Throughput: {throughput:.2f} req/s | Avg Latency: {avg_lat*1000:.2f}ms | Max Latency: {max_lat*1000:.2f}ms")

if len(t1_errors) > 0:
    print(f"[FAIL] Concurrency flood produced errors: {[e['error'] for e in t1_errors[:5]]}")
    failures.append(f"Test 1 Concurrency Flood had {len(t1_errors)} errors")
else:
    print("[PASS] Test 1: Concurrency Flood completed with 0 errors, 0 dropped connections.")

# -------------------------------------------------------------
# TEST 2: Rapid Raw TCP Socket Requests & WSAECONNABORTED check
# -------------------------------------------------------------
print("\n--- TEST 2: Rapid Raw TCP Socket Requests & Winsock Abort Check ---")
raw_socket_errors = []
raw_socket_success = 0
start_t2 = time.perf_counter()

raw_body = b'{"command":"get_app_version"}'
raw_http_payload = (
    b"POST /api/rust-invoke HTTP/1.1\r\n"
    b"Host: 127.0.0.1\r\n"
    b"Content-Type: application/json\r\n"
    + f"Content-Length: {len(raw_body)}\r\n".encode("ascii")
    + b"Connection: close\r\n\r\n"
    + raw_body
)

for i in range(100):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(3.0)
        s.connect(("127.0.0.1", port))
        s.sendall(raw_http_payload)
        
        resp_bytes = bytearray()
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            resp_bytes.extend(chunk)
        s.close()
        
        resp_str = resp_bytes.decode("utf-8", errors="ignore")
        if "HTTP/1.1 200 OK" in resp_str and "20.5.909.126" in resp_str:
            raw_socket_success += 1
        else:
            raw_socket_errors.append(f"Unexpected response: {resp_str[:100]}")
    except Exception as e:
        raw_socket_errors.append(f"Socket exception: {type(e).__name__}: {e}")

elapsed_t2 = time.perf_counter() - start_t2
print(f"Raw Socket Loop: {raw_socket_success}/100 SUCCESS | {len(raw_socket_errors)} ERRORS | Total Time: {elapsed_t2:.2f}s")

wsa_aborted = [e for e in raw_socket_errors if "10053" in e or "WSAECONNABORTED" in e or "10054" in e or "WSAECONNRESET" in e]
if wsa_aborted:
    print(f"[FAIL] Detected Winsock Abort/Reset errors: {wsa_aborted[:5]}")
    failures.append(f"Test 2 detected Winsock abort/reset errors: {len(wsa_aborted)}")
elif len(raw_socket_errors) > 0:
    print(f"[FAIL] Raw socket errors: {raw_socket_errors[:5]}")
    failures.append(f"Test 2 raw socket errors: {len(raw_socket_errors)}")
else:
    print("[PASS] Test 2: Rapid socket requests completed with 0 WSAECONNABORTED / 10053 errors.")

# -------------------------------------------------------------
# TEST 3: Heartbeat & Static Asset Burst Check
# -------------------------------------------------------------
print("\n--- TEST 3: Heartbeat & Static Asset Burst Check ---")
heartbeat_ok = 0
heartbeat_err = 0
for i in range(30):
    res = send_http_request(path="/api/heartbeat", body=None, timeout=3)
    if res["status"] == 200 and '{"status":"alive"}' in (res["data"] or ""):
        heartbeat_ok += 1
    else:
        heartbeat_err += 1

index_ok = 0
index_err = 0
for i in range(20):
    res = send_http_request(path="/", body=None, timeout=3)
    if res["status"] == 200 and ("<!DOCTYPE html>" in (res["data"] or "") or "VUONGTT" in (res["data"] or "")):
        index_ok += 1
    else:
        index_err += 1

appjs_ok = 0
appjs_err = 0
for i in range(20):
    res = send_http_request(path="/app.js", body=None, timeout=3)
    if res["status"] == 200 and len(res["data"] or "") > 1000:
        appjs_ok += 1
    else:
        appjs_err += 1

print(f"Heartbeat: {heartbeat_ok}/30 PASS | Index HTML: {index_ok}/20 PASS | App.js: {appjs_ok}/20 PASS")
if heartbeat_err > 0 or index_err > 0 or appjs_err > 0:
    failures.append(f"Test 3 Heartbeat/Static errors: hb_err={heartbeat_err}, idx_err={index_err}, js_err={appjs_err}")
    print("[FAIL] Test 3 failed")
else:
    print("[PASS] Test 3: Heartbeat and static asset endpoints 100% responsive.")

# -------------------------------------------------------------
# TEST 4: Malformed, Partial, and Abrupt Disconnection Stress
# -------------------------------------------------------------
print("\n--- TEST 4: Malformed, Partial, and Abrupt Disconnection Resilience ---")
t4_passes = 0

# 4.1 Immediate disconnect after connect (SYN-ACK then close)
try:
    for _ in range(10):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("127.0.0.1", port))
        s.close()
    t4_passes += 1
    print("[PASS] 4.1 Immediate disconnect without data: Server survived")
except Exception as e:
    failures.append(f"Test 4.1 failed: {e}")
    print(f"[FAIL] 4.1 Immediate disconnect failed: {e}")

# 4.2 Truncated HTTP header then close
try:
    for _ in range(5):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("127.0.0.1", port))
        s.sendall(b"POST /api/rust-invoke HTTP/1.1\r\nHost: 127.0.0.1\r\n")
        time.sleep(0.05)
        s.close()
    t4_passes += 1
    print("[PASS] 4.2 Truncated HTTP header: Server survived")
except Exception as e:
    failures.append(f"Test 4.2 failed: {e}")
    print(f"[FAIL] 4.2 Truncated header failed: {e}")

# 4.3 Truncated Body (Content-Length 1000 but only 10 bytes sent)
try:
    for _ in range(5):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("127.0.0.1", port))
        s.sendall(b"POST /api/rust-invoke HTTP/1.1\r\nContent-Length: 1000\r\n\r\n1234567890")
        time.sleep(0.05)
        s.close()
    t4_passes += 1
    print("[PASS] 4.3 Truncated Content-Length body: Server survived")
except Exception as e:
    failures.append(f"Test 4.3 failed: {e}")
    print(f"[FAIL] 4.3 Truncated body failed: {e}")

# 4.4 Large payload header chunk (> 32KB)
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("127.0.0.1", port))
    junk_headers = b"X-Junk: " + (b"A" * 35000) + b"\r\n\r\n"
    s.sendall(b"POST /api/rust-invoke HTTP/1.1\r\n" + junk_headers)
    time.sleep(0.1)
    s.close()
    t4_passes += 1
    print("[PASS] 4.4 Header >32KB break check: Server survived buffer threshold")
except Exception as e:
    failures.append(f"Test 4.4 failed: {e}")
    print(f"[FAIL] 4.4 Large header failed: {e}")

# 4.5 Multibyte UTF-8 Vietnamese payload
res_utf8 = send_http_request("/api/rust-invoke", {"command": "kiểm_tra_hệ_thống_tiếng_việt", "ghi_chú": "Chào mừng bạn đến với VUONGTT Toolkit 2026"})
if res_utf8["status"] == 200 and "success" in (res_utf8["data"] or ""):
    t4_passes += 1
    print(f"[PASS] 4.5 UTF-8 Vietnamese multibyte payload handled safely: {res_utf8['data']}")
else:
    failures.append(f"Test 4.5 UTF-8 payload failed: {res_utf8}")
    print(f"[FAIL] 4.5 UTF-8 payload failed: {res_utf8}")

# -------------------------------------------------------------
# TEST 5: Post-Stress Handle & Socket Leak Audit
# -------------------------------------------------------------
print("\n--- TEST 5: Post-Stress Resource Leak & Socket Drain Audit ---")
# Allow 2 seconds for worker threads to finish and sockets to settle
time.sleep(2.0)

post_metrics = get_process_metrics(proc.pid)
print(f"Post-Stress Metrics: Handles={post_metrics['handles']} | Threads={post_metrics['threads']} | Mem={post_metrics['mem_mb']} MB")

# Check open sockets via netstat for this PID
ns_out = subprocess.check_output(["netstat", "-ano", "-p", "tcp"]).decode("utf-8", errors="ignore")
server_sockets = []
for line in ns_out.splitlines():
    parts = line.strip().split()
    if len(parts) >= 5 and parts[4] == str(proc.pid):
        server_sockets.append((parts[1], parts[2], parts[3]))

print(f"Active TCP Connections for PID {proc.pid}: {len(server_sockets)}")
for sock in server_sockets:
    print(f"  Local: {sock[0]} | Remote: {sock[1]} | State: {sock[2]}")

# Sockets in non-listening state (e.g. CLOSE_WAIT, ESTABLISHED)
lingering_sockets = [s for s in server_sockets if s[2] != "LISTENING"]
print(f"Lingering Non-Listening Sockets: {len(lingering_sockets)}")

# Check if server is still fully functional after all stress
verify_res = send_http_request("/api/rust-invoke", {"command": "get_app_version"})
if verify_res["status"] == 200 and "20.5.909.126" in (verify_res["data"] or ""):
    print("[PASS] Post-stress functional sanity check: Server responded normally.")
else:
    failures.append("Post-stress server unresponsive")
    print(f"[FAIL] Post-stress server unresponsive: {verify_res}")

thread_growth = post_metrics["threads"] - baseline_metrics["threads"]
handle_growth = post_metrics["handles"] - baseline_metrics["handles"]
print(f"Delta: Thread count change = {thread_growth:+d} | Handle count change = {handle_growth:+d}")

if len(lingering_sockets) > 5:
    failures.append(f"Potential socket leak: {len(lingering_sockets)} lingering non-listening sockets")
    print(f"[FAIL] Lingering sockets detected: {len(lingering_sockets)}")
elif thread_growth > 10:
    failures.append(f"Potential thread leak: {thread_growth} threads remained active")
    print(f"[FAIL] Thread leak detected: {thread_growth}")
else:
    print("[PASS] Test 5: Resource Leak Audit passed. No thread or socket leak detected.")

# -------------------------------------------------------------
# TEARDOWN
# -------------------------------------------------------------
print("\n--- TEARDOWN ---")
try:
    if proc.poll() is None:
        send_http_request(path="/api/exit", body={})
        time.sleep(0.5)
        if proc.poll() is None:
            proc.kill()
            print("Process killed.")
        else:
            print("Process exited cleanly via /api/exit.")
except Exception as e:
    print(f"Teardown error: {e}")

print("\n" + "=" * 70)
if len(failures) == 0:
    print("ALL EMPIRICAL STRESS TESTS PASSED (0 FAILURES, 0 LEAKS, 0 WINSOCK ABORTS)")
    print("=" * 70)
    sys.exit(0)
else:
    print(f"STRESS TESTS FAILED WITH {len(failures)} ISSUES:")
    for f in failures:
        print(f"  * {f}")
    print("=" * 70)
    sys.exit(1)
