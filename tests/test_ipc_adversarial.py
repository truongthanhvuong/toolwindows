import json
import time
import urllib.request
import urllib.error
import subprocess
import sys
import os

# Ensure UTF-8 output on Windows console
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.stderr.reconfigure(encoding="utf-8", errors="replace")

print("=== STARTING ADVERSARIAL STRESS TEST ON RUST HTTP IPC SERVER ===")

project_root = r"E:\toolwindows"
exe_path = os.path.join(project_root, r"src-tauri\target\debug\vuongtt_toolkit.exe")

# Compile if not present
if not os.path.exists(exe_path):
    print("Building debug binary...")
    subprocess.run(["cargo", "build", "--manifest-path", os.path.join(project_root, r"src-tauri\Cargo.toml")], check=True)

# Start process
proc = subprocess.Popen([exe_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
time.sleep(1.5)

# Find port using netstat
port = None
out = subprocess.check_output(["netstat", "-ano", "-p", "tcp"]).decode("utf-8", errors="ignore")
for line in out.splitlines():
    parts = line.strip().split()
    if len(parts) >= 5 and parts[1].startswith("127.0.0.1:") and parts[3] == "LISTENING":
        pid_str = parts[4]
        if pid_str == str(proc.pid):
            port = int(parts[1].split(":")[1])
            break

if not port:
    port = 58992

print(f"Server PID: {proc.pid} listening on port: {port}")

# Clean up any child msedge processes launched by this test proc to not interfere with user
try:
    wmi_cmd = f"wmic process where (ParentProcessId={proc.pid}) get ProcessId"
    wmi_out = subprocess.check_output(["powershell", "-Command", f"Get-CimInstance Win32_Process | Where-Object {{ $_.ParentProcessId -eq {proc.pid} }} | ForEach-Object {{ Stop-Process -Id $_.ProcessId -Force }}"], stderr=subprocess.DEVNULL)
except Exception as e:
    pass

base_url = f"http://127.0.0.1:{port}"

def send_request(path="/api/rust-invoke", body=None, raw_data=None):
    url = base_url + path
    if raw_data is None:
        data = body.encode("utf-8") if isinstance(body, str) else json.dumps(body).encode("utf-8")
    else:
        data = raw_data
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json", "Connection": "close"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            resp_body = response.read().decode("utf-8", errors="ignore")
            status = response.status
            try:
                parsed = json.loads(resp_body)
            except Exception:
                parsed = resp_body
            return {"status": status, "body": parsed, "raw": resp_body}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="ignore")
        return {"status": e.code, "body": err_body, "raw": err_body}
    except Exception as e:
        return {"status": 0, "error": str(e)}

results = []

def run_test(name, fn):
    try:
        ok, detail, is_bug = fn()
        status_str = "PASS" if ok else "FAIL"
        results.append({"name": name, "ok": ok, "detail": detail, "is_bug": is_bug})
        print(f"[{status_str}] {name} - {detail}")
    except Exception as ex:
        results.append({"name": name, "ok": False, "detail": str(ex), "is_bug": True})
        print(f"[FAIL] {name} - Exception: {ex}")

# --- GROUP 1: Unknown Action Payload Fail-Closed ---
print("\n--- GROUP 1: Unknown Action Payload Fail-Closed ---")

def test_1_1_unknown_command():
    res = send_request(body={"command": "unknown_action_xyz_123", "payload": {}})
    # Check if fail-closed
    if isinstance(res.get("body"), dict):
        succ = res["body"].get("success")
        if succ is False:
            return True, f"Correctly returned success=false: {res['raw']}", False
        else:
            return False, f"VULNERABILITY: Server returned silent success=true for unknown action: {res['raw']}", True
    return False, f"Unexpected response format: {res}", True

run_test("1.1 Unknown command fail-closed check", test_1_1_unknown_command)

def test_1_2_arbitrary_json():
    res = send_request(body={"foo": "bar", "action": "fake_action"})
    if isinstance(res.get("body"), dict):
        succ = res["body"].get("success")
        if succ is False:
            return True, f"Correctly returned success=false: {res['raw']}", False
        else:
            return False, f"VULNERABILITY: Server returned silent success=true for arbitrary JSON: {res['raw']}", True
    return False, f"Unexpected response format: {res}", True

run_test("1.2 Arbitrary JSON payload fail-closed check", test_1_2_arbitrary_json)

def test_1_3_run_system_action_unknown():
    time.sleep(0.1)
    res = send_request(body={"command": "run_system_action", "actionId": "nonexistent_action_xyz_999"})
    if isinstance(res.get("body"), dict):
        succ = res["body"].get("success")
        msg = res["body"].get("message", "")
        if succ is False and ("không tồn tại" in msg or "Lỗi" in msg):
            return True, f"Correctly returned success=false with error message: {msg}", False
        else:
            return False, f"Unexpected response for unknown run_system_action: {res['raw']}", True
    return False, f"Unexpected response format: {res}", True

run_test("1.3 run_system_action with unknown actionId fail-closed check", test_1_3_run_system_action_unknown)

def test_1_4_system_ops_action_substring_collision():
    time.sleep(0.1)
    res = send_request(body={"command": "run_system_action", "actionId": "verify_disk_integrity_custom"})
    if isinstance(res.get("body"), dict):
        succ = res["body"].get("success")
        msg = res["body"].get("message", "")
        if succ is True and "diskmgmt.msc" in msg:
            return False, f"VULNERABILITY: False-positive substring match: actionId 'verify_disk_integrity_custom' triggered diskmgmt.msc due to 'act.contains(\"disk\")': {msg}", True
        elif succ is False:
            return True, f"Correctly failed closed for unknown action: {msg}", False
    return True, f"Response: {res}", False

run_test("1.4 Substring false-positive check in system_ops (act.contains('disk'))", test_1_4_system_ops_action_substring_collision)

# --- GROUP 2: Malformed JSON and Unexpected Types ---
print("\n--- GROUP 2: Malformed JSON and Unexpected Types ---")

def test_2_1_broken_json():
    res = send_request(raw_data=b'{"command": "run_system_action", "actionId": "broken')
    is_alive = proc.poll() is None
    if not is_alive:
        return False, "CRITICAL: Server crashed on broken JSON syntax!", True
    return True, f"Server stayed alive, responded with: {res.get('raw', res.get('error'))}", False

run_test("2.1 Broken JSON syntax crash resistance", test_2_1_broken_json)

def test_2_2_unexpected_types():
    res = send_request(body={"command": 12345, "actionId": True, "apps": [1, 2, 3], "payload": None})
    is_alive = proc.poll() is None
    if not is_alive:
        return False, "CRITICAL: Server crashed on unexpected types!", True
    return True, f"Server stayed alive: {res.get('raw')}", False

run_test("2.2 Unexpected parameter types crash resistance", test_2_2_unexpected_types)

def test_2_3_array_root():
    res = send_request(raw_data=b'[{"command":"get_app_version"}]')
    is_alive = proc.poll() is None
    if not is_alive:
        return False, "CRITICAL: Server crashed on JSON array root!", True
    return True, f"Server handled array root safely: {res.get('raw')}", False

run_test("2.3 Array root JSON payload", test_2_3_array_root)

def test_2_4_empty_body():
    res = send_request(raw_data=b'')
    is_alive = proc.poll() is None
    if not is_alive:
        return False, "CRITICAL: Server crashed on empty body!", True
    return True, f"Server handled empty body safely", False

run_test("2.4 Empty body request", test_2_4_empty_body)

# --- GROUP 3: Window Control with Unknown Commands & Substring Collisions ---
print("\n--- GROUP 3: Window Control Testing ---")

def test_3_1_window_control_unknown():
    res = send_request(body={"command": "window_control", "action": "explode_window"})
    if isinstance(res.get("body"), dict):
        succ = res["body"].get("success")
        msg = res["body"].get("message")
        if succ is False and msg == "Unknown window action":
            return True, f"Correctly returned success=false and 'Unknown window action'", False
        else:
            return False, f"Expected success=false for unknown window action, got: {res['raw']}", True
    return False, f"Unexpected response: {res}", True

run_test("3.1 window_control with unknown command", test_3_1_window_control_unknown)

def test_3_2_window_control_substring_collision():
    # If the dispatcher uses `body.contains("close")`, sending "action": "disclose" or "note": "please close"
    # will match "close" and prematurely terminate the server!
    res = send_request(body={"command": "window_control", "action": "disclose", "note": "do not close"})
    time.sleep(0.5)
    is_alive = proc.poll() is None
    if not is_alive:
        return False, "VULNERABILITY: Server exited prematurely because 'disclose' contained the substring 'close'!", True
    return True, "Server correctly did not exit on substring collision", False

run_test("3.2 window_control substring collision check", test_3_2_window_control_substring_collision)

# Cleanup
print("\n--- TEARDOWN ---")
try:
    if proc.poll() is None:
        send_request(path="/api/exit", body={})
        time.sleep(0.5)
        if proc.poll() is None:
            proc.kill()
except Exception:
    pass

# Print Summary
total = len(results)
passed = sum(1 for r in results if r["ok"])
failed = total - passed
bugs = [r for r in results if r["is_bug"]]

print("\n" + "=" * 60)
print(f"ADVERSARIAL STRESS TEST SUMMARY: {passed}/{total} PASS, {failed} FAIL")
if bugs:
    print(f"\nDEFECTS / VULNERABILITIES FOUND ({len(bugs)}):")
    for b in bugs:
        print(f"  * {b['name']}: {b['detail']}")
print("=" * 60)

if failed > 0:
    sys.exit(1)
else:
    sys.exit(0)
