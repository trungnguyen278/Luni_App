# BLE Pairing Flow

> Cập nhật: 2026-05-29

Provisioning robot qua Bluetooth Low Energy. Chỉ xảy ra 1 lần khi pair device mới.

## GATT Service

**Service UUID**: `0xFF01`

| UUID | Tên | Access | Level | Mô tả |
|------|-----|--------|-------|--------|
| `0x0001` | SSID | RW | L1 | WiFi network name |
| `0x0002` | PASSWORD | W | L1 | WiFi password |
| `0x0003` | WS_URL | RW | L1 | WebSocket server URL |
| `0x0004` | COMMIT | WN | L1 | Trigger lưu config vào NVS |
| `0x0005` | USER_ID | RW | L1 | Owner user UUID |
| `0x0006` | DEVICE_INFO | R | L0 | JSON: mac, model, fw_version, name |
| `0x0007` | DIAG_INFO | R | L2 | JSON: free_heap, uptime, partition |
| `0x0008` | DEV_TOKEN | W | L1 | Device auth token (128-char hex) |
| `0x0010` | AUTH_UNLOCK | WN | L0 | 6-digit PIN verification |
| `0x0011` | COMMAND | WN | L1/L2 | Control commands |
| `0x0012` | ADMIN_AUTH | WN | L1 | HMAC-SHA256 admin token |
| `0x0013` | LOG_LEVEL | RW | L2 | Debug level (1 byte) |
| `0x0014` | ADMIN_SECRET | W | L1 | Server-signed admin secret |

## Access Levels

- **L0**: Không cần auth — chỉ đọc device info
- **L1**: PIN 6 số hiển thị trên robot → ghi vào `AUTH_UNLOCK` (0x0010)
- **L2**: HMAC-SHA256 token → ghi vào `ADMIN_AUTH` (0x0012)

## Pairing Sequence

```
App                    Robot (C5 BLE)              Server
 │                         │                          │
 │── BLE Scan ────────────▶│                          │
 │◀── Advertise "Luni" ───│                          │
 │                         │                          │
 │── BLE Connect ─────────▶│                          │
 │── Read DEVICE_INFO (0x0006) ──▶│                   │
 │◀── JSON {mac, model, fw} ─────│                    │
 │                         │                          │
 │  [User nhập PIN trên app]     │                    │
 │── Write AUTH_UNLOCK (0x0010) ─▶│                   │
 │◀── Notify 0x00 (OK) ──────────│                    │
 │                         │                          │
 │  [User nhập WiFi SSID+Pass]  │                     │
 │── Write SSID (0x0001) ────────▶│                   │
 │── Write PASSWORD (0x0002) ────▶│                   │
 │                         │                          │
 │── POST /devices ──────────────────────────────────▶│
 │◀── {device_token, admin_secret} ──────────────────│
 │                         │                          │
 │── Write DEV_TOKEN (0x0008) ───▶│                   │
 │── Write USER_ID (0x0005) ─────▶│                   │
 │── Write ADMIN_SECRET (0x0014) ─▶│                  │
 │── Write WS_URL (0x0003) ──────▶│                   │
 │                         │                          │
 │── Write COMMIT (0x0004) ──────▶│ Validate + NVS save│
 │◀── Notify 0x00 (OK) ──────────│                    │
 │                         │                          │
 │── Write COMMAND restart (0x0011) ▶│                 │
 │                         │                          │
 │  [Poll /devices/{id}/status]  │── WiFi connect ──▶│
 │                         │     │── WS auth ────────▶│
 │◀── {is_online: true} ──────────────────────────────│
```

## Token Lifecycle

1. Server sinh `device_token` = `secrets.token_hex(64)` → 128 chars hex
2. Lưu DB: `devices.device_token`
3. App nhận từ `POST /devices` response
4. App ghi vào robot BLE char `0x0008`
5. Robot lưu NVS key `"device_token"` khi COMMIT
6. Robot dùng token cho WS auth handshake mỗi lần connect

**Token chỉ ghi 1 lần** qua BLE khi pairing. Sau đó robot dùng token từ NVS.
Re-pair cùng device → server sinh token mới → phải ghi lại qua BLE.

## BLE Commands (0x0011)

| Byte | Command | Level |
|------|---------|-------|
| `0x01` | Restart | L1 |
| `0x10` | Factory Reset | L2 |
| `0x11` | Full Wipe | L2 |
| `0x12` | Rollback Firmware | L2 |
| `0x13` | Enable Debug | L2 |
| `0x14` | Disable Debug | L2 |
| `0x15` | Clear Users | L2 |
| `0x16` | Enter DFU | L2 |
