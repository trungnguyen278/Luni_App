# Hybrid Realtime — WS + FCM

> Cập nhật: 2026-05-29

App dùng mô hình **hybrid**: WebSocket khi foreground, FCM khi background.

## Nguyên tắc

| Trạng thái App | Kênh realtime | Cách hoạt động |
|----------------|---------------|----------------|
| Đang xem device detail | **WebSocket** | `activeDeviceWsProvider(deviceId)` auto-connect khi vào, auto-disconnect khi rời |
| Home screen / device list | **FCM** | Push event trigger REST refresh |
| App background | **FCM** | OS notification tray |

## Flow chi tiết

### Foreground — Device Detail (WS)

```
DeviceDetailScreen
  → ref.watch(activeDeviceWsProvider(deviceId))
    → ws.connect(deviceId)
    → WS /ws/app/{device_id}?token=<jwt>
    → Nhận: state_update, battery, device_online/offline, interaction_result
    → DeviceListNotifier._listenWsUpdates() cập nhật state
  → ref dispose (rời screen)
    → ws.disconnect()
```

WS chỉ sống khi user đang xem 1 device cụ thể. Reconnect logic:
exponential backoff 1s → 2s → 4s → ... → 30s, max 10 retries.

### Background — Device List & Notifications (FCM)

```
Server phát hiện event (device offline, battery critical, ...)
  → Kiểm tra: app WS có connected không?
    → Có: đã gửi qua WS, skip FCM
    → Không: gửi FCM data message
      → { "type": "device_offline", "device_id": "AA:BB:..." }

App nhận FCM:
  → PushService._handleForeground() parse message
  → DevicePushEvent emit vào stream
  → DeviceListNotifier._listenFcmUpdates() nhận event
  → Gọi refreshDevices() → REST GET /devices
```

### FCM Data Message Format

```json
{
  "data": {
    "type": "device_online | device_offline | battery_critical | ota_available | interaction_result",
    "device_id": "AA:BB:CC:DD:EE:FF"
  }
}
```

## Providers

| Provider | Loại | Mục đích |
|----------|------|----------|
| `wsClientProvider` | `Provider` | Singleton WS client, tái tạo khi auth thay đổi |
| `activeDeviceWsProvider(deviceId)` | `Provider.autoDispose.family` | Auto connect/disconnect WS theo screen lifecycle |
| `pushServiceProvider` | `Provider` | FCM registration + event stream |
| `deviceListProvider` | `AsyncNotifierProvider` | Device list, subscribe cả WS (khi connected) và FCM |

## Khi nào dùng gì

- **Cần instant feedback** (điều khiển volume, emotion): WS (đang ở device detail)
- **Device status changes**: WS nếu đang xem, FCM nếu không
- **Commands** (set_volume, reboot, tts_play): Luôn qua REST `POST /devices/{id}/command`
- **Offline alerts**: FCM → OS notification
