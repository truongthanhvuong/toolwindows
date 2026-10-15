#[path = "../src-tauri/src/telemetry.rs"]
mod telemetry;
#[path = "../src-tauri/src/system_ops.rs"]
mod system_ops;

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};

fn main() {
    println!("===============================================================");
    println!("   VUONGTT TOOLKIT — EMPIRICAL CHALLENGER TEST SUITE (M1)");
    println!("===============================================================");

    let mut all_passed = true;

    // ------------------------------------------------------------------------
    // [TEST 1] Dynamic CPU Load Verification
    // ------------------------------------------------------------------------
    println!("\n--- [TEST 1] Dynamic CPU Load Verification ---");
    let baseline_cpu = telemetry::compute_real_cpu_percent();
    println!("Initial sample CPU: {:.1}%", baseline_cpu);

    let mut baseline_samples = Vec::new();
    for _ in 0..3 {
        thread::sleep(Duration::from_millis(150));
        let s = telemetry::compute_real_cpu_percent();
        baseline_samples.push(s);
    }
    let avg_baseline: f32 = baseline_samples.iter().sum::<f32>() / baseline_samples.len() as f32;
    println!("Average Baseline CPU (idle): {:.1}% (samples: {:?})", avg_baseline, baseline_samples);

    let num_cpus = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4);
    println!("Spawning {} worker threads to burn CPU...", num_cpus);

    let keep_burning = Arc::new(AtomicBool::new(true));
    let mut handles = Vec::new();
    for _ in 0..num_cpus {
        let flag = Arc::clone(&keep_burning);
        handles.push(thread::spawn(move || {
            let mut x: u64 = 1;
            while flag.load(Ordering::Relaxed) {
                x = x.wrapping_mul(6364136223846793005).wrapping_add(1);
            }
            x
        }));
    }

    thread::sleep(Duration::from_millis(400));

    let mut load_samples = Vec::new();
    for _ in 0..4 {
        thread::sleep(Duration::from_millis(150));
        let s = telemetry::compute_real_cpu_percent();
        load_samples.push(s);
    }
    let avg_load: f32 = load_samples.iter().sum::<f32>() / load_samples.len() as f32;
    println!("Average Under-Load CPU: {:.1}% (samples: {:?})", avg_load, load_samples);

    keep_burning.store(false, Ordering::Relaxed);
    for h in handles {
        let _ = h.join();
    }

    thread::sleep(Duration::from_millis(300));
    let mut cooldown_samples = Vec::new();
    for _ in 0..3 {
        thread::sleep(Duration::from_millis(150));
        let s = telemetry::compute_real_cpu_percent();
        cooldown_samples.push(s);
    }
    let avg_cooldown: f32 = cooldown_samples.iter().sum::<f32>() / cooldown_samples.len() as f32;
    println!("Average Cooldown CPU: {:.1}% (samples: {:?})", avg_cooldown, cooldown_samples);

    if avg_load > avg_baseline && avg_load > 30.0 {
        println!("[PASS] CPU percent dynamically responds to CPU load! (Baseline: {:.1}%, Load: {:.1}%)", avg_baseline, avg_load);
    } else {
        println!("[FAIL] CPU percent did not increase sufficiently under full load! (Baseline: {:.1}%, Load: {:.1}%)", avg_baseline, avg_load);
        all_passed = false;
    }

    // Verify CPU is decoupled from RAM
    thread::sleep(Duration::from_millis(150));
    let telem = telemetry::collect_telemetry();
    println!("Telemetry: CPU={:.1}%, RAM={:.1}%", telem.cpu_percent, telem.ram_percent);
    let old_formula = ((telem.ram_percent * 0.42).clamp(8.0, 92.0) * 10.0).round() / 10.0;
    println!("Old RAM-derived formula expectation: {:.1}%", old_formula);
    if (avg_load - old_formula).abs() > 5.0 {
        println!("[PASS] CPU percent is completely decoupled from RAM formula! (Load: {:.1}%, Old Formula: {:.1}%)", avg_load, old_formula);
    }

    // ------------------------------------------------------------------------
    // [TEST 2] RAM Optimization Dynamic Trim Verification
    // ------------------------------------------------------------------------
    println!("\n--- [TEST 2] RAM Optimization Dynamic Trim Verification ---");
    let (ok1, msg1) = system_ops::execute_system_action("optimize_ram", "{}");
    println!("optimize_ram run 1: ok={}, msg=\"{}\"", ok1, msg1);

    if !ok1 {
        println!("[FAIL] optimize_ram returned false!");
        all_passed = false;
    }

    if msg1.contains("Đã hoàn trả 3.2 GB") {
        println!("[FAIL] optimize_ram returns static hardcoded 3.2 GB!");
        all_passed = false;
    } else {
        println!("[PASS] optimize_ram does NOT return static hardcoded 3.2 GB.");
    }

    if msg1.contains("Trống:") && msg1.contains("Tải:") {
        println!("[PASS] optimize_ram output includes live measured RAM capacity, free space, and load.");
    } else {
        println!("[FAIL] optimize_ram output missing live RAM telemetry fields: {}", msg1);
        all_passed = false;
    }

    // Allocate 100MB buffer to generate WorkingSet
    println!("Allocating 100MB buffer to generate WorkingSet...");
    let mut large_buffer: Vec<u8> = vec![0xAA; 100 * 1024 * 1024];
    for b in large_buffer.iter_mut().step_by(4096) {
        *b = 0x55;
    }
    thread::sleep(Duration::from_millis(200));

    let (ok2, msg2) = system_ops::execute_system_action("optimize_ram", "{}");
    println!("optimize_ram run 2 (after allocation): ok={}, msg=\"{}\"", ok2, msg2);

    drop(large_buffer);

    // ------------------------------------------------------------------------
    // [TEST 3] Rapid Invocations & Sub-80ms Rate Limiting
    // ------------------------------------------------------------------------
    println!("\n--- [TEST 3] Rapid Invocations & Sub-80ms Rate Limiting ---");
    thread::sleep(Duration::from_millis(150));
    let c1 = telemetry::compute_real_cpu_percent();
    let c2 = telemetry::compute_real_cpu_percent();
    println!("Rapid call results: c1 (dt>=150ms) = {:.1}%, c2 (immediate dt<1ms) = {:.1}%", c1, c2);

    if c2 == 0.0 {
        println!("[OBSERVATION] Sub-80ms invocations return 0.0% to guard against kernel time delta division by zero.");
    }

    thread::sleep(Duration::from_millis(120));
    let c3 = telemetry::compute_real_cpu_percent();
    println!("Call 3 (after 120ms sleep): c3 = {:.1}%", c3);
    if c3 > 0.0 {
        println!("[PASS] CPU rate limit guard resets and yields valid measurement once elapsed >= 80ms.");
    }

    // ------------------------------------------------------------------------
    // [TEST 4] Concurrency & In-Memory Mutex Stress Test
    // ------------------------------------------------------------------------
    println!("\n--- [TEST 4] Concurrency & Mutex Contention Stress Test ---");
    let num_threads = 16;
    let iterations_per_thread = 100;
    println!("Launching {} concurrent threads running {} iterations of telemetry + logging...", num_threads, iterations_per_thread);

    let start_time = Instant::now();
    let mut thread_handles = Vec::new();
    for t_idx in 0..num_threads {
        thread_handles.push(thread::spawn(move || {
            let mut err_count = 0;
            for i in 0..iterations_per_thread {
                let t = telemetry::collect_telemetry();
                if t.os_summary.is_empty() || t.cpu_cores == 0 {
                    err_count += 1;
                }
                if let Some((avail, total, load)) = system_ops::get_sys_memory_status() {
                    if total == 0 || load > 100 {
                        err_count += 1;
                    }
                }
                system_ops::append_log(&format!("Thread {} iter {}", t_idx, i));
                let _ = system_ops::get_logs_json();
            }
            err_count
        }));
    }

    let mut total_errors = 0;
    for h in thread_handles {
        match h.join() {
            Ok(errs) => total_errors += errs,
            Err(_) => {
                println!("[FAIL] Thread panicked during concurrent execution!");
                total_errors += 1;
            }
        }
    }
    let elapsed = start_time.elapsed();
    println!("Completed {} concurrent in-memory operations in {:.2?}s with {} errors", num_threads * iterations_per_thread * 4, elapsed, total_errors);

    if total_errors == 0 {
        println!("[PASS] High-concurrency telemetry and mutex operations passed with 0 errors!");
    } else {
        println!("[FAIL] Concurrency stress test had {} errors!", total_errors);
        all_passed = false;
    }

    // ------------------------------------------------------------------------
    // [TEST 5] PowerShell Operations Concurrency Test
    // ------------------------------------------------------------------------
    println!("\n--- [TEST 5] PowerShell Operations Concurrency Test ---");
    let mut ps_handles = Vec::new();
    for _ in 0..4 {
        ps_handles.push(thread::spawn(|| {
            let opt_state = system_ops::collect_win_optimize_state();
            opt_state.contains("classic_context") && opt_state.starts_with('{')
        }));
    }
    let mut ps_pass = true;
    for h in ps_handles {
        if let Ok(res) = h.join() {
            if !res {
                ps_pass = false;
            }
        } else {
            ps_pass = false;
        }
    }
    if ps_pass {
        println!("[PASS] Concurrent PowerShell Win32 queries succeeded without crashing.");
    } else {
        println!("[FAIL] Concurrent PowerShell Win32 queries failed!");
        all_passed = false;
    }

    // ------------------------------------------------------------------------
    // [TEST 6] Fail-Closed Fallback Verification
    // ------------------------------------------------------------------------
    println!("\n--- [TEST 6] Fail-Closed Fallback Verification ---");
    let (unknown_ok, unknown_msg) = system_ops::execute_system_action("unsupported_action_xyz", "{}");
    println!("Unsupported action result: ok={}, msg=\"{}\"", unknown_ok, unknown_msg);
    if !unknown_ok && unknown_msg.contains("không tồn tại") {
        println!("[PASS] Unsupported action fails closed (returns false with informative message).");
    } else {
        println!("[FAIL] Unsupported action did not fail closed: ok={}, msg={}", unknown_ok, unknown_msg);
        all_passed = false;
    }

    println!("\n===============================================================");
    if all_passed {
        println!(">>> ALL EMPIRICAL CHALLENGES PASSED (VERDICT: APPROVE) <<<");
    } else {
        println!(">>> SOME EMPIRICAL CHALLENGES FAILED (VERDICT: REQUEST_CHANGES) <<<");
        std::process::exit(1);
    }
}
