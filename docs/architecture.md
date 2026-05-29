# Architecture

App Flutter dùng **Riverpod** (state), **Dio** (HTTP + JWT), **go_router** (điều hướng), **flutter_blue_plus** (BLE), **flutter_secure_storage** (token), **Hive** (cache offline), **firebase_messaging** (push).

## Cấu trúc thư mục (`lib/`)

```
main.dart                 Entry point
app.dart                  GoRouter + auth redirect guard
core/
  config/app_config.dart  API/WS base URLs (configurable build-time)
  config/theme.dart
  auth/auth_provider.dart  AuthController (login/register/logout/restore), AuthState
  network/api_client.dart  Dio client + JWT interceptor
  network/ws_client.dart    DeviceWsClient (reconnect, heartbeat)
  network/api_exceptions.dart
  bluetooth/ble_protocol.dart   GATT UUIDs + commands
  bluetooth/ble_scanner.dart / ble_connector.dart
  notifications/push_service.dart  FCM register + event stream
  storage/local_storage.dart       Hive cache
features/
  auth/      login, register, forgot-password
  home/      device list
  device/    detail, settings, sharing  (+ providers)
  pairing/   scan → connect → wifi → server → naming → done; admin-ble (+ providers)
  chat/ logs/ ota/ stats/ settings/
shared/
  models/    device, user, firmware, interaction, log_entry
  widgets/   app bar, loading, error state
```

## Networking config (`core/config/app_config.dart`)

Mặc định trỏ tới production, override được lúc build bằng `--dart-define`:

| Hằng | Env override | Default |
|------|--------------|---------|
| `apiBaseUrl` | `LUNI_API_BASE_URL` | `https://lunirobot.io.vn/api/v1` |
| `wsBaseUrl` | `LUNI_WS_BASE_URL` | `wss://lunirobot.io.vn` |
| `defaultDeviceWsUrl` | `LUNI_DEVICE_WS_URL` | `wss://lunirobot.io.vn/ws/device` |

`apiBaseUrl/wsBaseUrl` dùng cho App↔Cloud; `defaultDeviceWsUrl` được ghi vào robot qua BLE lúc pairing. Cách đổi khi dev local: xem [guides/BUILD_AND_RUN.md](guides/BUILD_AND_RUN.md).

## State management (Riverpod providers)

| Provider | Vai trò |
|----------|---------|
| `authControllerProvider` | Auth state + login/register/logout/restore session |
| `apiClientProvider` | Dio client, tự gắn `Authorization: Bearer` |
| `wsClientProvider` / `activeDeviceWsProvider(deviceId)` | WS client; family auto connect/disconnect theo màn device detail |
| `deviceListProvider` | Danh sách device + lắng nghe WS/FCM update |
| `deviceDetailProvider(deviceId)` | Lookup 1 device |
| `pushServiceProvider` | FCM token register + stream sự kiện |
| `pairingProvider` / `adminBleProvider` | State machine BLE pairing / admin |

## Auth & token lifecycle

1. `POST /auth/login` → `{ user, access_token, refresh_token }`.
2. Lưu token vào secure storage (Keystore/Keychain).
3. Khởi động: `tryRestoreSession()` đọc token → `GET /auth/me` verify → auto-login.
4. Token gắn vào REST (header) và WS app (`?token=`).

> Lưu ý: app hiện **chưa gọi `/auth/refresh`** — hết hạn access token thì đăng nhập lại. Endpoint refresh đã có ở server (xem Luni_Cloud auth module).

## Routing (`app.dart`)

GoRouter với redirect guard: chưa auth → `/login`; đã auth ở `/`|`/login` → `/home`.
Routes: `/login`, `/register`, `/forgot-password`, `/home`, `/pairing`, `/devices/:id`, `/devices/:id/sharing`, `/devices/:id/admin-ble`, `/settings`, `/profile`.

## Giao tiếp với robot

- **Qua Cloud** (chính): REST + WS app (`/ws/app/{id}`) + FCM. Xem [ws-protocol.md](ws-protocol.md), [hybrid-realtime.md](hybrid-realtime.md).
- **Trực tiếp BLE** (chỉ pairing 1 lần): cấu hình WiFi + ghi `device_token`/`admin_secret`. Xem [ble-pairing.md](ble-pairing.md).
