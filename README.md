# Luni App

Flutter mobile app cho hệ thống Luni Robot (iOS + Android).

## Features

- BLE pairing flow (kết nối robot qua Bluetooth)
- Device control (emotion, scene, volume, brightness)
- Chat (text interaction with robot via LLM)
- Realtime status via WebSocket
- OTA firmware update monitoring
- Device logs viewer
- Push notifications (FCM)
- Admin BLE panel (Level 2 — factory reset, diagnostics, firmware rollback)

## Tech Stack

- **Flutter** (Dart) — cross-platform iOS/Android
- **Riverpod** — state management
- **Dio** — HTTP client + JWT interceptor
- **flutter_blue_plus** — BLE scanning + pairing
- **Hive** — offline cache
- **go_router** — navigation

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
| [Luni_Cloud](https://github.com/trungnguyen278/Luni_Cloud) | FastAPI server + Next.js web admin (Docker Compose) |
