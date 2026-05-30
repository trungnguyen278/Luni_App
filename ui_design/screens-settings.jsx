/* ============================================================
   Settings — device settings, sharing, admin BLE, profile, app settings
   ============================================================ */

/* ---------------- Device Settings (hub tab) ---------------- */
function DeviceSettingsTab({ app, device, update }) {
  const d = device;
  const [share, setShare] = useS(false);
  const [admin, setAdmin] = useS(false);
  const [confirm, setConfirm] = useS(null);
  const lv = d.config.logLevel;

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
        <Row icon="edit" label="Tên robot" sub={d.name} onClick={() => {}} />
        <Divider /><Row icon="location" label="Vị trí" sub={`${d.location} · ${d.city}`} onClick={() => {}} />
        <Divider /><Row icon="globe" label="Múi giờ" sub="Asia/Ho_Chi_Minh (GMT+7)" onClick={() => {}} />
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
        <Row icon="bluetooth" label="Ghép nối lại (BLE)" sub="Đổi Wi‑Fi hoặc máy chủ" onClick={() => {}} />
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
  const invite = () => { if (!email.trim()) return; setPeople(p => [...p, { name: email.split('@')[0], email, role: 'Xem', em: 'curious' }]); setEmail(''); };
  return (
    <div>
      <div style={{ display: 'flex', gap: 10, marginBottom: 18 }}>
        <input className="field" value={email} onChange={e => setEmail(e.target.value)} placeholder="Mời qua email…" style={{ height: 50 }} />
        <button className="press" onClick={invite} style={{ width: 50, height: 50, borderRadius: 14, background: 'var(--cyan)', display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="plus" size={22} color="#06222b" strokeWidth={2.2} /></button>
      </div>
      <button className="press" style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, padding: 14, borderRadius: 14, border: '1.5px dashed var(--hairline-2)', color: 'var(--tx-soft)', fontWeight: 600, marginBottom: 18 }}><Icon name="qr" size={20} color="var(--cyan)" /> Chia sẻ bằng mã QR</button>
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
    </div>
  );
}

/* ---------------- Profile ---------------- */
function ProfileScreen({ app }) {
  return (
    <>
      <TopBar title="Hồ sơ" onBack={app.goHome} />
      <Scroll style={{ padding: '8px 18px 28px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '14px 0 8px' }}>
          <div style={{ position: 'relative' }}>
            <span style={{ width: 96, height: 96, borderRadius: '50%', background: 'linear-gradient(140deg,#5BE9FF,#76B8FF)', display: 'grid', placeItems: 'center', fontSize: 38, fontWeight: 800, color: '#06222b' }}>T</span>
            <button className="press" style={{ position: 'absolute', right: -2, bottom: -2, width: 34, height: 34, borderRadius: '50%', background: 'var(--bg-2)', border: '2px solid var(--bg-base)', display: 'grid', placeItems: 'center' }}><Icon name="edit" size={15} color="var(--cyan)" /></button>
          </div>
          <div className="t-h2" style={{ marginTop: 14 }}>Test User</div>
          <div className="t-sub">test@example.com</div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, margin: '20px 0' }}>
          <MiniStat icon="cpu" color="var(--cyan)" big="2" label="Robot" />
          <MiniStat icon="chat" color="var(--rose)" big="129" label="Tương tác" />
          <MiniStat icon="clock" color="var(--green)" big="42" label="Ngày" />
        </div>
        <Section>Tài khoản</Section>
        <div className="card">
          <Row icon="user" label="Chỉnh sửa hồ sơ" onClick={() => {}} />
          <Divider /><Row icon="lock" label="Đổi mật khẩu" onClick={() => {}} />
          <Divider /><Row icon="shield" label="Bảo mật & quyền riêng tư" onClick={() => {}} />
        </div>
        <button className="press" onClick={() => app.logout()} style={{ width: '100%', marginTop: 22, height: 52, borderRadius: 16, border: '1px solid ' + hexA('#FF5B6E', .3), color: 'var(--red)', fontWeight: 700, fontSize: 15, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}><Icon name="power" size={19} color="var(--red)" /> Đăng xuất</button>
      </Scroll>
    </>
  );
}

/* ---------------- App Settings ---------------- */
function AppSettingsScreen({ app }) {
  const [lang, setLang] = useS('vi');
  const [dark, setDark] = useS(true);
  const [notif, setNotif] = useS(true);
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
          <Divider /><Row icon="moon" label="Giờ yên tĩnh" sub="22:00 – 07:00" onClick={() => {}} />
        </div>
        <Section>Khác</Section>
        <div className="card">
          <Row icon="info" label="Về Luni" sub="Ứng dụng v1.0.0 · build 124" onClick={() => {}} />
          <Divider /><Row icon="shield" label="Điều khoản & quyền riêng tư" onClick={() => {}} />
          <Divider /><Row icon="chat" label="Hỗ trợ" onClick={() => {}} />
        </div>
        <button className="press" onClick={() => app.logout()} style={{ width: '100%', marginTop: 22, height: 52, borderRadius: 16, border: '1px solid ' + hexA('#FF5B6E', .3), color: 'var(--red)', fontWeight: 700, fontSize: 15, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}><Icon name="power" size={19} color="var(--red)" /> Đăng xuất</button>
      </Scroll>
    </>
  );
}

Object.assign(window, { DeviceSettingsTab, SharingPanel, ProfileScreen, AppSettingsScreen, ConfirmDialog, Divider });
