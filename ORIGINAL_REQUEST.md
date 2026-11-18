# Original User Request

## Initial Request — 2026-11-18T04:54:23Z

Fix Windows Setup error 0x80070490 in e:\toolwindows. 
Follow the process:
1. Use diskpart/mountvol to check system partitions.
2. Identify space issues.
3. Free space or extend partition if needed.
4. Verify fix.

## Follow-up — 2026-11-18T09:35:05Z

Tích hợp chức năng quản lý và dọn dẹp dữ liệu Zalo vào phân hệ "Dọn Dẹp & Tăng tốc" của VUONGTT Toolkit.
Yêu cầu:
1. Đổi tên sidebar mục "Dọn Dẹp & Tăng Tốc" thành "Dọn Dẹp & Tăng tốc, xóa Zalo".
2. Thêm module giao diện mới: "Quản Lý Dữ Liệu Zalo" tại `src-ui\index.html` (view-clean-uninstaller hoặc tương đương).
3. Backend: Bổ sung IPC actions (in `src-tauri/src/system_ops.rs`) để:
   - Tự động tìm đường dẫn Zalo Data: `C:\Users\{username}\AppData\Roaming\ZaloData\media`
   - Quét dung lượng các thư mục con (ví dụ: `2279715857995480376\ZaloDownloads`).
   - Xóa file theo filter thời gian: Giữ lại 3 tháng/6 tháng/tùy chỉnh (dựa trên LastWriteTime).
4. Đồng bộ hóa streaming log vào Universal Console Log Drawer.
5. Kiểm thử, nâng version `v20.5.909.188`, build, và git push.
