/* ============================================================
   Home — device list, empty state, quick access
   ============================================================ */
function DeviceCard({ d, onOpen }) {
  const moon = useLunar();
  const sp = specialDay(moon);
  const showEmotion = (sp && d.online) ? sp.emotion : d.emotion;
  const em = LUNI_EMOTIONS[showEmotion] || LUNI_EMOTIONS.idle;
  return (
    <button className="press" onClick={() => onOpen(d)} style={{
      width: '100%', textAlign: 'left', padding: 16, borderRadius: 22, position: 'relative', overflow: 'hidden',
      background: d.online ? `linear-gradient(150deg, ${hexA(em.color, .08)}, var(--bg-1) 55%)` : 'var(--bg-1)',
      border: `1px solid ${d.online ? hexA(em.color, .2) : 'var(--hairline)'}`,
    }}>
      <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
        <LuniFace emotion={showEmotion} size={66} dim={!d.online} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-.01em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.name}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--tx-mute)', fontSize: 13, marginTop: 3 }}>
            <Icon name="location" size={14} color="var(--tx-faint)" /> {d.location} · {d.city}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 11 }}>
            <StatusPill online={d.online} />
            <Battery pct={d.batteryPercent} charging={d.charging} />
          </div>
        </div>
        <Icon name="chevron" size={20} color="var(--tx-faint)" />
      </div>
      <div style={{ display: 'flex', gap: 8, marginTop: 14 }}>
        <MiniChip icon="sparkle" color={em.color} label={em.label} />
        <MiniChip icon="grid" color="var(--tx-soft)" label={SCENE_VI[d.scene] || d.scene} />
        <MiniChip icon="signal" color={d.online ? 'var(--tx-soft)' : 'var(--tx-faint)'} label={`${d.rssi} dBm`} />
      </div>
    </button>
  );
}

const SCENE_VI = { home: 'Trang chủ', weather: 'Thời tiết', clock: 'Đồng hồ', calendar: 'Lịch', sleep: 'Ngủ', music: 'Nhạc' };

function MiniChip({ icon, color, label }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, height: 30, padding: '0 11px', borderRadius: 99, background: 'var(--bg-2)', fontSize: 12.5, fontWeight: 600, color: 'var(--tx-soft)', border: '1px solid var(--hairline)' }}>
      <Icon name={icon} size={14} color={color} /> {label}
    </span>
  );
}

function HomeScreen({ app }) {
  const { devices, userName, openDevice, startPairing, openProfile, openSettings } = app;
  const moon = useLunar();
  const online = devices.filter(d => d.online).length;
  const empty = devices.length === 0;

  return (
    <>
      <TopBar
        title="Luni"
        right={<>
          <span title="Tuần trăng đêm nay" style={{ display: 'grid', placeItems: 'center', width: 36, height: 44 }}>
            <MoonGlyph p={moon.p} size={22} color="var(--cyan)" />
          </span>
          <button className="press" onClick={openProfile} style={iconBtn}><Icon name="user" size={22} /></button>
          <button className="press" onClick={openSettings} style={iconBtn}><Icon name="gear" size={22} /></button>
        </>}
      />
      <Scroll style={{ padding: '4px 18px 110px' }}>
        <div className="screen-anim">
          <h1 className="t-h1" style={{ marginTop: 6 }}>Nhà của {userName}</h1>
          <p className="t-sub" style={{ margin: '4px 0 22px' }}>
            {empty ? 'Chưa có robot nào — hãy ghép nối Luni đầu tiên.' : <><b style={{ color: online ? 'var(--green)' : 'var(--tx-soft)' }}>{online}/{devices.length}</b> robot đang trực tuyến</>}
          </p>

          {empty ? <EmptyHome onAdd={startPairing} /> : (
            <div style={{ display: 'grid', gap: 14 }}>
              {devices.map(d => <DeviceCard key={d.id} d={d} onOpen={openDevice} />)}
              <button className="press" onClick={startPairing} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: 16, borderRadius: 20,
                border: '1.5px dashed var(--hairline-2)', background: 'transparent', color: 'var(--tx-soft)',
              }}>
                <span style={{ width: 44, height: 44, borderRadius: 13, background: hexA('#5BE9FF', .12), display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="plus" size={22} color="var(--cyan)" strokeWidth={2.2} /></span>
                <span style={{ textAlign: 'left' }}>
                  <span style={{ display: 'block', fontWeight: 700, fontSize: 15, color: 'var(--tx)' }}>Thêm robot mới</span>
                  <span style={{ display: 'block', fontSize: 12.5, color: 'var(--tx-mute)' }}>Ghép nối qua Bluetooth</span>
                </span>
              </button>
            </div>
          )}
        </div>
      </Scroll>

      {!empty && (
        <button className="press" onClick={startPairing} style={{
          position: 'absolute', right: 18, bottom: 20, height: 56, padding: '0 22px 0 18px', borderRadius: 18,
          display: 'flex', alignItems: 'center', gap: 10, background: 'var(--cyan)', color: '#04222b',
          fontWeight: 700, fontSize: 15, boxShadow: '0 14px 34px -8px rgba(91,233,255,.6)', zIndex: 10,
        }}>
          <Icon name="bluetooth" size={20} color="#04222b" strokeWidth={2.2} /> Thêm robot
        </button>
      )}
    </>
  );
}

function EmptyHome({ onAdd }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: '30px 10px' }}>
      <div style={{ animation: 'floatY 4s ease-in-out infinite' }}><LuniFace emotion="curious" size={150} /></div>
      <h2 className="t-h2" style={{ margin: '26px 0 6px' }}>Xin chào! Mình là Luni.</h2>
      <p className="t-body" style={{ color: 'var(--tx-mute)', maxWidth: 280, margin: '0 0 26px' }}>Bật nguồn robot và để gần điện thoại. Mình sẽ giúp bạn kết nối trong vài bước.</p>
      <button className="cta" onClick={onAdd} style={{ maxWidth: 300 }}><Icon name="bluetooth" size={20} color="#04222b" strokeWidth={2.2} /> Ghép nối Luni</button>
    </div>
  );
}

Object.assign(window, { HomeScreen, DeviceCard, MiniChip, EmptyHome, SCENE_VI });
