# Luni — Ứng dụng di động (Prototype)

Luni là người bạn robot cảm xúc để bàn — một quả cầu phát sáng với đôi
mắt biểu cảm "chính là mặt trăng", thay đổi theo chu kỳ trăng. **Đây là
prototype ứng dụng di động** đi kèm robot: ghép nối qua Bluetooth, điều
khiển biểu cảm, trò chuyện, xem thống kê, cập nhật firmware và — cho kỹ
thuật viên — một bảng dịch vụ quản lý cả đội robot.

> Tìm phần *hiển thị* của robot (mắt, cảnh, bảng cảm xúc 320×240)? Xem
> thư mục **`LuniRobot/`** và `LuniRobot/REQUIREMENTS.md`. Repo này là
> **app điều khiển**, không phải firmware.

---

## Mở lên xem

Mở **`Luni App.html`** trong trình duyệt. **Không cần build** — trang tải
React 18 + Babel từ CDN rồi transpile các file `.jsx` ngay tại chỗ.

Bạn sẽ thấy một khung điện thoại Android ở giữa, cạnh đó là bảng điều
hướng nhanh (chỉ là chrome của prototype, không nằm trong sản phẩm) để
nhảy giữa các luồng. Dưới bảng đó là **panel Dev chỉnh ngày** — kéo để
"tua" cả app qua các đêm trong tháng âm lịch và xem Luni đổi tướng.

Trang thứ hai, **`App Icon.html`** (mở từ nút *App Icon →*), là phần khám
phá thương hiệu / biểu tượng ứng dụng theo pha trăng.

---

## Hai vai trò — quyết định bởi email đăng nhập

Màn hình đăng nhập suy ra vai trò từ email rồi rẽ luồng:

| Tài khoản demo    | Email             | Mật khẩu  | Vào đâu |
| ----------------- | ----------------- | --------- | ------- |
| **Người dùng**    | `test@example.com`| `luni2026`| App quản lý robot cá nhân |
| **Admin / kỹ thuật** | `admin@luni.vn`| `luni2026`| Bảng dịch vụ cả đội (Luni Service) |

Email chứa `admin`, `service`, `kythuat` hay tên miền `@luni.*` → vào
luồng Admin (tông tím). Còn lại → luồng người dùng (tông cyan).

---

## Các luồng chính

**Người dùng**

- **Đăng nhập / Đăng ký / Quên mật khẩu** — `screens-auth.jsx`
- **Trang chủ** — danh sách robot, trạng thái trực tuyến, pin, cảm xúc — `screens-home.jsx`
- **Ghép nối (BLE)** — trình hướng dẫn 7 bước: quét → kết nối → PIN →
  Wi‑Fi → máy chủ → đặt tên → nạp cấu hình → xong — `screens-pairing.jsx`
- **Bảng điều khiển thiết bị** (Hub) với các tab — `screens-hub.jsx`:
  - **Tổng quan** — hero cảm xúc, thẻ Tuần trăng, pin/sóng/firmware/vị trí, hoạt động gần đây
  - **Điều khiển** — ghi đè cảm xúc (47 biểu cảm, 12 trạng thái firmware), cảnh hiển thị, cho Luni đọc (TTS), âm lượng & độ sáng, thao tác nhanh — `screens-control.jsx`
  - **Trò chuyện** — lịch sử hội thoại thoại + chữ, tìm kiếm — `screens-data.jsx`
  - **Thống kê** — tương tác/tuần, lịch sử pin, phân bố cảm xúc — `screens-data.jsx`
  - **Cập nhật** — OTA firmware (tải → cài → khởi động lại) — `screens-data.jsx`
  - **Cài đặt** — thông tin, cấu hình, chia sẻ & quyền, console BLE nâng cao — `screens-settings.jsx`
- **Hồ sơ & Cài đặt ứng dụng** — avatar, đổi mật khẩu, bảo mật/2FA, ngôn ngữ, giờ yên tĩnh, hỗ trợ — `screens-settings.jsx`

**Admin / kỹ thuật** — `screens-admin-dash.jsx`

- **Đội robot** — tổng quan, lọc (cần xử lý / ngoại tuyến / đang cập nhật), tìm theo tên · MAC · chủ sở hữu
- **Console dịch vụ từng robot** (kết nối BLE giả lập, phiên Admin Level 2):
  **Chẩn đoán** (`CHR_DIAG_INFO`: heap, uptime, RSSI, reset reason…) ·
  **Cấu hình** (Wi‑Fi, WS URL, gán tài khoản) ·
  **Nhật ký** (mức log + tail realtime) ·
  **Firmware** (nạp OTA / rollback) ·
  **Reset** — vùng nguy hiểm, ghi `CHR_COMMAND`.

---

## Luni *chính là* mặt trăng — engine âm lịch

Điểm đặc trưng của sản phẩm. `luni-moon.jsx` tính pha trăng theo tháng
giao hội (~29,53 ngày) và cả app "thở" theo đó:

- Quả cầu mặt (`LuniFace`) khoác bóng pha trăng đêm nay; quầng sáng rực
  ở Rằm, mờ dịu ở Mùng Một.
- **Ngày đặc biệt tự đổi tướng**: đêm **Rằm** Luni *phấn khích* (vàng
  kim), **Mùng Một** *buồn ngủ* (tím) — không cần lệnh.
- Thẻ **Tuần trăng** ở Tổng quan và glyph mặt trăng ở khắp nơi đều tự
  vẽ lại theo ngày âm lịch (`MoonGlyph`, bộ 30 ngày `LunarMonthGrid`).
- **Panel Dev chỉnh ngày** (ngoài khung điện thoại) tua toàn app qua cả
  tháng để kiểm thử; offset lưu ở `localStorage` (`luni_day_offset`).

---

## Hệ thiết kế

| | |
| --- | --- |
| **Font** | `Be Vietnam Pro` (chữ) · `Space Mono` (số/kỹ thuật) |
| **Nền** | tối, xanh đen — `#090C15` → card `#11151F` |
| **Brand** | cyan `#5BE9FF` (người dùng) · tím `#B48CFF` (admin) |
| **Bảng cảm xúc 9 tông** | warm `#FFD166` · rose `#FF6B9D` · red `#FF5B6E` · blue `#76B8FF` · green `#7BE88E` · orange `#FF9D5B` |

Tokens, lớp type và thư viện animation nằm trong `luni-styles.css`. Quy
tắc màu kế thừa từ robot: **mặt (mắt) luôn cyan**, tông cảm xúc chỉ tô
quầng sáng và phụ kiện.

Toàn bộ giao diện bằng **tiếng Việt**.

---

## Bản đồ file (thứ tự nạp)

```
Luni App.html         điểm vào — nạp CSS + React/Babel + mọi file .jsx
luni-styles.css       design tokens, base, thư viện animation
luni-face.jsx         LuniFace — quả cầu mặt + LUNI_EMOTIONS + hexA()
luni-icons.jsx        bộ icon nét (stroke)
luni-moon.jsx         engine âm lịch + glyph mặt trăng theo pha
luni-ui.jsx           khung điện thoại, status bar, primitives dùng chung
screens-auth.jsx      đăng nhập / đăng ký / quên mật khẩu (+ useS, Spinner)
screens-home.jsx      danh sách robot, empty state
screens-pairing.jsx   trình ghép nối BLE 7 bước
screens-control.jsx   tab Điều khiển (cảm xúc, cảnh, TTS, slider)
screens-data.jsx      tab Trò chuyện · Thống kê · OTA
screens-admin.jsx     console BLE nâng cao (trong Cài đặt thiết bị)
screens-hub.jsx       vỏ Hub + tab strip + Tổng quan
screens-settings.jsx  cài đặt thiết bị, chia sẻ, hồ sơ, cài đặt app
screens-admin-dash.jsx  bảng dịch vụ Admin (đội robot + console kỹ thuật)
luni-app.jsx          router gốc + state + điều hướng prototype
App Icon.html         trang khám phá biểu tượng ứng dụng theo pha trăng
```

**Thứ tự quan trọng.** Mỗi file `.jsx` có scope riêng khi Babel transpile,
nên các component được gắn vào `window` ở cuối file (`Object.assign(window, …)`)
để file sau dùng được. `luni-face.jsx`, `luni-icons.jsx`, `luni-moon.jsx`
và `luni-ui.jsx` phải nạp trước các màn hình; `luni-app.jsx` nạp cuối cùng
vì nó render toàn bộ.

---

## Lưu ý cho người sửa

- **Không có backend** — mọi dữ liệu là seed trong `luni-app.jsx`
  (`SEED_DEVICES`) và các file màn hình. Các lệnh "gửi tới robot" chỉ hiện
  toast; OTA/ghép nối chạy bằng timer giả lập.
- Thuật ngữ firmware trong app (`CHR_*`, `WS set_emotion`, `EmotionCore`,
  `StateManager`) khớp với thư viện thật ở **`LuniRobot/`** — giữ nhất quán
  khi thêm tính năng.
- Viết JSX chuẩn: đặt tên object style riêng cho từng component (đừng dùng
  `const styles = …` chung), đóng thẻ đầy đủ, không dùng `type="module"`.
