# Quy tắc phát triển dự án (Project Rules)

- **QUY TẮC NÂNG VERSION & KIỂM THỬ CỤC BỘ (LOCAL VERSION BUMP & TEST)**:
  - **Mỗi lần sửa lỗi (fix) hoặc nâng cấp tính năng**: Tự động tăng 1 số Version (Build Increment, ví dụ `v20.5.909.01` -> `v20.5.909.02`) đồng bộ trên toàn bộ mã nguồn (`version.json`, `MainWindow.xaml`, `src/Program.cs`, `AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`) và biên dịch ra file thực thi `E:\toolwindows\VUONGTT_Toolkit.exe`.
  - **Xác nhận qua giao diện local**: Người dùng khởi chạy `E:\toolwindows\VUONGTT_Toolkit.exe` tại máy sẽ thấy ngay số hiệu phiên bản mới trên Window Title, Logo Header và Footer Bar, xác thực mã nguồn mới đã được áp dụng.
  - **Quy trình lặp lại (Iterative Fix)**: Nếu phát hiện lỗi trong quá trình kiểm thử, tiếp tục fix trực tiếp và nâng tiếp 1 version cho đến khi hoàn chỉnh.

- **QUY TẮC PHÁT HÀNH (PUBLISH & GIT PUSH)**:
  - **TỰ ĐỘNG `git push` SAU KHI HOÀN TẤT**: Sau khi chỉnh sửa mã nguồn, kiểm tra lỗi, chạy bộ kiểm thử tự động đạt 100% PASS và biên dịch xong file thực thi `VUONGTT_Toolkit.exe` tại local, tự động lưu commit và thực hiện `git push origin main` luôn mà không cần phải hỏi lại người dùng.