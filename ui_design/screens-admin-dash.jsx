/* ============================================================
   Admin Ops Dashboard — service console for technicians.
   Reached ONLY when an admin account logs in (email → role).
   Fleet view → per-robot service (diagnostics, config, logs,
   firmware, danger-zone reset). Purple-accented, dense, technical.
   ============================================================ */

const ADMIN_FLEET = [
  { id: 'AA:BB:CC:DD:EE:01', name: 'Luni #0142', owner: 'Nguyễn Mai',  city: 'Hà Nội',      fw: '2.1.0', online: true,  battery: 84, charging: false, rssi: -42, heap: 45032, minHeap: 38110, uptime: '23g 58p', reset: 'POWERON',  status: 'ok' },
  { id: 'AA:BB:CC:DD:EE:02', name: 'Luni #0098', owner: 'Trần Hùng',   city: 'Hồ Chí Minh', fw: '2.0.4', online: true,  battery: 12, charging: false, rssi: -71, heap: 18840, minHeap: 12030, uptime: '2g 04p',  reset: 'BROWNOUT', status: 'warn',  issue: 'Pin yếu · heap thấp dần' },
  { id: 'AA:BB:CC:DD:EE:03', name: 'Luni #0205', owner: 'Lê Trang',    city: 'Đà Nẵng',     fw: '2.1.0', online: false, battery: 0,  charging: false, rssi: -99, heap: 0,     minHeap: 0,     uptime: '—',       reset: '—',        status: 'offline', issue: 'Mất kết nối 3 ngày' },
  { id: 'AA:BB:CC:DD:EE:04', name: 'Luni #0311', owner: 'Phạm Đức',    city: 'Hải Phòng',   fw: '1.9.8', online: true,  battery: 64, charging: true,  rssi: -55, heap: 9120,  minHeap: 4880,  uptime: '0g 12p',  reset: 'PANIC',    status: 'error', issue: 'Crash loop · NVS lỗi (0x0a)' },
  { id: 'AA:BB:CC:DD:EE:05', name: 'Luni #0420', owner: 'Võ Linh',     city: 'Cần Thơ',     fw: '2.1.0', online: true,  battery: 78, charging: false, rssi: -48, heap: 40210, minHeap: 33020, uptime: '5g 30p',  reset: 'POWERON',  status: 'updating', issue: 'Đang nạp OTA 62% → 2.2.0' },
  { id: 'AA:BB:CC:DD:EE:06', name: 'Luni #0507', owner: '— chưa gán',  city: 'Kho Bắc Ninh', fw: '2.1.0', online: true, battery: 91, charging: false, rssi: -39, heap: 46880, minHeap: 44120, uptime: '0g 03p',  reset: 'POWERON',  status: 'provision', issue: 'Chưa cấp phép · cần gán user' },
];

const FLEET_STATUS = {
  ok:        { c: '#7BE88E', label: 'Tốt',         icon: 'check' },
  warn:      { c: '#FF9D5B', label: 'Cảnh báo',    icon: 'alert' },
  error:     { c: '#FF5B6E', label: 'Lỗi',         icon: 'alert' },
  offline:   { c: '#5C6680', label: 'Ngoại tuyến', icon: 'power' },
  updating:  { c: '#76B8FF', label: 'Đang cập nhật', icon: 'download' },
  provision: { c: '#B48CFF', label: 'Chưa cấp phép', icon: 'key' },
};

const FLEET_FILTERS = [
  { id: 'all',     label: 'Tất cả' },
  { id: 'attention', label: 'Cần xử lý' },
  { id: 'offline', label: 'Ngoại tuyến' },
  { id: 'updating', label: 'Đang cập nhật' },
];

/* ---------------- root ---------------- */
function AdminDashboard({ app }) {
  const [view, setView] = useS('fleet');
  const [selId, setSelId] = useS(null);
  const sel = ADMIN_FLEET.find(d => d.id === selId);

  if (view === 'service' && sel) {
    return <AdminService device={sel} onBack={() => setView('fleet')} />;
  }
  return <AdminFleet onOpen={(d) => { setSelId(d.id); setView('service'); }} onLogout={app.logout} email={app.adminEmail} />;
}

/* ---------------- ops header ---------------- */
function AdminBar({ title, sub, onBack, right }) {
  return (
    <div style={{ flex: 'none', minHeight: 56, padding: '8px 10px 8px 6px', display: 'flex', alignItems: 'center', gap: 6, borderBottom: '1px solid var(--hairline)', background: 'linear-gradient(180deg, rgba(180,140,255,.07), transparent)' }}>
      {onBack ? (
        <button className="press" onClick={onBack} style={iconBtn}><Icon name="back" size={22} /></button>
      ) : (
        <span style={{ width: 40, height: 40, marginLeft: 6, borderRadius: 12, background: hexA('#B48CFF', .16), display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="shield" size={21} color="var(--purple)" strokeWidth={2} /></span>
      )}
      <div style={{ flex: 1, minWidth: 0, paddingLeft: onBack ? 2 : 10 }}>
        <div style={{ fontSize: 16.5, fontWeight: 800, letterSpacing: '-.01em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>
        {sub && <div className="mono" style={{ fontSize: 11, color: 'var(--tx-mute)', marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 2 }}>{right}</div>
    </div>
  );
}

/* ---------------- fleet list ---------------- */
function AdminFleet({ onOpen, onLogout, email }) {
  const [filter, setFilter] = useS('all');
  const [q, setQ] = useS('');

  const total = ADMIN_FLEET.length;
  const onlineN = ADMIN_FLEET.filter(d => d.online).length;
  const attentionN = ADMIN_FLEET.filter(d => d.status !== 'ok').length;

  const list = ADMIN_FLEET.filter(d => {
    if (filter === 'attention' && d.status === 'ok') return false;
    if (filter === 'offline' && d.status !== 'offline') return false;
    if (filter === 'updating' && d.status !== 'updating') return false;
    if (q.trim()) {
      const s = (d.name + ' ' + d.id + ' ' + d.owner + ' ' + d.city).toLowerCase();
      if (!s.includes(q.trim().toLowerCase())) return false;
    }
    return true;
  });

  return (
    <>
      <AdminBar
        title="Luni Service"
        sub="bảng điều khiển kỹ thuật"
        right={<>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', marginRight: 4 }}>
            <span style={{ fontSize: 11.5, fontWeight: 700, color: 'var(--purple)' }}>ADMIN</span>
            <span className="mono" style={{ fontSize: 10, color: 'var(--tx-faint)', maxWidth: 120, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{email || 'admin@luni.vn'}</span>
          </div>
          <button className="press" onClick={onLogout} title="Đăng xuất" style={iconBtn}><Icon name="power" size={20} color="var(--tx-mute)" /></button>
        </>}
      />

      <Scroll style={{ padding: '14px 16px 28px' }}>
        {/* summary band */}
        <div className="card" style={{ display: 'flex', padding: '14px 4px', background: 'radial-gradient(120% 120% at 0% 0%, rgba(180,140,255,.1), var(--bg-1) 60%)', borderColor: hexA('#B48CFF', .2) }}>
          <StatCell n={total} label="Thiết bị" c="var(--tx)" />
          <span style={{ width: 1, background: 'var(--hairline)' }} />
          <StatCell n={onlineN} label="Trực tuyến" c="var(--green)" />
          <span style={{ width: 1, background: 'var(--hairline)' }} />
          <StatCell n={attentionN} label="Cần xử lý" c="var(--orange)" />
        </div>

        {/* search */}
        <div style={{ position: 'relative', marginTop: 14 }}>
          <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none' }}><Icon name="search" size={18} color="var(--tx-faint)" /></span>
          <input value={q} onChange={e => setQ(e.target.value)} placeholder="Tìm theo tên, MAC, chủ sở hữu…" className="mono"
            style={{ width: '100%', height: 46, padding: '0 14px 0 42px', background: 'var(--bg-2)', border: '1px solid var(--hairline)', borderRadius: 13, color: 'var(--tx)', fontSize: 13, outline: 'none' }} />
        </div>

        {/* filters */}
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', margin: '12px 0 6px', paddingBottom: 2 }}>
          {FLEET_FILTERS.map(f => {
            const on = filter === f.id;
            const badge = f.id === 'attention' ? attentionN : f.id === 'offline' ? ADMIN_FLEET.filter(d => d.status === 'offline').length : f.id === 'updating' ? ADMIN_FLEET.filter(d => d.status === 'updating').length : total;
            return (
              <button key={f.id} className="press" onClick={() => setFilter(f.id)} style={{
                flex: 'none', display: 'flex', alignItems: 'center', gap: 7, height: 36, padding: '0 13px', borderRadius: 99, whiteSpace: 'nowrap',
                background: on ? hexA('#B48CFF', .18) : 'var(--bg-2)', color: on ? 'var(--purple)' : 'var(--tx-mute)',
                border: `1px solid ${on ? hexA('#B48CFF', .45) : 'var(--hairline)'}`, fontSize: 13, fontWeight: 700,
              }}>
                {f.label}
                <span style={{ fontSize: 10.5, fontWeight: 800, padding: '1px 6px', borderRadius: 99, background: on ? hexA('#B48CFF', .25) : 'var(--bg-3)', color: on ? 'var(--purple)' : 'var(--tx-faint)' }}>{badge}</span>
              </button>
            );
          })}
        </div>

        {/* list */}
        <div style={{ display: 'grid', gap: 10, marginTop: 8 }}>
          {list.length === 0 && (
            <div style={{ textAlign: 'center', padding: '40px 0', color: 'var(--tx-faint)', fontSize: 13.5 }}>Không có thiết bị nào khớp.</div>
          )}
          {list.map(d => <FleetRow key={d.id} d={d} onOpen={onOpen} />)}
        </div>
      </Scroll>
    </>
  );
}

function StatCell({ n, label, c }) {
  return (
    <div style={{ flex: 1, textAlign: 'center' }}>
      <div style={{ fontSize: 26, fontWeight: 800, lineHeight: 1, color: c }}>{n}</div>
      <div className="t-cap" style={{ marginTop: 5 }}>{label}</div>
    </div>
  );
}

function FleetRow({ d, onOpen }) {
  const st = FLEET_STATUS[d.status];
  const issue = d.status !== 'ok';
  return (
    <button className="press" onClick={() => onOpen(d)} style={{
      width: '100%', textAlign: 'left', padding: 14, borderRadius: 18,
      background: 'var(--bg-1)', border: `1px solid ${issue ? hexA(st.c, .28) : 'var(--hairline)'}`,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <span style={{ width: 40, height: 40, borderRadius: 12, background: hexA(st.c, .14), display: 'grid', placeItems: 'center', flex: 'none', boxShadow: d.online ? `0 0 14px ${hexA(st.c, .25)}` : 'none' }}>
          <Icon name={st.icon} size={19} color={st.c} strokeWidth={2.1} />
        </span>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 15.5, fontWeight: 700, whiteSpace: 'nowrap' }}>{d.name}</span>
            <span style={{ fontSize: 10, fontWeight: 800, letterSpacing: '.03em', padding: '2px 7px', borderRadius: 6, color: st.c, background: hexA(st.c, .14) }}>{st.label}</span>
          </div>
          <div className="mono" style={{ fontSize: 11, color: 'var(--tx-faint)', marginTop: 3, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.id}</div>
        </div>
        <Icon name="chevron" size={18} color="var(--tx-faint)" />
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12, flexWrap: 'wrap' }}>
        <FleetChip icon="user" text={`${d.owner} · ${d.city}`} />
        <FleetChip icon="cpu" text={`v${d.fw}`} mono />
        <FleetChip icon="signal" text={d.online ? `${d.rssi} dBm` : 'offline'} mono dim={!d.online} />
        <FleetChip icon="battery" text={`${d.battery}%`} mono dim={d.battery <= 15} />
      </div>

      {issue && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 11, padding: '8px 11px', borderRadius: 11, background: hexA(st.c, .09), border: `1px solid ${hexA(st.c, .22)}` }}>
          <Icon name={st.icon} size={14} color={st.c} />
          <span style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--tx-soft)' }}>{d.issue}</span>
        </div>
      )}
    </button>
  );
}

function FleetChip({ icon, text, mono, dim }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, height: 27, padding: '0 10px', borderRadius: 8, background: 'var(--bg-2)', border: '1px solid var(--hairline)' }}>
      <Icon name={icon} size={13} color="var(--tx-faint)" />
      <span className={mono ? 'mono' : ''} style={{ fontSize: 11.5, fontWeight: 600, color: dim ? 'var(--tx-faint)' : 'var(--tx-soft)' }}>{text}</span>
    </span>
  );
}

/* ---------------- per-robot service console ---------------- */
const ADMIN_SVC_TABS = [
  { id: 'diag',   label: 'Chẩn đoán', icon: 'cpu' },
  { id: 'config', label: 'Cấu hình',  icon: 'gear' },
  { id: 'logs',   label: 'Nhật ký',   icon: 'logs' },
  { id: 'fw',     label: 'Firmware',  icon: 'download' },
  { id: 'reset',  label: 'Reset',     icon: 'alert' },
];

function AdminService({ device, onBack }) {
  const d = device;
  const [conn, setConn] = useS('connecting'); // connecting | ready
  const [tab, setTab] = useS('diag');
  const [confirm, setConfirm] = useS(null);
  const [notice, setNotice] = useS(null);
  const [cfg, setCfg] = useS({ logLevel: 'info', ssid: 'Nha_Khach_5G', wsUrl: 'wss://api.luni.vn/ws', userId: d.owner.startsWith('—') ? '' : 'usr_8842a1', wpass: '', devToken: '' });

  React.useEffect(() => {
    const t = setTimeout(() => setConn('ready'), 1300);
    return () => clearTimeout(t);
  }, []);
  React.useEffect(() => {
    if (!notice) return;
    const t = setTimeout(() => setNotice(null), 2400);
    return () => clearTimeout(t);
  }, [notice]);

  const flash = (icon, c, text) => setNotice({ icon, c, text });
  const set = (patch) => setCfg(c => ({ ...c, ...patch }));
  const st = FLEET_STATUS[d.status];

  if (conn === 'connecting') {
    return (
      <>
        <AdminBar title={d.name} sub={d.id} onBack={onBack} />
        <div style={{ flex: 1, display: 'grid', placeItems: 'center', padding: '0 24px' }}>
          <div style={{ textAlign: 'center' }}>
            <LuniFace emotion="curious" size={120} state="thinking" />
            <div className="t-h3" style={{ marginTop: 18 }}>Đang mở kênh BLE…</div>
            <p className="t-sub" style={{ marginTop: 6 }}>Xác thực admin & đọc CHR_DEVICE_INFO</p>
            <div style={{ display: 'flex', justifyContent: 'center', marginTop: 18 }}><Spinner color="var(--purple)" /></div>
          </div>
        </div>
      </>
    );
  }

  const Body = { diag: SvcDiag, config: SvcConfig, logs: SvcLogs, fw: SvcFirmware, reset: SvcReset }[tab];

  return (
    <>
      <AdminBar
        title={d.name}
        sub={d.id}
        onBack={onBack}
        right={<span style={{ fontSize: 10, fontWeight: 800, letterSpacing: '.03em', padding: '4px 9px', borderRadius: 7, color: st.c, background: hexA(st.c, .14), marginRight: 6 }}>{st.label.toUpperCase()}</span>}
      />

      {/* admin session banner */}
      <div style={{ flex: 'none', padding: '12px 16px 0' }}>
        <div className="card" style={{ padding: '11px 14px', background: 'radial-gradient(120% 120% at 100% 0%, rgba(180,140,255,.12), var(--bg-1) 60%)', borderColor: hexA('#B48CFF', .3) }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 11 }}>
            <span style={{ width: 30, height: 30, borderRadius: 9, background: hexA('#B48CFF', .18), display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="shield" size={16} color="var(--purple)" /></span>
            <span style={{ flex: 1, fontSize: 13, fontWeight: 700, color: 'var(--purple)' }}>Phiên Admin · Level 2</span>
            <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-mute)' }}>BLE · HMAC ✓</span>
          </div>
          <LevelTrack level={2} maxLevel={2} />
        </div>
      </div>

      {/* tab strip */}
      <div style={{ flex: 'none', display: 'flex', gap: 7, overflowX: 'auto', padding: '12px 16px 12px' }}>
        {ADMIN_SVC_TABS.map(t => {
          const on = t.id === tab;
          const danger = t.id === 'reset';
          const c = danger ? '#FF5B6E' : '#B48CFF';
          return (
            <button key={t.id} className="press" onClick={() => setTab(t.id)} style={{
              flex: 'none', display: 'flex', alignItems: 'center', gap: 7, height: 36, padding: '0 13px', borderRadius: 99, whiteSpace: 'nowrap',
              background: on ? hexA(c, .18) : 'var(--bg-2)', color: on ? c : 'var(--tx-mute)',
              border: `1px solid ${on ? hexA(c, .45) : 'var(--hairline)'}`, fontSize: 13, fontWeight: 700,
            }}>
              <Icon name={t.icon} size={15} color={on ? c : 'var(--tx-faint)'} strokeWidth={2} />
              {t.label}
            </button>
          );
        })}
      </div>

      {notice && (
        <div className="glass pop" style={{ position: 'absolute', left: '50%', bottom: 20, transform: 'translateX(-50%)', display: 'flex', alignItems: 'center', gap: 9, padding: '12px 18px', borderRadius: 14, border: '1px solid var(--hairline-2)', zIndex: 40, whiteSpace: 'nowrap', boxShadow: 'var(--shadow-pop)' }}>
          <Icon name={notice.icon} size={17} color={notice.c} strokeWidth={2.3} />
          <span style={{ fontSize: 13.5, fontWeight: 600 }}>{notice.text}</span>
        </div>
      )}

      <div className="screen-anim" key={tab} style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
        <Body d={d} cfg={cfg} set={set} flash={flash} confirm={setConfirm} />
      </div>

      {confirm && <ConfirmDialog {...confirm} onClose={() => setConfirm(null)} />}
    </>
  );
}

/* ---- diagnostics ---- */
function SvcDiag({ d, flash }) {
  const metrics = [
    { k: 'free_heap',     v: d.heap ? d.heap.toLocaleString('en-US').replace(/,/g, ' ') + ' B' : '—', warn: d.heap > 0 && d.heap < 20000 },
    { k: 'min_free_heap', v: d.minHeap ? d.minHeap.toLocaleString('en-US').replace(/,/g, ' ') + ' B' : '—', warn: d.minHeap > 0 && d.minHeap < 8000 },
    { k: 'uptime',        v: d.uptime },
    { k: 'rssi',          v: d.online ? d.rssi + ' dBm' : '—', warn: d.online && d.rssi < -70 },
    { k: 'battery',       v: d.battery + '%' + (d.charging ? ' ⚡' : ''), warn: d.battery <= 15 },
    { k: 'fw_version',    v: 'v' + d.fw },
    { k: 'reset_reason',  v: d.reset, warn: d.reset === 'PANIC' || d.reset === 'BROWNOUT' },
  ];
  return (
    <Scroll style={{ padding: '4px 16px 26px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '6px 2px 10px' }}>
        <span className="t-cap">CHR_DIAG_INFO · trực tiếp</span>
        <span className="dot" style={{ background: 'var(--green)', boxShadow: '0 0 8px var(--green)' }} />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {metrics.map(m => (
          <div key={m.k} className="card-2" style={{ padding: '12px 14px', borderColor: m.warn ? hexA('#FF9D5B', .35) : 'var(--hairline)' }}>
            <div className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)' }}>{m.k}</div>
            <div className="mono" style={{ fontSize: 15.5, fontWeight: 700, marginTop: 5, color: m.warn ? 'var(--orange)' : 'var(--tx)' }}>{m.v}</div>
          </div>
        ))}
      </div>

      <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
        <button className="press" onClick={() => flash('refresh', 'var(--purple)', 'Đã đọc lại CHR_DIAG_INFO')} style={svcBtn('var(--purple)')}>
          <Icon name="refresh" size={18} color="var(--purple)" /> Đọc lại
        </button>
        <button className="press" onClick={() => flash('copy', 'var(--cyan)', 'Đã chép báo cáo chẩn đoán')} style={svcBtn('var(--cyan)')}>
          <Icon name="copy" size={18} color="var(--cyan)" /> Chép báo cáo
        </button>
      </div>

      {d.status !== 'ok' && (
        <div className="card" style={{ marginTop: 16, padding: 14, borderColor: hexA(FLEET_STATUS[d.status].c, .3), background: hexA(FLEET_STATUS[d.status].c, .06) }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
            <Icon name="alert" size={16} color={FLEET_STATUS[d.status].c} />
            <span style={{ fontSize: 13.5, fontWeight: 700, color: FLEET_STATUS[d.status].c }}>Sự cố đang ghi nhận</span>
          </div>
          <p style={{ fontSize: 12.5, color: 'var(--tx-soft)', margin: '7px 0 0', lineHeight: 1.5 }}>{d.issue}</p>
        </div>
      )}
    </Scroll>
  );
}

/* ---- config (network / server / account) ---- */
function SvcConfig({ d, cfg, set, flash }) {
  return (
    <Scroll style={{ padding: '4px 16px 26px' }}>
      <div className="t-cap" style={{ margin: '6px 2px 10px' }}>MẠNG & MÁY CHỦ</div>
      <div style={{ display: 'grid', gap: 8 }}>
        <AdminField chr="CHR_SSID" access="R·W" label="Tên Wi‑Fi (SSID)" value={cfg.ssid} onChange={v => set({ ssid: v })} mono />
        <AdminField chr="CHR_PASSWORD" access="W" label="Mật khẩu Wi‑Fi" value={cfg.wpass} onChange={v => set({ wpass: v })} type="password" placeholder="Chỉ ghi — không đọc lại được" />
        <AdminField chr="CHR_WS_URL" access="R·W" label="WebSocket URL" value={cfg.wsUrl} onChange={v => set({ wsUrl: v })} mono />
      </div>

      <div className="t-cap" style={{ margin: '20px 2px 10px' }}>GÁN TÀI KHOẢN</div>
      <div style={{ display: 'grid', gap: 8 }}>
        <AdminField chr="CHR_USER_ID" access="R·W" label="User ID" value={cfg.userId} onChange={v => set({ userId: v })} placeholder={d.status === 'provision' ? 'Chưa gán — nhập user ID' : ''} mono />
        <AdminField chr="CHR_DEV_TOKEN" access="W" label="Device Token" value={cfg.devToken} onChange={v => set({ devToken: v })} type="password" placeholder="Dán device token" mono />
      </div>

      <button className="press" onClick={() => flash('check', 'var(--green)', 'Đã ghi CHR_COMMIT — robot áp dụng cấu hình')} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, width: '100%', marginTop: 18, height: 50, borderRadius: 14, background: 'var(--purple)', color: '#1a0d33', fontWeight: 700, fontSize: 15 }}>
        <Icon name="check" size={19} color="#1a0d33" strokeWidth={2.4} /> Lưu & áp dụng (CHR_COMMIT)
      </button>
    </Scroll>
  );
}

/* ---- logs ---- */
function SvcLogs({ d, cfg, set, flash }) {
  return (
    <Scroll style={{ padding: '4px 16px 26px' }}>
      <div className="t-cap" style={{ margin: '6px 2px 10px' }}>CHR_LOG_LEVEL</div>
      <div className="card-2" style={{ padding: 12, marginBottom: 14 }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {['debug', 'info', 'warn', 'error'].map(l => {
            const on = cfg.logLevel === l;
            return <button key={l} className="press" onClick={() => { set({ logLevel: l }); flash('check', 'var(--green)', 'log_level = ' + l.toUpperCase()); }} style={{ flex: 1, height: 36, borderRadius: 10, fontSize: 11.5, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.03em', background: on ? 'var(--purple)' : 'var(--bg-1)', color: on ? '#1a0d33' : 'var(--tx-mute)', border: `1px solid ${on ? 'transparent' : 'var(--hairline)'}` }}>{l}</button>;
          })}
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '0 2px 10px' }}>
        <span className="t-cap">LOG HỆ THỐNG · realtime</span>
        <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)' }}>tail · {d.id.slice(-5)}</span>
      </div>
      <div style={{ display: 'grid', gap: 6 }}>
        {LOGS.map((l, i) => {
          const lv = LOG_LEVELS[l.lv];
          return (
            <div key={i} style={{ display: 'flex', gap: 9, alignItems: 'flex-start', padding: '9px 11px', background: 'var(--bg-1)', border: '1px solid var(--hairline)', borderRadius: 10 }}>
              <span style={{ flex: 'none', marginTop: 1, fontSize: 8.5, fontWeight: 800, letterSpacing: '.04em', padding: '2px 5px', borderRadius: 5, color: lv.fill ? '#06121a' : lv.c, background: lv.fill ? lv.c : 'transparent', border: lv.fill ? 'none' : `1px solid ${lv.c}` }}>{l.lv}</span>
              <span className="mono" style={{ flex: 1, minWidth: 0, fontSize: 11.5, color: 'var(--tx-soft)', lineHeight: 1.4, wordBreak: 'break-word' }}>{l.msg}</span>
              <span className="mono" style={{ flex: 'none', fontSize: 10, color: 'var(--tx-faint)' }}>{l.t}</span>
            </div>
          );
        })}
      </div>
    </Scroll>
  );
}

/* ---- firmware / OTA ---- */
function SvcFirmware({ d, flash, confirm }) {
  const latest = '2.2.0';
  const updating = d.status === 'updating';
  const behind = d.fw !== latest;
  return (
    <Scroll style={{ padding: '4px 16px 26px' }}>
      <div className="card" style={{ padding: 16, textAlign: 'center' }}>
        <span style={{ width: 56, height: 56, borderRadius: 16, background: hexA('#B48CFF', .14), display: 'grid', placeItems: 'center', margin: '0 auto 12px' }}><Icon name="cpu" size={28} color="var(--purple)" strokeWidth={1.6} /></span>
        <div className="mono" style={{ fontSize: 22, fontWeight: 700 }}>v{d.fw}</div>
        <div className="t-sub" style={{ marginTop: 2 }}>phân vùng đang chạy · ota_0</div>
        {behind ? (
          <span className="pill" style={{ marginTop: 12, background: hexA('#FFD166', .14), color: 'var(--warm)' }}>Có bản v{latest}</span>
        ) : (
          <span className="pill" style={{ marginTop: 12, background: hexA('#7BE88E', .14), color: 'var(--green)' }}>Đã mới nhất</span>
        )}
      </div>

      {updating && (
        <div className="card" style={{ marginTop: 12, padding: 14, borderColor: hexA('#76B8FF', .3) }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 9 }}>
            <span style={{ fontSize: 13.5, fontWeight: 700, color: 'var(--blue)' }}>Đang nạp OTA → v{latest}</span>
            <span className="mono" style={{ fontSize: 12, fontWeight: 700, color: 'var(--blue)' }}>62%</span>
          </div>
          <div style={{ height: 8, borderRadius: 99, background: 'var(--bg-2)', overflow: 'hidden' }}><div style={{ width: '62%', height: '100%', borderRadius: 99, background: 'var(--blue)' }} /></div>
        </div>
      )}

      <div style={{ display: 'grid', gap: 8, marginTop: 14 }}>
        <button className="press" disabled={!behind || updating} onClick={() => confirm({ title: `Nạp firmware v${latest}?`, body: `Đẩy bản v${latest} qua OTA. Robot khởi động lại sau khi nạp xong (~90 giây).`, cta: 'Bắt đầu nạp', danger: false, onOk: () => flash('download', 'var(--blue)', 'Đã khởi tạo OTA — đang tải manifest') })}
          style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, height: 50, borderRadius: 14, background: (!behind || updating) ? 'var(--bg-3)' : 'var(--purple)', color: (!behind || updating) ? 'var(--tx-faint)' : '#1a0d33', fontWeight: 700, fontSize: 15 }}>
          <Icon name="download" size={19} color={(!behind || updating) ? 'var(--tx-faint)' : '#1a0d33'} strokeWidth={2.2} /> {updating ? 'Đang nạp…' : behind ? `Nạp v${latest}` : 'Đã mới nhất'}
        </button>
        <button className="press" onClick={() => confirm({ title: 'Rollback firmware?', body: 'Quay về phân vùng ota_1 (v2.0.4). Ghi CHR_COMMAND = 0x12.', cta: 'Rollback', danger: false, onOk: () => flash('back', 'var(--warm)', 'Đã yêu cầu rollback về ota_1') })}
          style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, height: 48, borderRadius: 14, background: 'var(--bg-2)', border: '1px solid var(--hairline)', color: 'var(--tx-soft)', fontWeight: 700, fontSize: 14.5 }}>
          <Icon name="back" size={18} color="var(--warm)" /> Rollback về v2.0.4
        </button>
      </div>
    </Scroll>
  );
}

/* ---- reset / danger zone ---- */
function SvcReset({ d, flash, confirm }) {
  return (
    <Scroll style={{ padding: '4px 16px 26px' }}>
      <div className="card" style={{ padding: 14, marginBottom: 14, borderColor: hexA('#FF5B6E', .26), background: hexA('#FF5B6E', .05) }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
          <Icon name="alert" size={17} color="var(--red)" />
          <span style={{ fontSize: 13.5, fontWeight: 700, color: 'var(--red)' }}>Vùng nguy hiểm</span>
        </div>
        <p style={{ fontSize: 12.5, color: 'var(--tx-mute)', margin: '7px 0 0', lineHeight: 1.5 }}>Các lệnh này ghi <span className="mono" style={{ color: 'var(--tx-soft)' }}>CHR_COMMAND</span> và chỉ chạy được ở Level 2. Không hoàn tác được.</p>
      </div>

      <div style={{ display: 'grid', gap: 8 }}>
        <button className="press" onClick={() => confirm({ title: 'Khởi động lại robot?', body: 'Ghi CHR_COMMAND = RESTART (0x01). Luni ngoại tuyến ~20 giây.', cta: 'Khởi động lại', danger: false, onOk: () => flash('refresh', 'var(--cyan)', 'Đã gửi lệnh khởi động lại') })} style={cmdRow('#5BE9FF')}>
          <span style={cmdIcon('#5BE9FF')}><Icon name="refresh" size={19} color="var(--cyan)" /></span>
          <span style={{ flex: 1 }}><span style={cmdTitle()}>Restart <span className="mono" style={cmdCode()}>0x01</span></span><span style={cmdSub()}>Khởi động lại mềm</span></span>
          <Icon name="chevron" size={17} color="var(--tx-faint)" />
        </button>
        {CMD_L2.map(c => {
          const danger = c.c === 'var(--red)';
          const tone = c.c === 'var(--red)' ? '#FF5B6E' : c.c === 'var(--orange)' ? '#FF9D5B' : c.c === 'var(--warm)' ? '#FFD166' : '#76B8FF';
          return (
            <button key={c.code} className="press" onClick={() => confirm({ title: c.label + '?', body: c.sub + '. Ghi CHR_COMMAND = ' + c.code + ' — cần Level 2.', cta: c.label, danger, onOk: () => flash('check', tone, 'Đã gửi ' + c.label + ' (' + c.code + ')') })} style={cmdRow(danger ? '#FF5B6E' : 'var(--hairline)')}>
              <span style={cmdIcon(tone)}><Icon name={c.icon} size={19} color={c.c} /></span>
              <span style={{ flex: 1 }}><span style={cmdTitle(danger)}>{c.label} <span className="mono" style={cmdCode()}>{c.code}</span></span><span style={cmdSub()}>{c.sub}</span></span>
              <Icon name="chevron" size={17} color="var(--tx-faint)" />
            </button>
          );
        })}
      </div>
    </Scroll>
  );
}

/* ---- small style helpers ---- */
function svcBtn(c) {
  return { flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 9, height: 46, borderRadius: 13, background: 'var(--bg-2)', border: '1px solid var(--hairline)', color: c, fontSize: 14, fontWeight: 700 };
}
function cmdRow(borderC) {
  return { display: 'flex', alignItems: 'center', gap: 13, padding: 13, borderRadius: 14, background: 'var(--bg-2)', border: '1px solid ' + (borderC.startsWith('#') ? hexA(borderC, .28) : borderC), width: '100%', textAlign: 'left' };
}
function cmdIcon(tone) {
  return { width: 38, height: 38, borderRadius: 11, background: hexA(tone, .14), display: 'grid', placeItems: 'center', flex: 'none' };
}
function cmdTitle(danger) {
  return { display: 'block', fontWeight: 700, fontSize: 14.5, color: danger ? 'var(--red)' : 'var(--tx)' };
}
function cmdCode() { return { fontSize: 11, color: 'var(--tx-faint)', fontWeight: 600 }; }
function cmdSub() { return { display: 'block', fontSize: 12, color: 'var(--tx-mute)' }; }

Object.assign(window, { AdminDashboard, AdminFleet, AdminService, ADMIN_FLEET, FLEET_STATUS });
