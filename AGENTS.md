# Quy tắc phát triển dự án (Project Rules)

- **QUY TẮC PHÁT HÀNH (PUBLISH & GIT PUSH)**:
  - **TUYỆT ĐỐI KHÔNG TỰ Ý `git push` LÊN GITHUB**: Sau khi chỉnh sửa mã nguồn, kiểm tra lỗi và biên dịch xong file `VUONGTT_Toolkit.exe` tại local, chỉ lưu và kiểm thử tại máy cục bộ.
  - **KHÔNG CHẠY LỆNH `git push`**: Đợi người dùng kiểm thử (test) hoàn tất. Người dùng sẽ tự chủ động cập nhật và phát hành thủ công bằng file script `Publish-Update.ps1`.