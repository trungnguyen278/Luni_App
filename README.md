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

- [System Architecture](docs/plan/SYSTEM_ARCHITECTURE.md) — tổng quan toàn hệ thống
- [App Plan](docs/plan/PLAN_APP.md) — chi tiết BLE protocol, pairing flow, screens

## Related Repos

| Repo | Mô tả |
|------|--------|
| [Luni_Robot](https://github.com/trungnguyen278/Luni_Robot) | Firmware ESP32-S3 + ESP32-C5 (display, audio, network) |
| [Luni_Cloud](https://github.com/trungnguyen278/Luni_Cloud) | FastAPI server + Next.js web admin (Docker Compose) |
