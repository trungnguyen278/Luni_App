# Luni App — Documentation

Flutter app (iOS + Android) cho hệ thống Luni Robot. Tài liệu chia theo **module**.

## Architecture & modules

| Doc | Nội dung |
|-----|----------|
| [architecture.md](architecture.md) | Cấu trúc app, layers, Riverpod providers, routing, màn hình |
| [system-overview.md](system-overview.md) | Kiến trúc 3 project + kênh giao tiếp (App/Cloud/Robot) |
| [ble-pairing.md](ble-pairing.md) | BLE provisioning flow + GATT characteristics |
| [ws-protocol.md](ws-protocol.md) | WebSocket message types + binary audio |
| [hybrid-realtime.md](hybrid-realtime.md) | WS foreground + FCM background |

## Guides

| Guide | Nội dung |
|-------|----------|
| [guides/BUILD_AND_RUN.md](guides/BUILD_AND_RUN.md) | Build, cấu hình API URL (dev/prod), chạy & test qua adb |

## Related repos

| Repo | Mô tả |
|------|--------|
| [Luni_Cloud](https://github.com/trungnguyen278/Luni_Cloud) | FastAPI server + web admin |
| [Luni_Robot](https://github.com/trungnguyen278/Luni_Robot) | Firmware ESP32-S3 + ESP32-C5 |
