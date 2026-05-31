/* ============================================================
   Device Hub — shell with tab strip + Overview dashboard (hero)
   ============================================================ */
const HUB_TABS = [
  { id: 'overview', label: 'Tổng quan', icon: 'grid' },
  { id: 'control', label: 'Điều khiển', icon: 'sliders' },
  { id: 'history', label: 'Trò chuyện', icon: 'chat' },
  { id: 'stats', label: 'Thống kê', icon: 'chart' },
  { id: 'ota', label: 'Cập nhật', icon: 'download' },
  { id: 'settings', label: 'Cài đặt', icon: 'gear' },
];

function HubScreen({ app }) {
  const { device, updateDevice, goHome, openSettings } = app;
  const [tab, setTab] = useS('overview');
  const em = LUNI_EMOTIONS[device.emotion] || LUNI_EMOTIONS.idle;

  const Tabs = {
    overview: OverviewTab, control: window.ControlTab,
    history: window.ConversationTab, stats: window.StatsTab, ota: window.OtaTab, settings: window.DeviceSettingsTab,
  };
  const Active = Tabs[tab] || OverviewTab;

  return (
    <>
      <TopBar
        title={device.name}
        sub={<span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><MoodDot emotion={device.emotion} dim={!device.online} size={7} /> {device.online ? em.label : 'Ngoại tuyến'}</span>}
        onBack={goHome}
        right={<button className="press" onClick={() => setTab('settings')} style={iconBtn}><Icon name="gear" size={21} /></button>}
      />
      <TabStrip tabs={HUB_TABS} active={tab} onSelect={setTab} />
      <div className="screen-anim" key={tab} style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
        <Active app={app} device={device} update={updateDevice} setTab={setTab} />
      </div>
    </>
  );
}

/* ---------------- Overview ---------------- */
function OverviewTab({ device, update, setTab }) {
  const d = device;
  const moon = useLunar();
  const sp = specialDay(moon);
  const heroEmotion = (sp && d.online) ? sp.emotion : d.emotion;
  const em = LUNI_EMOTIONS[heroEmotion] || LUNI_EMOTIONS.idle;
  return (
    <Scroll style={{ padding: '14px 18px 28px' }}>
      {/* hero */}
      <div className="card" style={{ position: 'relative', overflow: 'hidden', padding: '26px 18px 20px', textAlign: 'center', background: `radial-gradient(120% 90% at 50% -10%, ${hexA(em.color, d.online ? .16 : .04)}, var(--bg-1) 60%)`, borderColor: d.online ? hexA(em.color, .22) : 'var(--hairline)' }}>
        <div style={{ animation: 'floatY 5s ease-in-out infinite' }}><LuniFace emotion={heroEmotion} size={150} dim={!d.online} state={d.online ? 'idle' : 'idle'} /></div>
        <div style={{ marginTop: 14, fontSize: 14, color: 'var(--tx-mute)' }}>{d.online ? 'Luni đang cảm thấy' : 'Lần cuối trực tuyến 18 phút trước'}</div>
        {d.online && <div className="t-h2" style={{ marginTop: 2, color: em.color }}>{em.label}</div>}
        {sp && d.online && (
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 8, padding: '5px 11px', borderRadius: 99, background: hexA(sp.color, 0.14), border: `1px solid ${hexA(sp.color, 0.32)}` }}>
            <MoonGlyph p={moon.p} size={15} color={sp.color} glow={false} ring={false} />
            <span style={{ fontSize: 11.5, fontWeight: 700, color: sp.color }}>Tự đổi vì {sp.vi}</span>
          </div>
        )}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 10, marginTop: 16 }}>
          <HeroBtn icon="sliders" label="Điều khiển" onClick={() => setTab('control')} primary />
          <HeroBtn icon="sun" label="Đánh thức" onClick={() => update({ emotion: 'happy' })} />
          <HeroBtn icon="wave" label="Thư giãn" onClick={() => update({ emotion: 'calm' })} />
        </div>
      </div>

      {/* moon phase — Luni follows the lunar cycle */}
      <div style={{ marginTop: 14 }}>
        <MoonCard accent={em.color} />
      </div>

      {/* stat grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 14 }}>
        <StatCard>
          <Ring value={d.batteryPercent} size={96} stroke={8} color={d.charging ? 'var(--green)' : d.batteryPercent <= 15 ? 'var(--red)' : 'var(--cyan)'}>
            <div>
              <div style={{ fontSize: 22, fontWeight: 800, lineHeight: 1 }}>{d.batteryPercent}<span style={{ fontSize: 12 }}>%</span></div>
              {d.charging && <div style={{ fontSize: 10, color: 'var(--green)', fontWeight: 700, display: 'flex', alignItems: 'center', gap: 2, justifyContent: 'center', marginTop: 2 }}><Icon name="bolt" size={11} color="var(--green)" /> Sạc</div>}
            </div>
          </Ring>
          <StatLabel icon="battery" text="Pin" />
        </StatCard>

        <StatCard>
          <div style={{ display: 'grid', placeItems: 'center', height: 96 }}>
            <Icon name="wifi" size={40} color={d.online ? 'var(--cyan)' : 'var(--tx-faint)'} strokeWidth={1.6} />
            <div className="mono" style={{ fontSize: 14, fontWeight: 700, marginTop: 6 }}>{d.rssi} dBm</div>
          </div>
          <StatLabel icon="signal" text={d.online ? 'Nha_Cua_Tui_5G' : 'Mất kết nối'} />
        </StatCard>

        <StatCard onClick={() => setTab('ota')}>
          <div style={{ display: 'grid', placeItems: 'center', height: 96 }}>
            <Icon name="cpu" size={38} color="var(--purple)" strokeWidth={1.5} />
            <div className="mono" style={{ fontSize: 15, fontWeight: 700, marginTop: 8 }}>v{d.fwVersion}</div>
            <span className="pill" style={{ height: 22, marginTop: 6, background: hexA('#FFD166', .14), color: 'var(--warm)' }}>Có bản 2.2.0</span>
          </div>
          <StatLabel icon="download" text="Firmware" />
        </StatCard>

        <StatCard>
          <div style={{ display: 'grid', placeItems: 'center', height: 96 }}>
            <Icon name="location" size={38} color="var(--rose)" strokeWidth={1.5} />
            <div style={{ fontSize: 15, fontWeight: 700, marginTop: 8 }}>{d.location}</div>
            <div style={{ fontSize: 12, color: 'var(--tx-mute)', marginTop: 2 }}>{d.city} · GMT+7</div>
          </div>
          <StatLabel icon="globe" text="Vị trí" />
        </StatCard>
      </div>

      {/* recent activity */}
      <Section>Hoạt động gần đây</Section>
      <div className="card" style={{ padding: '4px 14px' }}>
        {RECENT.map((r, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0', borderBottom: i < RECENT.length - 1 ? '1px solid var(--hairline)' : 'none' }}>
            <MoodDot emotion={r.em} size={9} />
            <span style={{ flex: 1, fontSize: 13.5 }}>{r.text}</span>
            <span className="mono" style={{ fontSize: 11.5, color: 'var(--tx-faint)' }}>{r.t}</span>
          </div>
        ))}
        <button className="press" onClick={() => setTab('history')} style={{ width: '100%', padding: '12px 0 10px', color: 'var(--cyan)', fontWeight: 700, fontSize: 13.5, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>Xem lịch sử trò chuyện <Icon name="chevron" size={16} color="var(--cyan)" /></button>
      </div>
    </Scroll>
  );
}

const RECENT = [
  { em: 'happy', text: 'Phát nhạc theo lịch buổi sáng', t: '34p' },
  { em: 'calm', text: 'Chuyển sang chế độ thư giãn', t: '1g' },
  { em: 'curious', text: 'Wi‑Fi yếu — tự động roaming', t: '1g' },
  { em: 'idle', text: 'Đồng bộ với máy chủ', t: '2g' },
];

function HeroBtn({ icon, label, onClick, primary }) {
  return (
    <button className="press" onClick={onClick} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, width: 78 }}>
      <span style={{ width: 52, height: 52, borderRadius: 16, display: 'grid', placeItems: 'center', background: primary ? 'var(--cyan)' : 'var(--bg-2)', border: primary ? 'none' : '1px solid var(--hairline)', boxShadow: primary ? '0 8px 20px -6px rgba(91,233,255,.5)' : 'none' }}>
        <Icon name={icon} size={22} color={primary ? '#04222b' : 'var(--tx)'} strokeWidth={primary ? 2.2 : 1.8} />
      </span>
      <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--tx-soft)' }}>{label}</span>
    </button>
  );
}

function StatCard({ children, onClick }) {
  return <button className={onClick ? 'press' : ''} onClick={onClick} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, padding: '18px 12px 14px', borderRadius: 18, background: 'var(--bg-1)', border: '1px solid var(--hairline)', width: '100%', textAlign: 'center' }}>{children}</button>;
}
function StatLabel({ icon, text }) {
  return <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--tx-mute)', fontSize: 12.5, fontWeight: 600, maxWidth: '100%', overflow: 'hidden' }}><Icon name={icon} size={14} color="var(--tx-faint)" /><span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{text}</span></div>;
}

Object.assign(window, { HubScreen, OverviewTab, HUB_TABS, HeroBtn, StatCard, StatLabel, RECENT });
