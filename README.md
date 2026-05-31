# Luni App

Flutter mobile app cho hệ thống Luni Robot (iOS + Android).

## Features

- BLE pairing flow (kết nối robot qua Bluetooth)
- Device control (emotion, scene, volume, brightness)
- Chat (text interaction with robot via LLM)
- Realtime status via WebSocket (online/pin/cảm xúc/`interaction_result`)
- Weather + lunar calendar (qua `GET /data/sync/{id}`)
- Device sharing (mời/gỡ người dùng theo email)
- Profile & đổi mật khẩu (`/auth/me`, `/auth/change-password`)
- Stats dashboard (`GET /devices/{id}/stats`)
- OTA firmware update monitoring
- Device logs viewer
- Push notifications (FCM → `/push/register`)
- Admin BLE panel (Level 2 — factory reset, diagnostics, firmware rollback)

## Tech Stack

- **Flutter** (Dart) — cross-platform iOS/Android
- **Riverpod** — state management
- **Dio** — HTTP client + JWT interceptor (tự refresh khi 401)
- **web_socket_channel** — realtime WS tới `/ws/app/{deviceId}`
- **flutter_blue_plus** — BLE scanning + pairing
- **flutter_secure_storage** — lưu access/refresh token
- **firebase_messaging** — push notification (FCM)
- **Hive** — offline cache
- **go_router** — navigation

### Cấu hình kết nối (mặc định trỏ production)

| Hằng | Mặc định | Override khi build |
|------|----------|--------------------|
| API base | `https://lunirobot.io.vn/api/v1` | `--dart-define=LUNI_API_BASE_URL=…` |
| WebSocket | `wss://lunirobot.io.vn` | `--dart-define=LUNI_WS_BASE_URL=…` |

Dùng backend local từ Android emulator (host = `10.0.2.2`):

```bash
flutter pub get
flutter run --dart-define=LUNI_API_BASE_URL=http://10.0.2.2:8000/api/v1 \
            --dart-define=LUNI_WS_BASE_URL=ws://10.0.2.2:8000
```

## Documentation

📖 **[docs/](docs/README.md)** — index đầy đủ.

- [Architecture](docs/architecture.md) — cấu trúc app, Riverpod providers, routing, config
- [System Overview](docs/system-overview.md) — kiến trúc 3 project + kênh giao tiếp
- Modules: [ble-pairing](docs/ble-pairing.md) · [ws-protocol](docs/ws-protocol.md) · [hybrid-realtime](docs/hybrid-realtime.md)
- Guides: [build & run](docs/guides/BUILD_AND_RUN.md)

## Related Repos

| Repo | Mô tả |
|------|--------|
| [Luni_Robot](https://github.com/trungnguyen278/Luni_Robot) | Firmware ESP32-S3 + ESP32-C5 (display, audio, network) |
| [Luni_Cloud](https://github.com/trungnguyen278/Luni_Cloud) | FastAPI server + AI gateway + web dashboard (Docker Compose) |
