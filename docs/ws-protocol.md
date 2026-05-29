# WebSocket Protocol

> Cập nhật: 2026-05-29

2 WS endpoints: 1 cho device (robot), 1 cho app/web client.

## Endpoints

| Endpoint | Auth | Client |
|----------|------|--------|
| `WS /ws/device` | device_token + MAC handshake | Robot (ESP32-C5) |
| `WS /ws/app/{device_id}?token=<jwt>` | JWT query param | App/Web |

## Message Format (Text Frames)

```json
{
  "type": "<message_type>",
  "id": "uuid-v4",
  "ts": 1716825600000,
  "payload": { ... }
}
```

## Device ↔ Server

### Auth Handshake

```
Device → Server:  {"type": "auth", "payload": {"device_token": "...", "mac": "AA:BB:...", "fw_version": "2.1.0", "model": "luni_v2_s3c5"}}
Server → Device:  {"type": "auth_result", "payload": {"status": "ok"}}
```

Timeout: 5s. Fail → close 4001.

### Device → Server

| type | payload | Mô tả |
|------|---------|--------|
| `heartbeat` | `{uptime, free_heap, rssi}` | Mỗi 30s |
| `device_info` | `{mac, fw_version, model}` | Sau auth OK |
| `state_update` | `{category, old, new}` | State changes |
| `battery` | `{voltage, percent, charging}` | Pin |
| `ota_progress` | `{percent, phase}` | OTA status |
| `error` | `{code, message, severity}` | Lỗi |
| `log` | `{level, tag, message}` | Device log |
| `audio_end` | `{}` | Silence detected |

### Server → Device

| type | payload | Mô tả |
|------|---------|--------|
| `set_volume` | `{value: 0-100}` | Chỉnh volume |
| `set_brightness` | `{value: 0-100}` | Chỉnh brightness |
| `set_emotion` | `{emotion, variant}` | Đổi cảm xúc |
| `set_scene` | `{scene, data}` | Đổi scene |
| `reboot` | `{}` | Restart |
| `ota_available` | `{version, url, sha256, size}` | OTA mới |
| `sync_data` | `{time, weather, calendar, location}` | Data sync |
| `tts_play` | `{text}` | Text-to-speech |
| `audio_stop` | `{}` | Dừng audio |
| `config_update` | `{key, value}` | Cập nhật config |
| `interaction_msg` | `{from, text, source}` | Chat từ user |
| `ack` | `{ref_id}` | Xác nhận nhận message |

## App ↔ Server

### App → Server (qua WS)

| type | Mô tả |
|------|--------|
| `ping` | Keepalive (30s) |
| `set_volume`, `set_brightness`, `set_emotion`, `set_scene`, `reboot`, `tts_play`, `audio_stop` | Forward to device |

### Server → App (broadcast)

| type | Nguồn | Mô tả |
|------|-------|--------|
| `current_state` | Server | Gửi khi app connect |
| `device_online` | Server | Device vừa connect |
| `device_offline` | Server | Device mất kết nối |
| `state_update` | Relay từ device | State changes |
| `battery` | Relay từ device | Pin |
| `ota_progress` | Relay từ device | OTA status |
| `error` | Relay từ device | Lỗi |
| `interaction_result` | Server | Kết quả LLM |
| `command_ack` | Server | Xác nhận command đã gửi |

## Binary Frames (Audio)

```
┌──────────┬───────────┬──────────┬──────────────────┐
│ Direction│ Sequence  │  Length  │   Opus Payload    │
│  1 byte  │  2 bytes  │  2 bytes │   N bytes         │
│ 0xAA/0xAB│  (LE)     │  (LE)    │                   │
└──────────┴───────────┴──────────┴──────────────────┘
```

- `0xAA` = uplink (mic → server)
- `0xAB` = downlink (server → speaker)
- Opus: 48kHz, 16-bit mono, frame 20ms

## Timing

| Parameter | Value |
|-----------|-------|
| Device heartbeat | 30s |
| Server check | 60s |
| Offline threshold | 90s (3 missed) |
| WS auth timeout | 5s |
| App ping | 30s |
| Reconnect backoff | 1s → 30s max, 10 retries |
