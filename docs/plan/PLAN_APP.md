# Luni Mobile App — Detailed Plan

> Platform: Flutter (iOS + Android)
> Backend: FastAPI REST API + WebSocket (shared với Web)
> DB: PostgreSQL (truy cập qua API, không trực tiếp)

---

## 1. Vai trò App vs Web

```
App và Web dùng CHUNG 1 FastAPI backend:
  ✓ Cùng REST API endpoints, cùng response format
  ✓ Cùng auth flow (login → JWT + refresh token)
  ✓ Cùng WebSocket protocol cho realtime
  ✓ Cùng data models

App có RIÊNG:
  ✓ BLE pairing flow (kết nối robot qua Bluetooth)
  ✓ Push notifications (FCM)
  ✓ Offline cache (Hive)
  ✓ Push-to-talk audio (tương lai)
  ✓ Optimized cho mobile UX (gestures, haptics)

Web có RIÊNG:
  ✓ Admin dashboard (users, firmware, system health)
  ✓ Server log viewer
  ✓ Firmware upload
  → Xem chi tiết: PLAN_SERVER.md §14
```

## 2. Project Structure

```
luni_app/
├── lib/
│   ├── main.dart
│   ├── app.dart                        # MaterialApp, routing, theme
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart         # API URLs, env vars
│   │   │   └── theme.dart              # Luni design system
│   │   ├── network/
│   │   │   ├── api_client.dart         # Dio HTTP client + JWT interceptor
│   │   │   ├── ws_client.dart          # WebSocket for realtime updates
│   │   │   └── api_exceptions.dart     # Error mapping
│   │   ├── auth/
│   │   │   ├── auth_provider.dart      # JWT storage, auto-refresh
│   │   │   └── auth_guard.dart         # Route protection
│   │   ├── bluetooth/
│   │   │   ├── ble_scanner.dart        # Scan for Luni devices
│   │   │   ├── ble_connector.dart      # Connect + read/write characteristics
│   │   │   └── ble_protocol.dart       # Characteristic UUIDs, data format
│   │   └── storage/
│   │       └── local_storage.dart      # Hive (offline cache)
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       ├── register_screen.dart
│   │   │       └── forgot_password_screen.dart
│   │   │
│   │   ├── home/
│   │   │   ├── screens/home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── device_card.dart
│   │   │       └── quick_action_bar.dart
│   │   │
│   │   ├── pairing/                    # BLE pairing flow
│   │   │   ├── screens/
│   │   │   │   ├── scan_screen.dart        # BLE scan, show nearby devices
│   │   │   │   ├── connect_screen.dart     # Connecting animation
│   │   │   │   ├── wifi_setup_screen.dart  # Enter WiFi SSID/password
│   │   │   │   ├── server_setup_screen.dart # Auto or manual server URL
│   │   │   │   ├── naming_screen.dart      # Name the robot
│   │   │   │   ├── pairing_done_screen.dart # Success + verify online
│   │   │   │   └── admin_ble_screen.dart   # Admin BLE panel (Level 2, role=admin)
│   │   │   ├── providers/
│   │   │   │   ├── pairing_notifier.dart   # State machine for pairing flow
│   │   │   │   └── admin_ble_notifier.dart # Admin BLE auth + commands
│   │   │   └── widgets/
│   │   │       ├── ble_device_tile.dart
│   │   │       ├── wifi_network_list.dart
│   │   │       ├── pairing_progress.dart
│   │   │       ├── admin_command_tile.dart  # Admin command button with confirmation
│   │   │       └── diag_info_card.dart     # Display DIAG_INFO data
│   │   │
│   │   ├── device/
│   │   │   ├── screens/
│   │   │   │   ├── device_detail_screen.dart
│   │   │   │   ├── device_settings_screen.dart
│   │   │   │   └── device_sharing_screen.dart
│   │   │   ├── providers/
│   │   │   │   ├── device_list_notifier.dart
│   │   │   │   └── device_detail_notifier.dart
│   │   │   └── widgets/
│   │   │       ├── emotion_picker.dart
│   │   │       ├── scene_picker.dart
│   │   │       ├── volume_slider.dart
│   │   │       ├── brightness_slider.dart
│   │   │       └── battery_indicator.dart
│   │   │
│   │   ├── chat/                       # User ↔ Robot interaction
│   │   │   ├── screens/chat_screen.dart
│   │   │   └── widgets/
│   │   │       ├── chat_bubble.dart
│   │   │       ├── chat_input.dart
│   │   │       └── talk_button.dart    # Push-to-talk (future)
│   │   │
│   │   ├── logs/
│   │   │   └── screens/log_viewer_screen.dart
│   │   │
│   │   ├── stats/
│   │   │   └── screens/stats_screen.dart
│   │   │
│   │   ├── ota/
│   │   │   └── screens/ota_screen.dart
│   │   │
│   │   └── settings/
│   │       └── screens/
│   │           ├── app_settings_screen.dart
│   │           └── profile_screen.dart
│   │
│   └── shared/
│       ├── models/
│       │   ├── device.dart
│       │   ├── user.dart
│       │   ├── log_entry.dart
│       │   ├── interaction.dart
│       │   └── firmware.dart
│       └── widgets/
│           ├── luni_app_bar.dart
│           ├── loading_overlay.dart
│           └── error_widget.dart
│
├── assets/
│   ├── icons/                          # Emotion/scene icons (SVG)
│   ├── animations/                     # Lottie (pairing, loading)
│   └── fonts/
├── pubspec.yaml
└── test/
```

## 3. BLE Pairing Flow — Chi tiết

### 3.1 BLE Protocol (Robot side — ESP32-C5)

```
Service UUID: 0xFF01

=== Access Levels ===
  Level 0: Không auth → chỉ read DEVICE_INFO
  Level 1: User auth (PIN trên màn hình robot) → pairing, restart
  Level 2: Admin auth (server-signed token) → tất cả + admin commands

=== Characteristics ===

  Provisioning (Level 1+):
  0x0001  SSID         (R/W, max 32 bytes)
  0x0002  PASSWORD     (W-only, max 64 bytes)
  0x0003  WS_URL       (R/W, max 128 bytes)
  0x0004  DEV_TOKEN    (W-only, max 128 bytes)
  0x0005  USER_ID      (R/W, max 36 bytes, UUID)

  Info:
  0x0006  DEVICE_INFO  (R-only, Level 0+, JSON)
  0x0007  DIAG_INFO    (R-only, Level 2, JSON — extended diagnostics)

  Security:
  0x0010  AUTH_UNLOCK   (W, 6-char PIN → Level 1)
  0x0012  ADMIN_AUTH    (W, HMAC token + timestamp → Level 2)

  Control:
  0x0011  COMMAND       (W, 1 byte — xem bảng commands)
  0x0013  LOG_LEVEL     (R/W, Level 2, 1 byte: 10/20/30/40)
  0x0014  ADMIN_SECRET  (W-only, Level 1, 32 bytes — admin BLE auth key, written during pairing)

=== COMMAND values ===
  Level 1:
    0x01  restart

  Level 2 (Admin):
    0x10  factory_reset     — xóa WiFi + token, giữ firmware
    0x11  full_wipe         — xóa toàn bộ NVS
    0x12  rollback_fw       — roll back firmware
    0x13  enable_debug      — bật debug log tạm
    0x14  disable_debug     — tắt debug log
    0x15  clear_users       — xóa tất cả user IDs
    0x16  enter_dfu         — chế độ firmware download

  Response (notify): 0x00=OK, 0x01=FAIL, 0x02=UNAUTHORIZED

=== DEVICE_INFO (Level 0, JSON ~150B) ===
  { "mac": "AA:BB:CC:DD:EE:FF", "model": "luni_v2_s3c5",
    "fw_version": "2.1.0", "name": "Luni" }

=== DIAG_INFO (Level 2, JSON ~300B) ===
  { "free_heap": 45032, "uptime_s": 86400, "reset_reason": "power_on",
    "wifi_rssi": -42, "ws_state": "ONLINE", "fw_partition": "ota_0",
    "ota_rollback_available": true, "spi_errors": 0, "battery_mv": 3850 }
```

### 3.2 Pairing State Machine (App)

```
                ┌──────────┐
     start ────▶│ SCANNING │
                └─────┬────┘
                      │ device found, user selects
                ┌─────▼──────┐
                │ CONNECTING │──── timeout ──→ ERROR
                └─────┬──────┘
                      │ BLE connected
                ┌─────▼──────┐
                │ READ_INFO  │──── fail ──→ ERROR
                └─────┬──────┘
                      │ got MAC, model, fw_version (Level 0)
                ┌─────▼──────┐
                │  PIN_AUTH  │──── wrong PIN ──→ retry (max 3x)
                └─────┬──────┘
                      │ write PIN to AUTH_UNLOCK → Level 1
                      │ (PIN hiển thị trên màn hình robot)
                ┌─────▼──────┐
                │ WIFI_SETUP │
                └─────┬──────┘
                      │ user enters SSID + password
                ┌─────▼──────┐
                │ WRITE_WIFI │──── BLE write fail ──→ ERROR
                └─────┬──────┘
                      │ SSID + password written
                ┌─────▼──────┐
                │ GEN_TOKEN  │
                └─────┬──────┘
                      │ generate device_token (random 64 bytes → hex)
                      │ POST /api/v1/devices { mac, name, model, token }
                      │ → server returns { device_id, admin_secret }
                ┌─────▼──────┐
                │ WRITE_TOKEN│──── BLE write fail ──→ ERROR
                └─────┬──────┘
                      │ device_token + admin_secret + WS URL + user_id written
                ┌─────▼──────┐
                │ WRITE_URL  │
                └─────┬──────┘
                      │ server URL written
                ┌─────▼──────┐
                │  RESTART   │
                └─────┬──────┘
                      │ BLE command: restart device
                      │ disconnect BLE
                ┌─────▼──────┐
                │  VERIFY    │──── timeout 30s ──→ WARN (manual check)
                └─────┬──────┘
                      │ poll GET /devices/:id/status until online
                ┌─────▼──────┐
                │   DONE     │──→ navigate to device detail
                └────────────┘
```

### 3.3 Admin BLE Flow (role == admin)

```
Admin vào Device Settings → "Quản lý nâng cao" → BLE connect

                ┌──────────┐
     start ────▶│ SCANNING │
                └─────┬────┘
                      │ chọn device (đã paired)
                ┌─────▼──────┐
                │ CONNECTING │
                └─────┬──────┘
                      │ BLE connected
                ┌─────▼──────┐
                │ READ_INFO  │  Level 0
                └─────┬──────┘
                ┌─────▼──────┐
                │  PIN_AUTH  │  → Level 1
                └─────┬──────┘
                ┌─────▼──────┐
                │ ADMIN_AUTH │  App gọi POST /api/v1/devices/:id/ble-token
                └─────┬──────┘  → server trả admin_token (HMAC-SHA256)
                      │         Write admin_token vào ADMIN_AUTH → Level 2
                      │ fail → notify "Không có quyền admin"
                ┌─────▼──────────────────────────────────────────┐
                │           ADMIN PANEL (Level 2)                │
                │                                                │
                │  ┌── Diagnostics ──────────────────────────┐   │
                │  │ Read DIAG_INFO: heap, uptime, RSSI,     │   │
                │  │ partition, errors, battery, S3 state     │   │
                │  └─────────────────────────────────────────┘   │
                │                                                │
                │  ┌── Cấu hình ─────────────────────────────┐   │
                │  │ Đổi server URL (WS_URL)                 │   │
                │  │ Đổi log level (LOG_LEVEL)                │   │
                │  │ Đổi WiFi (SSID + PASSWORD)               │   │
                │  └─────────────────────────────────────────┘   │
                │                                                │
                │  ┌── Admin Commands ───────────────────────┐   │
                │  │ [Factory Reset]  → xóa WiFi + token     │   │
                │  │ [Full Wipe]      → xóa toàn bộ NVS      │   │
                │  │ [Rollback FW]    → firmware cũ           │   │
                │  │ [Debug Mode]     → bật/tắt debug log     │   │
                │  │ [Clear Users]    → xóa tất cả users      │   │
                │  │ [Enter DFU]      → chế độ flash UART/USB │   │
                │  └─────────────────────────────────────────┘   │
                └────────────────────────────────────────────────┘
```

### 3.4 WiFi Scan (optional improvement)

```dart
// Robot BLE có thể thêm characteristic cho WiFi scan results:
// 0x0020  WIFI_SCAN_TRIGGER  (write: trigger scan)
// 0x0021  WIFI_SCAN_RESULT   (read/notify: JSON list of networks)
//
// Flow:
// 1. App writes 0x01 to WIFI_SCAN_TRIGGER
// 2. Robot scans WiFi, writes results to WIFI_SCAN_RESULT
// 3. App reads → show list for user to pick
// 4. User selects → auto-fill SSID
//
// Alternative: user types SSID manually (simpler, current approach)
```

### 3.5 Error Recovery

| Error | Handling |
|-------|---------|
| BLE scan timeout | Show "Đảm bảo robot đang bật và ở gần" + retry |
| BLE connect fail | Retry 3x, then suggest restart robot |
| PIN wrong | Retry 3x, then suggest kiểm tra màn hình robot |
| BLE write fail | Retry characteristic write, suggest restart |
| Server register fail | Check internet, suggest retry |
| Device not online after restart | Show troubleshoot: check WiFi password, server URL |
| Already paired device | Show warning, option to re-pair (overwrite token) |
| Admin auth fail | "Tài khoản không có quyền admin" — chỉ hiện admin panel khi role=admin |
| Command UNAUTHORIZED (0x02) | Level không đủ — cần auth lại |

### 3.6 Re-pairing / Factory Reset

```
User (Level 1):
  Device Settings → "Re-pair" → BLE pairing flow again (overwrite WiFi/token)
  Device Settings → "Restart" → BLE write COMMAND(0x01)

Admin (Level 2):
  Device Settings → "Quản lý nâng cao" → Admin BLE flow (§3.3)
  → Factory Reset (0x10): xóa WiFi + token, giữ firmware
  → Full Wipe (0x11): xóa toàn bộ NVS
  → Rollback FW (0x12): quay về firmware trước
  → Đổi server URL: write WS_URL mới
  → Đổi log level: write LOG_LEVEL

Kết quả sau reset:
  Factory Reset → device giữ server URL + name, cần re-pair WiFi + token + admin_secret
  Full Wipe → device hoàn toàn clean, cần setup toàn bộ như lần đầu
  Rollback FW → device reboot với firmware cũ, kết nối lại bình thường

Server-side sau reset:
  Device record vẫn tồn tại trong DB (không tự xóa)
  Re-pair cùng MAC + cùng owner → server update device_token (không tạo mới)
  Re-pair cùng MAC + khác owner → server reject 409 (admin phải DELETE device cũ trước)

From robot button:
  Long-press reset button 5s → device enters BLE_PROVISIONING
  → App can scan and re-pair
```

## 4. Screens & UX Flow

```
Splash
  │
  ├── No token → Login / Register
  │
  └── Has token → Home (Device List)
                     │
    ┌────────────────┼────────────────┬──────────┐
    │                │                │          │
  Device Detail    Stats          Settings   + Add Device
    │                                            │
    │                                       BLE Pairing Flow
    ├── Overview tab                    (6-step wizard)
    │     Status, battery, WiFi             │
    │     Quick controls                    Done → Device Detail
    │
    ├── Control tab
    │     Emotion picker (grid)
    │     Scene picker (grid)
    │     Volume / Brightness sliders
    │     [Reboot] [TTS] [Mute]
    │
    ├── Chat tab
    │     Message list (scrollable)
    │     Text input → POST /interact
    │     Robot response + emotion shown
    │     (Future: push-to-talk button)
    │
    ├── Logs tab
    │     Filter: level, tag, date
    │     Infinite scroll list
    │
    ├── Stats tab
    │     Charts: interactions/day, audio time
    │     Battery history, uptime
    │
    ├── OTA tab
    │     Current version, available update
    │     Download progress, changelog
    │
    └── Settings tab
          Name, location, timezone
          Log level (debug/info/warn/error)
          Auto-update toggle
          Share with users
          Re-pair (BLE Level 1)
          [Admin only] Quản lý nâng cao (BLE Level 2)
            → Diagnostics, đổi domain, factory reset,
              rollback FW, debug mode, clear users
```

## 5. Realtime via WebSocket

```dart
class DeviceWsClient {
  late WebSocketChannel channel;

  void connect(String deviceId, String token) {
    final url = '${AppConfig.wsUrl}/ws/app/$deviceId?token=$token';
    channel = WebSocketChannel.connect(Uri.parse(url));
    channel.stream.listen(_onMessage);
  }

  void _onMessage(dynamic data) {
    final msg = jsonDecode(data);
    switch (msg['type']) {
      case 'state_update':          // device state changed (relayed from device)
      case 'device_online':         // came online (server-generated)
      case 'device_offline':        // went offline (server-generated)
      case 'ota_progress':          // OTA update progress (relayed from device)
      case 'error':                 // device error (relayed from device)
      case 'battery':               // battery update (relayed from device)
      case 'interaction_result':    // LLM response to chat (server-generated)
    }
  }
}
```

## 6. State Management (Riverpod)

```dart
// Device list — auto-refresh khi có WS event
final deviceListProvider = AsyncNotifierProvider<DeviceListNotifier, List<Device>>(() {
  return DeviceListNotifier();
});

// Realtime device status via WebSocket
final deviceStatusProvider = StreamProvider.family<DeviceState, String>((ref, deviceId) {
  final ws = ref.watch(wsClientProvider);
  return ws.statusStream(deviceId);
});

// BLE pairing state machine
final pairingProvider = StateNotifierProvider<PairingNotifier, PairingState>((ref) {
  return PairingNotifier(ref);
});

// Chat / interaction history
final chatProvider = AsyncNotifierProvider.family<ChatNotifier, List<Interaction>, String>(() {
  return ChatNotifier();
});
```

## 7. Offline Mode

| Feature | Online | Offline |
|---------|--------|---------|
| Device list | Live from API | Cached in Hive |
| Device status | WebSocket realtime | Last known (stale indicator) |
| Send commands | Immediate | Queued, replay on reconnect |
| Chat | Live | Disabled (show message) |
| Logs | Live query | Cached last page |
| BLE pairing | Register on server | Partial (WiFi+BLE only, register later) |

## 8. Push Notifications (FCM)

```
Server → FCM → App notification khi:
  • Device offline > 5 phút
  • OTA available (new firmware)
  • Battery critical (< 10%)
  • Error severity = critical
  • Interaction response ready (nếu app ở background)

User preferences (per-device):
  • Enable/disable notifications
  • Choose which events to notify
  • Quiet hours
```

## 9. Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.0    # State management
  dio: ^5.0                 # HTTP client
  web_socket_channel: ^2.0  # WebSocket
  flutter_blue_plus: ^1.0   # BLE scanning + pairing
  hive_flutter: ^1.0        # Offline cache
  fl_chart: ^0.60           # Charts
  go_router: ^12.0          # Navigation
  firebase_messaging: ^14   # Push notifications
  permission_handler: ^11   # BLE + location permissions
  intl: ^0.18               # i18n
  lottie: ^2.0              # Animations (pairing flow)
  flutter_secure_storage: ^9 # JWT secure storage
```

## 10. Design System

### Color Palette (matching robot's 9-tone system)

```dart
class LuniColors {
  static const cyan   = Color(0xFF5BE9FF);  // Primary, default
  static const warm   = Color(0xFFFFD166);  // Happy, success
  static const rose   = Color(0xFFFF6B9D);  // Love, attention
  static const red    = Color(0xFFFF5B6E);  // Error, critical
  static const blue   = Color(0xFF76B8FF);  // Info, calm
  static const green  = Color(0xFF7BE88E);  // Online, charging
  static const purple = Color(0xFFB48CFF);  // Sleep, mischievous
  static const orange = Color(0xFFFF9D5B);  // Warning, curious
  static const white  = Color(0xFFF0F4FF);  // Background accent

  static const bgDark = Color(0xFF0A0E1A);  // Dark background
  static const bgCard = Color(0xFF141825);  // Card background
}
```

### Log Level Badges

| Level | Color | Badge |
|-------|-------|-------|
| DEBUG | purple | Outline |
| INFO | cyan | Filled |
| WARN | orange | Filled |
| ERROR | red | Filled, bold |
