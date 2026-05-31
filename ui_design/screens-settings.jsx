/* ============================================================
   Settings — device settings, sharing, admin BLE, profile, app settings
   ============================================================ */

/* ---------------- Device Settings (hub tab) ---------------- */
function DeviceSettingsTab({ app, device, update }) {
  const d = device;
  const [share, setShare] = useS(false);
  const [admin, setAdmin] = useS(false);
  const [confirm, setConfirm] = useS(null);
  const [edit, setEdit] = useS(null);   // 'name' | 'loc' | 'tz' | 'ble'
  const lv = d.config.logLevel;
  const TZ = ['Asia/Ho_Chi_Minh (GMT+7)', 'Asia/Bangkok (GMT+7)', 'Asia/Singapore (GMT+8)', 'Asia/Tokyo (GMT+9)'];

  return (
    <Scroll style={{ padding: '14px 18px 30px' }}>
      <div className="card" style={{ display: 'flex', alignItems: 'center', gap: 14, padding: 16 }}>
        <LuniFace emotion={d.emotion} size={56} dim={!d.online} />
        <div style={{ flex: 1 }}>
          <div className="t-h3">{d.name}</div>
          <div className="mono" style={{ fontSize: 11.5, color: 'var(--tx-mute)', marginTop: 2 }}>{d.id}</div>
        </div>
        <StatusPill online={d.online} />
      </div>

      <Section>Thông tin</Section>
      <div className="card">
        <Row icon="edit" label="Tên robot" sub={d.name} onClick={() => setEdit('name')} />
        <Divider /><Row icon="location" label="Vị trí" sub={`${d.location} · ${d.city}`} onClick={() => setEdit('loc')} />
        <Divider /><Row icon="globe" label="Múi giờ" sub="Asia/Ho_Chi_Minh (GMT+7)" onClick={() => setEdit('tz')} />
      </div>

      <Section>Cấu hình</Section>
      <div className="card">
        <div style={{ padding: '14px 16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 13, marginBottom: 12 }}>
            <span style={{ width: 38, height: 38, borderRadius: 11, background: hexA('#7d91b9', .12), display: 'grid', placeItems: 'center' }}><Icon name="logs" size={19} color="var(--tx-soft)" /></span>
            <span style={{ fontSize: 15, fontWeight: 600 }}>Mức nhật ký</span>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            {['debug', 'info', 'warn', 'error'].map(l => (
              <button key={l} className="press" onClick={() => update({ config: { ...d.config, logLevel: l } })} style={{ flex: 1, height: 36, borderRadius: 10, fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.03em', background: lv === l ? 'var(--cyan)' : 'var(--bg-2)', color: lv === l ? '#06222b' : 'var(--tx-mute)', border: `1px solid ${lv === l ? 'transparent' : 'var(--hairline)'}` }}>{l}</button>
            ))}
          </div>
        </div>
        <Divider /><Row icon="download" label="Tự động cập nhật" sub="Cài firmware mới khi rảnh" right={<Toggle on={d.config.autoOta} onChange={v => update({ config: { ...d.config, autoOta: v } })} />} />
        <Divider /><Row icon="alert" label="Thông báo đẩy" sub="Offline, pin yếu, lỗi" right={<Toggle on={true} onChange={() => {}} />} />
      </div>

      <Section>Chia sẻ & quyền</Section>
      <div className="card">
        <Row icon="users" label="Chia sẻ robot" sub="2 người có quyền truy cập" onClick={() => setShare(true)} />
      </div>

      <Section>Bảo trì</Section>
      <div className="card">
        <Row icon="bluetooth" label="Ghép nối lại (BLE)" sub="Đổi Wi‑Fi hoặc máy chủ" onClick={() => setEdit('ble')} />
        <Divider /><Row icon="refresh" label="Khởi động lại robot" onClick={() => setConfirm({ title: 'Khởi động lại Luni?', body: 'Robot sẽ ngoại tuyến khoảng 20 giây.', cta: 'Khởi động lại', danger: false })} />
        <Divider /><Row icon="shield" iconColor="var(--purple)" label="Quản lý nâng cao" sub="Công cụ chẩn đoán BLE (Admin)" right={<><span className="pill" style={{ background: hexA('#B48CFF', .14), color: 'var(--purple)', height: 22, marginRight: 6 }}>Admin</span><Icon name="chevron" size={18} color="var(--tx-faint)" /></>} onClick={() => setAdmin(true)} />
      </div>

      <div style={{ marginTop: 22 }}>
        <button className="press" onClick={() => setConfirm({ title: 'Xoá robot này?', body: 'Luni sẽ bị gỡ khỏi tài khoản của bạn. Có thể ghép nối lại sau.', cta: 'Xoá robot', danger: true, onOk: app.goHome })} style={{ width: '100%', height: 52, borderRadius: 16, border: '1px solid ' + hexA('#FF5B6E', .3), color: 'var(--red)', fontWeight: 700, fontSize: 15, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <Icon name="trash" size={19} color="var(--red)" /> Xoá robot khỏi tài khoản
        </button>
      </div>

      <Sheet open={share} onClose={() => setShare(false)} title="Chia sẻ robot"><SharingPanel device={d} /></Sheet>
      <Sheet open={admin} onClose={() => setAdmin(false)} title="Quản trị nâng cao · BLE" height="92%"><AdminBleConsole device={d} update={update} confirm={setConfirm} /></Sheet>
      {confirm && <ConfirmDialog {...confirm} onClose={() => setConfirm(null)} />}
    </Scroll>
  );
}

function Divider() { return <div style={{ height: 1, background: 'var(--hairline)', margin: '0 16px' }} />; }

function ConfirmDialog({ title, body, cta, danger, onOk, onClose }) {
  return (
    <div onClick={onClose} style={{ position: 'absolute', inset: 0, zIndex: 60, display: 'grid', placeItems: 'center', padding: 26 }}>
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(3,5,10,.7)' }} />
      <div onClick={e => e.stopPropagation()} className="card pop" style={{ position: 'relative', width: '100%', padding: 22, background: 'var(--bg-1)' }}>
        <div className="t-h3" style={{ marginBottom: 6 }}>{title}</div>
        <p className="t-body" style={{ color: 'var(--tx-mute)', margin: '0 0 20px' }}>{body}</p>
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="cta-ghost" onClick={onClose} style={{ height: 48 }}>Huỷ</button>
          <button className="press" onClick={() => { onOk && onOk(); onClose(); }} style={{ flex: 1, height: 48, borderRadius: 16, fontWeight: 700, fontSize: 15, background: danger ? 'var(--red)' : 'var(--cyan)', color: danger ? '#fff' : '#06222b' }}>{cta}</button>
        </div>
      </div>
    </div>
  );
}

/* ---------------- Sharing ---------------- */
const SHARED = [
  { name: 'Test User', email: 'test@example.com', role: 'Chủ sở hữu', owner: true, em: 'happy' },
  { name: 'Minh Anh', email: 'minhanh@vidu.com', role: 'Điều khiển', em: 'love' },
];
function SharingPanel({ device }) {
  const [people, setPeople] = useS(SHARED);
  const [email, setEmail] = useS('');
  const [qr, setQr] = useS(false);
  const invite = () => { if (!email.trim()) return; setPeople(p => [...p, { name: email.split('@')[0], email, role: 'Xem', em: 'curious' }]); setEmail(''); luniToast('Đã gửi lời mời'); };
  return (
    <div>
      <div style={{ display: 'flex', gap: 10, marginBottom: 18 }}>
        <input className="field" value={email} onChange={e => setEmail(e.target.value)} placeholder="Mời qua email…" style={{ height: 50 }} />
        <button className="press" onClick={invite} style={{ width: 50, height: 50, borderRadius: 14, background: 'var(--cyan)', display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="plus" size={22} color="#06222b" strokeWidth={2.2} /></button>
      </div>
      <button className="press" onClick={() => setQr(true)} style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, padding: 14, borderRadius: 14, border: '1.5px dashed var(--hairline-2)', color: 'var(--tx-soft)', fontWeight: 600, marginBottom: 18 }}><Icon name="qr" size={20} color="var(--cyan)" /> Chia sẻ bằng mã QR</button>
      <div className="t-cap" style={{ margin: '0 2px 10px' }}>NGƯỜI CÓ QUYỀN ({people.length})</div>
      <div style={{ display: 'grid', gap: 8 }}>
        {people.map((p, i) => (
          <div key={i} className="card-2" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 12 }}>
            <span style={{ width: 40, height: 40, borderRadius: '50%', background: hexA(LUNI_EMOTIONS[p.em].color, .16), display: 'grid', placeItems: 'center', color: LUNI_EMOTIONS[p.em].color, fontWeight: 800, flex: 'none' }}>{p.name[0].toUpperCase()}</span>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 600, fontSize: 14.5 }}>{p.name}</div>
              <div style={{ fontSize: 12, color: 'var(--tx-mute)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.email}</div>
            </div>
            <span className="pill" style={{ background: p.owner ? hexA('#5BE9FF', .14) : 'var(--bg-3)', color: p.owner ? 'var(--cyan)' : 'var(--tx-mute)' }}>{p.role}</span>
          </div>
        ))}
      </div>

      <Sheet open={qr} onClose={() => setQr(false)} title="Chia sẻ bằng mã QR">
        <p style={{ fontSize: 12.5, color: 'var(--tx-mute)', margin: '0 0 16px', lineHeight: 1.45 }}>Cho người khác quét mã này trong ứng dụng Luni để nhận quyền điều khiển <b style={{ color: 'var(--tx-soft)' }}>{device.name}</b>.</p>
        <div style={{ display: 'grid', placeItems: 'center' }}>
          <div style={{ padding: 16, borderRadius: 20, background: '#fff' }}><QRPlaceholder seed={device.id} /></div>
          <div className="mono" style={{ fontSize: 11.5, color: 'var(--tx-faint)', marginTop: 14, letterSpacing: '.06em' }}>LUNI-{device.id.replace(/:/g, '').slice(-6)}</div>
        </div>
        <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
          <button className="cta-ghost" onClick={() => { luniToast('Đã sao chép liên kết'); }} style={{ height: 50 }}><Icon name="logs" size={18} /> Sao chép liên kết</button>
          <button className="press" onClick={() => { luniToast('Mã QR sẽ hết hạn sau 24 giờ', { icon: 'info', color: 'var(--cyan)' }); }} style={{ flex: 1, height: 50, borderRadius: 16, fontWeight: 700, fontSize: 15, background: 'var(--cyan)', color: '#06222b', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}><Icon name="qr" size={18} color="#06222b" /> Mã mới</button>
        </div>
      </Sheet>
    </div>
  );
}

/* deterministic QR-style placeholder (decorative squares, not a real code) */
function QRPlaceholder({ seed = '', size = 180 }) {
  const n = 21;
  let h = 0; for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  const rng = () => { h = (h * 1103515245 + 12345) & 0x7fffffff; return h / 0x7fffffff; };
  const cell = size / n;
  const finder = (x, y) => (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
  const cells = [];
  for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
    if (finder(x, y)) continue;
    if (rng() > 0.52) cells.push([x, y]);
  }
  const Finder = ({ x, y }) => (
    <>
      <rect x={x * cell} y={y * cell} width={cell * 7} height={cell * 7} fill="#0b0e16" />
      <rect x={(x + 1) * cell} y={(y + 1) * cell} width={cell * 5} height={cell * 5} fill="#fff" />
      <rect x={(x + 2) * cell} y={(y + 2) * cell} width={cell * 3} height={cell * 3} fill="#0b0e16" />
    </>
  );
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} shapeRendering="crispEdges">
      {cells.map(([x, y], i) => <rect key={i} x={x * cell} y={y * cell} width={cell} height={cell} fill="#0b0e16" />)}
      <Finder x={0} y={0} /><Finder x={n - 7} y={0} /><Finder x={0} y={n - 7} />
    </svg>
  );
}

/* ---------------- Sheet form helpers ---------------- */
function FieldLabel({ children, style }) {
  return <div className="t-cap" style={{ margin: '0 2px 7px', ...style }}>{children}</div>;
}
function SheetActions({ onClose, onSave, save = 'Lưu', danger }) {
  return (
    <div style={{ display: 'flex', gap: 10, marginTop: 22 }}>
      <button className="cta-ghost" onClick={onClose} style={{ height: 50 }}>Huỷ</button>
      <button className="press" onClick={onSave} style={{ flex: 1, height: 50, borderRadius: 16, fontWeight: 700, fontSize: 15, background: danger ? 'var(--red)' : 'var(--cyan)', color: danger ? '#fff' : '#06222b' }}>{save}</button>
    </div>
  );
}

/* ---------------- Profile ---------------- */
function ProfileScreen({ app }) {
  const [sheet, setSheet] = useS(null);   // avatar | edit | password | security
  const [profile, setProfile] = useS({ name: 'Test User', email: 'test@example.com', phone: '0912 345 678' });

  return (
    <>
      <TopBar title="Hồ sơ" onBack={app.goHome} />
      <Scroll style={{ padding: '8px 18px 28px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '14px 0 8px' }}>
          <button className="press" onClick={() => setSheet('avatar')} style={{ position: 'relative', background: 'transparent' }}>
            <span style={{ width: 96, height: 96, borderRadius: '50%', background: 'linear-gradient(140deg,#5BE9FF,#76B8FF)', display: 'grid', placeItems: 'center', fontSize: 38, fontWeight: 800, color: '#06222b' }}>{profile.name[0].toUpperCase()}</span>
            <span style={{ position: 'absolute', right: -2, bottom: -2, width: 34, height: 34, borderRadius: '50%', background: 'var(--bg-2)', border: '2px solid var(--bg-base)', display: 'grid', placeItems: 'center' }}><Icon name="edit" size={15} color="var(--cyan)" /></span>
          </button>
          <div className="t-h2" style={{ marginTop: 14 }}>{profile.name}</div>
          <div className="t-sub">{profile.email}</div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, margin: '20px 0' }}>
          <MiniStat icon="cpu" color="var(--cyan)" big="2" label="Robot" />
          <MiniStat icon="chat" color="var(--rose)" big="129" label="Tương tác" />
          <MiniStat icon="clock" color="var(--green)" big="42" label="Ngày" />
        </div>
        <Section>Tài khoản</Section>
        <div className="card">
          <Row icon="user" label="Chỉnh sửa hồ sơ" sub={profile.name} onClick={() => setSheet('edit')} />
          <Divider /><Row icon="lock" label="Đổi mật khẩu" onClick={() => setSheet('password')} />
          <Divider /><Row icon="shield" label="Bảo mật & quyền riêng tư" onClick={() => setSheet('security')} />
        </div>
        <button className="press" onClick={() => app.logout()} style={{ width: '100%', marginTop: 22, height: 52, borderRadius: 16, border: '1px solid ' + hexA('#FF5B6E', .3), color: 'var(--red)', fontWeight: 700, fontSize: 15, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}><Icon name="power" size={19} color="var(--red)" /> Đăng xuất</button>
      </Scroll>

      {/* avatar */}
      <Sheet open={sheet === 'avatar'} onClose={() => setSheet(null)} title="Ảnh đại diện">
        <div style={{ display: 'grid', gap: 2 }}>
          <Row icon="user" label="Chụp ảnh mới" onClick={() => { setSheet(null); luniToast('Đang mở máy ảnh…', { icon: 'user', color: 'var(--cyan)' }); }} />
          <Divider /><Row icon="grid" label="Chọn từ thư viện" onClick={() => { setSheet(null); luniToast('Đang mở thư viện ảnh…', { icon: 'grid', color: 'var(--cyan)' }); }} />
          <Divider /><Row icon="trash" danger label="Xoá ảnh hiện tại" onClick={() => { setSheet(null); luniToast('Đã xoá ảnh đại diện', { icon: 'trash', color: 'var(--red)' }); }} />
        </div>
      </Sheet>

      {/* edit profile */}
      <Sheet open={sheet === 'edit'} onClose={() => setSheet(null)} title="Chỉnh sửa hồ sơ">
        <EditProfileForm profile={profile} onCancel={() => setSheet(null)} onSave={(p) => { setProfile(p); setSheet(null); luniToast('Đã lưu hồ sơ'); }} />
      </Sheet>

      {/* password */}
      <Sheet open={sheet === 'password'} onClose={() => setSheet(null)} title="Đổi mật khẩu">
        <PasswordForm onCancel={() => setSheet(null)} onSave={() => { setSheet(null); luniToast('Đã cập nhật mật khẩu'); }} />
      </Sheet>

      {/* security */}
      <Sheet open={sheet === 'security'} onClose={() => setSheet(null)} title="Bảo mật & quyền riêng tư">
        <SecurityPanel />
      </Sheet>
    </>
  );
}

function EditProfileForm({ profile, onCancel, onSave }) {
  const [f, setF] = useS(profile);
  const set = (k) => (e) => setF(s => ({ ...s, [k]: e.target.value }));
  return (
    <div>
      <FieldLabel>TÊN HIỂN THỊ</FieldLabel>
      <input className="field" value={f.name} onChange={set('name')} style={{ height: 52, marginBottom: 16 }} />
      <FieldLabel>EMAIL</FieldLabel>
      <input className="field" value={f.email} onChange={set('email')} type="email" style={{ height: 52, marginBottom: 16 }} />
      <FieldLabel>SỐ ĐIỆN THOẠI</FieldLabel>
      <input className="field" value={f.phone} onChange={set('phone')} style={{ height: 52 }} />
      <SheetActions onClose={onCancel} onSave={() => onSave(f)} />
    </div>
  );
}

function PasswordForm({ onCancel, onSave }) {
  const [cur, setCur] = useS('');
  const [nw, setNw] = useS('');
  const [cf, setCf] = useS('');
  const ok = cur && nw.length >= 6 && nw === cf;
  const mismatch = cf && nw !== cf;
  return (
    <div>
      <FieldLabel>MẬT KHẨU HIỆN TẠI</FieldLabel>
      <input className="field" type="password" value={cur} onChange={e => setCur(e.target.value)} placeholder="••••••••" style={{ height: 52, marginBottom: 16 }} />
      <FieldLabel>MẬT KHẨU MỚI</FieldLabel>
      <input className="field" type="password" value={nw} onChange={e => setNw(e.target.value)} placeholder="Tối thiểu 6 ký tự" style={{ height: 52, marginBottom: 16 }} />
      <FieldLabel>XÁC NHẬN MẬT KHẨU MỚI</FieldLabel>
      <input className="field" type="password" value={cf} onChange={e => setCf(e.target.value)} placeholder="Nhập lại mật khẩu mới" style={{ height: 52, borderColor: mismatch ? hexA('#FF5B6E', .6) : undefined }} />
      {mismatch && <div style={{ fontSize: 12, color: 'var(--red)', margin: '8px 2px 0', display: 'flex', alignItems: 'center', gap: 6 }}><Icon name="alert" size={13} color="var(--red)" /> Mật khẩu xác nhận chưa khớp.</div>}
      <div style={{ display: 'flex', gap: 10, marginTop: 22 }}>
        <button className="cta-ghost" onClick={onCancel} style={{ height: 50 }}>Huỷ</button>
        <button className="press" disabled={!ok} onClick={onSave} style={{ flex: 1, height: 50, borderRadius: 16, fontWeight: 700, fontSize: 15, background: ok ? 'var(--cyan)' : 'var(--bg-3)', color: ok ? '#06222b' : 'var(--tx-faint)' }}>Cập nhật</button>
      </div>
    </div>
  );
}

function SecurityPanel() {
  const [tfa, setTfa] = useS(false);
  const [bio, setBio] = useS(true);
  const [diag, setDiag] = useS(true);
  return (
    <div>
      <div className="card" style={{ marginBottom: 14 }}>
        <Row icon="lock" iconColor="var(--cyan)" label="Xác thực 2 bước" sub="Mã OTP khi đăng nhập thiết bị mới" right={<Toggle on={tfa} onChange={(v) => { setTfa(v); luniToast(v ? 'Đã bật 2FA' : 'Đã tắt 2FA'); }} />} />
        <Divider /><Row icon="user" iconColor="var(--cyan)" label="Đăng nhập sinh trắc học" sub="Face ID / vân tay" right={<Toggle on={bio} onChange={setBio} />} />
        <Divider /><Row icon="chart" iconColor="var(--cyan)" label="Chia sẻ dữ liệu chẩn đoán" sub="Giúp cải thiện Luni" right={<Toggle on={diag} onChange={setDiag} />} />
      </div>
      <div className="t-cap" style={{ margin: '0 2px 10px' }}>QUYỀN RIÊNG TƯ</div>
      <div className="card">
        <Row icon="download" label="Tải dữ liệu của tôi" sub="Xuất bản sao hội thoại & cài đặt" onClick={() => luniToast('Đang chuẩn bị bản xuất…', { icon: 'download', color: 'var(--cyan)' })} />
        <Divider /><Row icon="trash" danger label="Xoá tài khoản" sub="Gỡ vĩnh viễn mọi dữ liệu" onClick={() => luniToast('Đã gửi yêu cầu xoá tài khoản', { icon: 'trash', color: 'var(--red)' })} />
      </div>
    </div>
  );
}

/* ---------------- App Settings ---------------- */
function AppSettingsScreen({ app }) {
  const [lang, setLang] = useS('vi');
  const [dark, setDark] = useS(true);
  const [notif, setNotif] = useS(true);
  const [sheet, setSheet] = useS(null);     // quiet | about | terms | support
  const [quiet, setQuiet] = useS({ on: true, start: 22, end: 7 });
  return (
    <>
      <TopBar title="Cài đặt ứng dụng" onBack={app.goHome} />
      <Scroll style={{ padding: '8px 18px 28px' }}>
        <Section>Giao diện</Section>
        <div className="card">
          <Row icon="moon" label="Chế độ tối" right={<Toggle on={dark} onChange={setDark} />} />
          <Divider />
          <div style={{ padding: '14px 16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 13, marginBottom: 12 }}><span style={{ width: 38, height: 38, borderRadius: 11, background: hexA('#7d91b9', .12), display: 'grid', placeItems: 'center' }}><Icon name="globe" size={19} color="var(--tx-soft)" /></span><span style={{ fontSize: 15, fontWeight: 600 }}>Ngôn ngữ</span></div>
            <div style={{ display: 'flex', gap: 8 }}>
              {[['vi', 'Tiếng Việt'], ['en', 'English']].map(([id, l]) => <button key={id} className="press" onClick={() => setLang(id)} style={{ flex: 1, height: 42, borderRadius: 12, fontWeight: 700, fontSize: 14, background: lang === id ? 'var(--cyan)' : 'var(--bg-2)', color: lang === id ? '#06222b' : 'var(--tx-mute)', border: `1px solid ${lang === id ? 'transparent' : 'var(--hairline)'}` }}>{l}</button>)}
            </div>
          </div>
        </div>
        <Section>Thông báo</Section>
        <div className="card">
          <Row icon="alert" label="Thông báo đẩy" sub="Offline, pin yếu, OTA, lỗi" right={<Toggle on={notif} onChange={setNotif} />} />
          <Divider /><Row icon="moon" label="Giờ yên tĩnh" sub={quiet.on ? `${hh(quiet.start)} – ${hh(quiet.end)}` : 'Đang tắt'} onClick={() => setSheet('quiet')} />
        </div>
        <Section>Khác</Section>
        <div className="card">
          <Row icon="info" label="Về Luni" sub="Ứng dụng v1.0.0 · build 124" onClick={() => setSheet('about')} />
          <Divider /><Row icon="shield" label="Điều khoản & quyền riêng tư" onClick={() => setSheet('terms')} />
          <Divider /><Row icon="chat" label="Hỗ trợ" onClick={() => setSheet('support')} />
        </div>
        <button className="press" onClick={() => app.logout()} style={{ width: '100%', marginTop: 22, height: 52, borderRadius: 16, border: '1px solid ' + hexA('#FF5B6E', .3), color: 'var(--red)', fontWeight: 700, fontSize: 15, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}><Icon name="power" size={19} color="var(--red)" /> Đăng xuất</button>
      </Scroll>

      {/* quiet hours */}
      <Sheet open={sheet === 'quiet'} onClose={() => setSheet(null)} title="Giờ yên tĩnh">
        <p style={{ fontSize: 12.5, color: 'var(--tx-mute)', margin: '0 0 16px', lineHeight: 1.45 }}>Trong khung giờ này Luni sẽ giảm đèn, tắt âm báo và không gửi thông báo đẩy.</p>
        <div className="card" style={{ padding: '4px 16px', marginBottom: 16 }}>
          <Row icon="moon" iconColor="var(--cyan)" label="Bật giờ yên tĩnh" right={<Toggle on={quiet.on} onChange={v => setQuiet(q => ({ ...q, on: v }))} />} />
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, opacity: quiet.on ? 1 : .4, pointerEvents: quiet.on ? 'auto' : 'none' }}>
          <TimeStepper label="BẮT ĐẦU" value={quiet.start} onChange={v => setQuiet(q => ({ ...q, start: v }))} />
          <TimeStepper label="KẾT THÚC" value={quiet.end} onChange={v => setQuiet(q => ({ ...q, end: v }))} />
        </div>
        <button className="cta" onClick={() => { setSheet(null); luniToast('Đã lưu giờ yên tĩnh'); }} style={{ marginTop: 20 }}>Lưu</button>
      </Sheet>

      {/* about */}
      <Sheet open={sheet === 'about'} onClose={() => setSheet(null)} title="Về Luni">
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '4px 0 6px' }}>
          <LuniFace emotion="happy" size={92} />
          <div className="t-h2" style={{ marginTop: 14 }}>Luni</div>
          <div className="t-sub">Người bạn robot cảm xúc</div>
          <div className="mono" style={{ fontSize: 12, color: 'var(--tx-faint)', marginTop: 6 }}>Ứng dụng v1.0.0 · build 124</div>
        </div>
        <div className="card" style={{ marginTop: 18 }}>
          <Row icon="cpu" label="Firmware tương thích" right={<span className="mono" style={{ fontSize: 13, color: 'var(--tx-mute)' }}>≥ 2.0.0</span>} />
          <Divider /><Row icon="globe" label="Trang chủ" sub="luni.vn" onClick={() => luniToast('Đang mở luni.vn…', { icon: 'globe', color: 'var(--cyan)' })} />
          <Divider /><Row icon="sparkle" label="Có gì mới" sub="Nhật ký phiên bản" onClick={() => luniToast('Đang tải nhật ký phiên bản…', { icon: 'sparkle', color: 'var(--warm)' })} />
        </div>
        <p style={{ textAlign: 'center', fontSize: 11.5, color: 'var(--tx-faint)', margin: '18px 0 2px', lineHeight: 1.5 }}>© 2026 Luni Robotics. Made with ♥ in Việt Nam.</p>
      </Sheet>

      {/* terms */}
      <Sheet open={sheet === 'terms'} onClose={() => setSheet(null)} title="Điều khoản & quyền riêng tư" height="86%">
        <div style={{ fontSize: 13.5, lineHeight: 1.6, color: 'var(--tx-soft)' }}>
          {TERMS.map((s, i) => (
            <div key={i} style={{ marginBottom: 18 }}>
              <div className="t-h3" style={{ marginBottom: 6 }}>{s.h}</div>
              <p style={{ margin: 0, color: 'var(--tx-mute)' }}>{s.b}</p>
            </div>
          ))}
          <div className="mono" style={{ fontSize: 11, color: 'var(--tx-faint)', marginTop: 4 }}>Cập nhật lần cuối: 01/03/2026</div>
        </div>
        <button className="cta" onClick={() => { setSheet(null); luniToast('Đã xác nhận đã đọc'); }} style={{ marginTop: 18 }}>Tôi đã đọc</button>
      </Sheet>

      {/* support */}
      <Sheet open={sheet === 'support'} onClose={() => setSheet(null)} title="Hỗ trợ">
        <div className="card" style={{ marginBottom: 14 }}>
          <Row icon="chat" iconColor="var(--cyan)" label="Trò chuyện với hỗ trợ" sub="Phản hồi trong ~5 phút" onClick={() => { setSheet(null); luniToast('Đang kết nối hỗ trợ…', { icon: 'chat', color: 'var(--cyan)' }); }} />
          <Divider /><Row icon="info" iconColor="var(--cyan)" label="Câu hỏi thường gặp" sub="Ghép nối, Wi‑Fi, pin, OTA" onClick={() => { setSheet(null); luniToast('Đang mở trung tâm trợ giúp…', { icon: 'info', color: 'var(--cyan)' }); }} />
          <Divider /><Row icon="alert" iconColor="var(--orange)" label="Báo lỗi" sub="Gửi nhật ký chẩn đoán" onClick={() => { setSheet(null); luniToast('Đã gửi báo cáo lỗi', { icon: 'check', color: 'var(--green)' }); }} />
        </div>
        <div className="t-cap" style={{ margin: '0 2px 10px' }}>LIÊN HỆ</div>
        <div className="card-2" style={{ padding: 14, display: 'grid', gap: 8 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13.5 }}><Icon name="chat" size={16} color="var(--tx-faint)" /> hotro@luni.vn</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13.5 }}><Icon name="speaker" size={16} color="var(--tx-faint)" /> 1900 1234 (8:00–22:00)</div>
        </div>
      </Sheet>
    </>
  );
}

function hh(n) { return String(((n % 24) + 24) % 24).padStart(2, '0') + ':00'; }

function TimeStepper({ label, value, onChange }) {
  const step = (d) => onChange((((value + d) % 24) + 24) % 24);
  return (
    <div className="card" style={{ padding: '14px 12px', textAlign: 'center' }}>
      <FieldLabel style={{ textAlign: 'center', margin: '0 0 10px' }}>{label}</FieldLabel>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button className="press" onClick={() => step(-1)} style={{ width: 36, height: 36, borderRadius: 11, background: 'var(--bg-2)', border: '1px solid var(--hairline)', display: 'grid', placeItems: 'center' }}><Icon name="chevron" size={18} color="var(--tx-soft)" style={{ transform: 'rotate(180deg)' }} /></button>
        <span className="mono" style={{ fontSize: 22, fontWeight: 800, fontVariantNumeric: 'tabular-nums', color: 'var(--cyan)' }}>{hh(value)}</span>
        <button className="press" onClick={() => step(1)} style={{ width: 36, height: 36, borderRadius: 11, background: 'var(--bg-2)', border: '1px solid var(--hairline)', display: 'grid', placeItems: 'center' }}><Icon name="chevron" size={18} color="var(--tx-soft)" /></button>
      </div>
    </div>
  );
}

const TERMS = [
  { h: '1. Thu thập dữ liệu', b: 'Luni xử lý giọng nói và câu hỏi của bạn để phản hồi. Bản ghi hội thoại được lưu tối đa 30 ngày trên máy chủ rồi tự xoá. Bạn có thể tải về hoặc xoá sớm bất cứ lúc nào trong mục Bảo mật.' },
  { h: '2. Quyền riêng tư trẻ em', b: 'Khi bật chế độ trẻ em, Luni không lưu nội dung nhạy cảm và lọc kết quả theo độ tuổi. Phụ huynh quản lý toàn bộ dữ liệu của con qua tài khoản chính.' },
  { h: '3. Kết nối thiết bị', b: 'Robot giao tiếp với máy chủ qua kết nối mã hoá. Thông tin Wi‑Fi cấu hình qua Bluetooth chỉ lưu cục bộ trên robot, không gửi lên máy chủ.' },
  { h: '4. Chia sẻ & quyền', b: 'Bạn có thể mời người khác điều khiển robot. Chủ sở hữu có thể thu hồi quyền bất cứ lúc nào. Mọi thao tác điều khiển đều được ghi nhật ký.' },
];

Object.assign(window, { DeviceSettingsTab, SharingPanel, ProfileScreen, AppSettingsScreen, ConfirmDialog, Divider });
