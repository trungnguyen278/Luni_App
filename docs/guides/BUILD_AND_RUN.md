# Build & Run Guide

## Yêu cầu

- Flutter SDK (xem ràng buộc trong `pubspec.yaml`)
- Android: Android SDK + thiết bị/emulator; iOS: Xcode (macOS)
- Firebase config cho FCM (`google-services.json` / `GoogleService-Info.plist`) nếu test push

```bash
flutter pub get
```

## Chạy (production backend mặc định)

App mặc định trỏ tới `https://lunirobot.io.vn`:

```bash
flutter run                          # debug
flutter run --release
```

## Trỏ về backend local (dev)

Override URL lúc build bằng `--dart-define` (xem [../architecture.md](../architecture.md)):

```bash
# Android emulator (host = 10.0.2.2). Cloud chạy ở http://localhost (nginx :80)
flutter run \
  --dart-define=LUNI_API_BASE_URL=http://10.0.2.2/api/v1 \
  --dart-define=LUNI_WS_BASE_URL=ws://10.0.2.2 \
  --dart-define=LUNI_DEVICE_WS_URL=ws://10.0.2.2/ws/device

# Thiết bị thật cùng LAN: thay 10.0.2.2 bằng IP máy chạy server
```

> `LUNI_DEVICE_WS_URL` là URL **robot** sẽ dùng (ghi qua BLE lúc pairing) — đặt sao cho robot truy cập được (domain công khai hoặc IP LAN), không phải `10.0.2.2`.

## Build APK

```bash
flutter build apk --debug      # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release
```

## Cài & test qua adb

```bash
adb devices
adb -s <serial> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <serial> shell monkey -p com.example.luni_app -c android.intent.category.LAUNCHER 1

# Screenshot để kiểm tra UI
adb -s <serial> exec-out screencap -p > screen.png

# Flutter render lên 1 surface → uiautomator không thấy node; thao tác bằng toạ độ:
adb -s <serial> shell input tap <x> <y>
adb -s <serial> shell input swipe <x1> <y1> <x2> <y2> <ms>
```

Package id: `com.example.luni_app`.

## Tài khoản test

Hai tài khoản seed sẵn trong DB Cloud (mật khẩu chung: `luni2026`):

| Vai trò | Email             | Mật khẩu   | Dùng cho                       |
| ------- | ----------------- | ---------- | ------------------------------ |
| User    | `test@example.com`| `luni2026` | App quản lý robot              |
| Admin   | `admin@luni.vn`   | `luni2026` | Bảng dịch vụ kỹ thuật (web)    |

> Trước đây hai tài khoản này hiện trong màn đăng nhập dưới dạng nút "Tài khoản demo".
> Đã gỡ khỏi UI — nhập email/mật khẩu thủ công khi cần. Email khớp `admin|service|@luni.`
> sẽ tự đổi nút sang chế độ Admin (xem `_looksAdmin` trong `login_screen.dart`).
>
> Đặt lại mật khẩu khi cần (chạy ở máy có Docker stack Luni Cloud):
>
> ```bash
> hash=$(docker exec luni-api python -c "from app.core.security import hash_password; print(hash_password('luni2026'))")
> docker exec luni-db psql -U luni -d luni \
>   -c "UPDATE users SET password='$hash' WHERE email='test@example.com';"
> ```

## Test

```bash
flutter test
flutter analyze
```
