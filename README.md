Ứng dụng Flutter quét và kết nối với thiết bị Bluetooth HC-05.

## Chức năng chính:

1️⃣ **Quét thiết bị Bluetooth HC-05**:

- Nhấn nút "Quét thiết bị HC-05" để tìm thiết bị HC-05 gần đó.
- Ứng dụng sẽ lọc và chỉ hiển thị các thiết bị HC-05.
- Hiển thị tên và địa chỉ MAC của thiết bị.

2️⃣ **Kết nối và gửi dữ liệu**:

- Khi kết nối thành công, hiển thị thông báo "Đã kết nối với HC-05".
- Nhập dữ liệu cần gửi vào TextField.
- Nhấn nút "Gửi" để gửi dữ liệu dưới dạng chuỗi text tới HC-05.

3️⃣ **Cấu trúc code**:

- Sử dụng `StatefulWidget` để cập nhật UI.
- Logic Bluetooth được xử lý trong `_BluetoothPageState`.
- Sử dụng `async/await` để xử lý kết nối Bluetooth.

4️⃣ **Giao diện UI**:

- Sử dụng Material Design với AppBar và các ElevatedButton.
- Hiển thị danh sách thiết bị bằng ListView.
- Hiệu ứng loading khi đang quét thiết bị.

## Cách chạy ứng dụng:

1. Thêm dependency `flutter_blue_plus` vào `pubspec.yaml`.
2. Chạy lệnh `flutter pub get`.
3. Chạy ứng dụng trên thiết bị Android.
