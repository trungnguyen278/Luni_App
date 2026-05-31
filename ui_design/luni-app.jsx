/* ============================================================
   Luni App — root router & state
   ============================================================ */
const SEED_DEVICES = [
  { id: 'AA:BB:CC:DD:EE:01', name: 'Luni Phòng khách', location: 'Phòng khách', city: 'Hà Nội', model: 'luni_v2_s3c5', fwVersion: '2.1.0', online: true, batteryPercent: 84, charging: false, rssi: -42, emotion: 'happy', scene: 'weather', config: { volume: 62, brightness: 92, logLevel: 'info', autoOta: false } },
  { id: 'AA:BB:CC:DD:EE:02', name: 'Luni Bàn làm việc', location: 'Góc làm việc', city: 'Hồ Chí Minh', model: 'luni_v2_s3c5', fwVersion: '2.0.4', online: false, batteryPercent: 31, charging: true, rssi: -67, emotion: 'sleepy', scene: 'sleep', config: { volume: 45, brightness: 70, logLevel: 'warn', autoOta: true } },
];

function LuniApp() {
  const [screen, setScreen] = useS('auth');     // auth | home | pairing | hub | profile | appsettings | admin
  const [role, setRole] = useS('user');         // user | admin (from login email)
  const [adminEmail, setAdminEmail] = useS('');
  const [devices, setDevices] = useS(SEED_DEVICES);
  const [selId, setSelId] = useS(null);
  const device = devices.find(d => d.id === selId) || devices[0];

  const updateDevice = (patch) => setDevices(ds => ds.map(d => d.id === (selId || ds[0]?.id) ? { ...d, ...patch } : d));

  const app = {
    devices, userName: 'Test User', device, role, adminEmail,
    openDevice: (d) => { setSelId(d.id); setScreen('hub'); },
    updateDevice,
    startPairing: () => setScreen('pairing'),
    goHome: () => setScreen('home'),
    openProfile: () => setScreen('profile'),
    openSettings: () => setScreen('appsettings'),
    logout: () => { setRole('user'); setScreen('auth'); },
  };

  let body;
  if (screen === 'auth') body = <AuthFlow onAuthed={(r, mail) => { setRole(r); setAdminEmail(mail || ''); setScreen(r === 'admin' ? 'admin' : 'home'); }} />;
  else if (screen === 'admin') body = <AdminDashboard app={app} />;
  else if (screen === 'home') body = <HomeScreen app={app} />;
  else if (screen === 'pairing') body = <PairingFlow onCancel={() => setScreen('home')} onComplete={(nd) => { setDevices(ds => [...ds, nd]); setSelId(nd.id); setScreen('hub'); }} />;
  else if (screen === 'hub') body = <HubScreen app={app} />;
  else if (screen === 'profile') body = <ProfileScreen app={app} />;
  else if (screen === 'appsettings') body = <AppSettingsScreen app={app} />;

  // external prototype nav (only after auth)
  const userJumps = [
    ['home', 'home', 'Trang chủ'], ['pairing', 'bluetooth', 'Ghép nối'],
    ['hub', 'grid', 'Bảng điều khiển'], ['profile', 'user', 'Hồ sơ'], ['appsettings', 'gear', 'Cài đặt'],
  ];
  const adminJumps = [['admin', 'shield', 'Bảng dịch vụ']];
  const jumps = role === 'admin' ? adminJumps : userJumps;
  const accent = role === 'admin' ? 'var(--purple)' : 'var(--cyan)';

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 40, padding: '40px 24px', background: 'radial-gradient(120% 100% at 50% 0%, #0c1020 0%, #07090f 60%)' }}>
      <div>
        <Phone>{body}</Phone>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 6, width: 230 }}>
        <div className="t-over" style={{ marginBottom: 6 }}>{role === 'admin' ? 'Luni Service · Admin' : 'Luni OS · Prototype'}</div>
        {jumps.map(([id, ic, label]) => {
          const on = screen === id;
          return (
            <button key={id} className="press" onClick={() => { if (id === 'hub' && !selId) setSelId(devices[0].id); setScreen(id); }} style={{
              display: 'flex', alignItems: 'center', gap: 11, padding: '11px 14px', borderRadius: 13, textAlign: 'left',
              background: on ? 'var(--bg-2)' : 'transparent', border: `1px solid ${on ? 'var(--hairline-2)' : 'transparent'}`,
              color: on ? 'var(--tx)' : 'var(--tx-mute)', transition: 'all .15s',
            }}>
              <Icon name={ic} size={18} color={on ? accent : 'var(--tx-faint)'} strokeWidth={1.8} /> <span style={{ fontSize: 13.5, fontWeight: 600 }}>{label}</span>
            </button>
          );
        })}
        {role === 'admin' && (
          <button className="press" onClick={() => { setRole('user'); setScreen('auth'); }} style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '11px 14px', borderRadius: 13, textAlign: 'left', background: 'transparent', border: '1px solid transparent', color: 'var(--tx-mute)' }}>
            <Icon name="power" size={18} color="var(--tx-faint)" strokeWidth={1.8} /> <span style={{ fontSize: 13.5, fontWeight: 600 }}>Đăng xuất</span>
          </button>
        )}
        <a href="App Icon.html" style={{ textDecoration: 'none' }}>
          <button className="press" style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '11px 14px', borderRadius: 13, textAlign: 'left', width: '100%', background: 'transparent', border: '1px solid transparent', color: 'var(--tx-mute)' }}>
            <Icon name="sparkle" size={18} color="var(--warm)" strokeWidth={1.8} /> <span style={{ fontSize: 13.5, fontWeight: 600 }}>App Icon →</span>
          </button>
        </a>
        <p style={{ fontSize: 11.5, color: 'var(--tx-faint)', lineHeight: 1.5, margin: '12px 4px 0' }}>Bấm để nhảy nhanh giữa các luồng, hoặc dùng điều hướng trong app.</p>
        {role !== 'admin' && <LuniDateDevPanel accent="#5BE9FF" />}
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<LuniApp />);
Object.assign(window, { LuniApp, SEED_DEVICES });
