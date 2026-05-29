# System Overview

> Cập nhật: 2026-05-29

## Kiến trúc 3 project

```
┌──────────────┐     BLE (pairing)     ┌──────────────────────────────┐
│  Luni_App    │◄═════════════════════▶│         Luni_Robot           │
│  (Flutter)   │                       │  ┌─────────┐  ┌──────────┐  │
│              │     REST + FCM        │  │ ESP32-S3│  │ ESP32-C5 │  │
│              │◄═══════╗              │  │ Display │◄─┤ WiFi/BLE │  │
└──────────────┘        ║              │  │ Audio   │SPI│ Network  │  │
                        ║              │  │ Touch   │UART WS Client│  │
                   ┌────╨────┐         │  └─────────┘  └────┬─────┘  │
                   │Luni_Cloud│         └────────────────────┼────────┘
                   │(FastAPI) │◄═════════════════════════════╝
                   │ PG+Redis│          WebSocket (persistent)
                   └─────────┘
```

## Kênh giao tiếp

| Kênh | Protocol | Hướng | Mục đích |
|------|----------|-------|----------|
| App ↔ Cloud | REST HTTPS | Request-response | Auth, device CRUD, commands, OTA |
| App ← Cloud | FCM | Server push | Device alerts khi app background |
| App ↔ Cloud | WSS (foreground only) | Bidirectional | Realtime khi xem device detail |
| Robot ↔ Cloud | WSS (persistent) | Bidirectional | Commands, state, audio streaming |
| Robot ↔ Cloud | HTTPS | Download | OTA firmware |
| App ↔ Robot | BLE | Bidirectional | Provisioning (1 lần) |
| S3 ↔ C5 | SPI | Full-duplex | Audio frames |
| S3 ↔ C5 | UART | Bidirectional | Control/status |

## Tech Stack

| Layer | Công nghệ |
|-------|-----------|
| App | Flutter, Riverpod, Dio, flutter_blue_plus, firebase_messaging |
| Cloud | FastAPI, PostgreSQL, Redis, Nginx, Cloudflare Tunnel |
| Robot | ESP-IDF, PlatformIO, C++17, NimBLE, esp_websocket_client |
| AI | OpenAI / Claude API (STT, LLM, TTS) qua server proxy |

## Docs chi tiết

- [hybrid-realtime.md](hybrid-realtime.md) — Mô hình WS foreground + FCM background
- [ble-pairing.md](ble-pairing.md) — BLE provisioning flow + GATT characteristics
- [ws-protocol.md](ws-protocol.md) — WebSocket message types + binary audio format
