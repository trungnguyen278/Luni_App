/* ============================================================
   Admin BLE Console — level-gated provisioning & maintenance
   Mirrors the real GATT characteristic set:
     Level 0  CHR_DEVICE_INFO (R) · CHR_AUTH_UNLOCK (W)
     Level 1  CHR_SSID · CHR_PASSWORD · CHR_WS_URL · CHR_COMMIT
              CHR_USER_ID · CHR_DEV_TOKEN · CHR_ADMIN_SECRET
              CHR_ADMIN_AUTH · CHR_COMMAND(RESTART)
     Level 2  CHR_DIAG_INFO (R) · CHR_LOG_LEVEL (R/W)
              CHR_COMMAND(FACTORY_RESET · FULL_WIPE · ROLLBACK · CLEAR_USERS)
   ============================================================ */

const DEMO_PIN = '481205';

const ADMIN_DIAG = [
  ['free_heap', '45 032 B'], ['min_free_heap', '38 110 B'], ['uptime', '23g 58p 12s'],
  ['fw_partition', 'ota_0'], ['fw_version', 'v2.1.0'], ['reset_reason', 'POWERON'],
];

const CMD_L2 = [
  { code: '0x10', icon: 'refresh', c: 'var(--orange)', label: 'Factory Reset', sub: 'Xoá Wi‑Fi + token, giữ firmware' },
  { code: '0x11', icon: 'trash',   c: 'var(--red)',    label: 'Full Wipe',     sub: 'Xoá toàn bộ NVS về trạng thái gốc' },
  { code: '0x12', icon: 'back',    c: 'var(--warm)',   label: 'Rollback FW',   sub: 'Quay về phân vùng ota_1 (v2.0.4)' },
  { code: '0x15', icon: 'users',   c: 'var(--blue)',   label: 'Clear Users',   sub: 'Xoá toàn bộ user ID đã gán' },
];

const CHR_C = { R: '#5BE9FF', W: '#FF9D5B', 'R·W': '#7BE88E' };
function ChrTag({ name, access }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)', letterSpacing: '.01em' }}>{name}</span>
      <span style={{ fontSize: 8.5, fontWeight: 800, letterSpacing: '.05em', padding: '2px 5px', borderRadius: 5, color: CHR_C[access], background: hexA(CHR_C[access], .15) }}>{access}</span>
    </span>
  );
}

/* labelled write field with characteristic tag */
function AdminField({ chr, access, label, value, onChange, type = 'text', placeholder, mono }) {
  const [show, setShow] = useS(false);
  const pw = type === 'password';
  return (
    <div className="card-2" style={{ padding: '12px 14px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 9, gap: 8 }}>
        <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--tx-soft)' }}>{label}</span>
        <ChrTag name={chr} access={access} />
      </div>
      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
        <input className={mono ? 'mono' : ''} value={value} onChange={e => onChange(e.target.value)} type={pw && !show ? 'password' : 'text'} placeholder={placeholder}
          style={{ flex: 1, minWidth: 0, height: 42, padding: '0 12px', background: 'var(--bg-1)', border: '1px solid var(--hairline)', borderRadius: 10, color: 'var(--tx)', fontSize: 13.5, outline: 'none' }} />
        {pw && <button className="press" onClick={() => setShow(s => !s)} style={{ width: 42, height: 42, borderRadius: 10, background: 'var(--bg-1)', border: '1px solid var(--hairline)', display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name={show ? 'eyeOff' : 'eye'} size={17} color="var(--tx-mute)" /></button>}
      </div>
    </div>
  );
}

/* ---------------- PIN unlock (CHR_AUTH_UNLOCK) ---------------- */
function PinUnlock({ onUnlock }) {
  const [pin, setPin] = useS('');
  const [err, setErr] = useS(false);
  const [busy, setBusy] = useS(false);
  const ref = React.useRef(null);
  const submit = () => {
    setBusy(true);
    setTimeout(() => {
      if (pin === DEMO_PIN) onUnlock();
      else { setErr(true); setBusy(false); setPin(''); }
    }, 850);
  };
  return (
    <div className="card" style={{ padding: 16, borderColor: err ? hexA('#FF5B6E', .4) : 'var(--hairline)' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4, gap: 8 }}>
        <span style={{ fontSize: 15, fontWeight: 700 }}>Mở khoá Level 1</span>
        <ChrTag name="CHR_AUTH_UNLOCK" access="W" />
      </div>
      <p className="t-sub" style={{ margin: '0 0 14px' }}>Nhập mã PIN 6 số hiển thị trên màn hình Luni để ghép nối.</p>
      <div onClick={() => ref.current && ref.current.focus()} style={{ position: 'relative', display: 'flex', justifyContent: 'space-between', gap: 7 }}>
        <input ref={ref} value={pin} inputMode="numeric" onChange={e => { setErr(false); setPin(e.target.value.replace(/\D/g, '').slice(0, 6)); }}
          style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0, border: 'none', background: 'transparent', cursor: 'pointer' }} />
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} style={{ flex: 1, height: 50, borderRadius: 12, background: 'var(--bg-2)', border: `1.5px solid ${err ? hexA('#FF5B6E', .5) : i === pin.length ? 'var(--cyan)' : 'var(--hairline)'}`, display: 'grid', placeItems: 'center', fontSize: 22, fontWeight: 800 }}>{pin[i] || ''}</div>
        ))}
      </div>
      {err && <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 11, color: 'var(--red)', fontSize: 12.5, fontWeight: 600 }}><Icon name="alert" size={14} color="var(--red)" /> Sai mã PIN — vẫn ở Level 0. Thử lại.</div>}
      <button className="press" disabled={pin.length < 6 || busy} onClick={submit} style={{ width: '100%', marginTop: 14, height: 48, borderRadius: 14, fontWeight: 700, fontSize: 15, background: pin.length < 6 ? 'var(--bg-3)' : 'var(--cyan)', color: pin.length < 6 ? 'var(--tx-faint)' : '#06222b', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
        {busy ? <Spinner color="#06222b" /> : <><Icon name="key" size={18} color={pin.length < 6 ? 'var(--tx-faint)' : '#06222b'} strokeWidth={2.2} /> Xác thực PIN</>}
      </button>
      <div className="t-cap" style={{ textAlign: 'center', marginTop: 11, color: 'var(--tx-faint)' }}>Demo · PIN = {DEMO_PIN}</div>
    </div>
  );
}

/* ---------------- Admin elevation (CHR_ADMIN_SECRET → CHR_ADMIN_AUTH) ---------------- */
function ElevatePanel({ onElevated }) {
  const [secret, setSecret] = useS('');
  const [busy, setBusy] = useS(false);
  const go = () => {
    setBusy(true);
    setTimeout(() => onElevated(), 1600);
  };
  return (
    <div className="card" style={{ padding: 16, background: 'radial-gradient(120% 90% at 50% -10%, rgba(180,140,255,.1), var(--bg-1) 62%)', borderColor: hexA('#B48CFF', .26) }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 11, marginBottom: 4 }}>
        <span style={{ width: 36, height: 36, borderRadius: 11, background: hexA('#B48CFF', .16), display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="shield" size={19} color="var(--purple)" /></span>
        <div style={{ flex: 1 }}><div style={{ fontSize: 15, fontWeight: 700 }}>Nâng quyền Admin · Level 2</div><div className="t-sub">Mở chẩn đoán & lệnh nguy hiểm</div></div>
      </div>
      <p style={{ fontSize: 12.5, color: 'var(--tx-mute)', lineHeight: 1.5, margin: '6px 0 14px' }}>Nhập <b style={{ color: 'var(--tx-soft)' }}>Admin Secret</b> để tạo token HMAC, rồi gửi qua <span className="mono" style={{ color: 'var(--tx-soft)' }}>CHR_ADMIN_AUTH</span>. Nếu hợp lệ, phiên BLE được nâng lên Level 2.</p>
      <AdminField chr="CHR_ADMIN_SECRET" access="W" label="Admin Secret" value={secret} onChange={setSecret} type="password" placeholder="Dán mã bí mật admin" mono />
      <button className="press" disabled={!secret.trim() || busy} onClick={go} style={{ width: '100%', marginTop: 12, height: 48, borderRadius: 14, fontWeight: 700, fontSize: 15, background: !secret.trim() ? 'var(--bg-3)' : 'var(--purple)', color: !secret.trim() ? 'var(--tx-faint)' : '#1a0d33', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
        {busy ? <Spinner color="#1a0d33" /> : <><Icon name="key" size={18} color={!secret.trim() ? 'var(--tx-faint)' : '#1a0d33'} strokeWidth={2.2} /> Tạo & gửi HMAC token</>}
      </button>
    </div>
  );
}

/* ---------------- Level tracker pills ---------------- */
function LevelTrack({ level, maxLevel }) {
  const items = [
    { n: 0, label: 'Công khai' },
    { n: 1, label: 'Người dùng' },
    { n: 2, label: 'Admin' },
  ];
  return (
    <div style={{ display: 'flex', gap: 7 }}>
      {items.map((it) => {
        const allowed = it.n <= maxLevel;
        const on = allowed && level >= it.n;
        const c = it.n === 2 ? '#B48CFF' : it.n === 1 ? '#5BE9FF' : '#7BE88E';
        const icon = on ? 'check' : !allowed ? 'lock' : 'lock';
        return (
          <div key={it.n} style={{ flex: 1, padding: '9px 8px', borderRadius: 12, textAlign: 'center', background: on ? hexA(c, .14) : 'var(--bg-2)', border: `1px solid ${on ? hexA(c, .4) : 'var(--hairline)'}`, opacity: allowed ? 1 : .45, transition: 'all .3s var(--ease)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5 }}>
              <Icon name={icon} size={12} color={on ? c : 'var(--tx-faint)'} strokeWidth={2.4} />
              <span style={{ fontSize: 11, fontWeight: 800, color: on ? c : 'var(--tx-faint)' }}>L{it.n}</span>
            </div>
            <div style={{ fontSize: 10, fontWeight: 600, color: on ? 'var(--tx-soft)' : 'var(--tx-faint)', marginTop: 3 }}>{!allowed ? 'chỉ admin' : it.label}</div>
          </div>
        );
      })}
    </div>
  );
}

/* ---------------- Main console ---------------- */
function AdminBleConsole({ device, update, confirm }) {
  const d = device;
  const [conn, setConn] = useS('connecting'); // connecting | ready
  const [level, setLevel] = useS(0);
  const [notice, setNotice] = useS(null);
  const [logsOpen, setLogsOpen] = useS(false);

  // Tài khoản người dùng thường — chỉ tới được Level 1. Admin dùng bảng điều khiển dịch vụ riêng.
  const maxLevel = 1;

  // network / account fields (Level 1)
  const [ssid, setSsid] = useS('Nha_Cua_Tui_5G');
  const [wpass, setWpass] = useS('');
  const [wsUrl, setWsUrl] = useS('wss://api.luni.vn/ws');
  const [userId, setUserId] = useS('usr_8842a1');
  const [devToken, setDevToken] = useS('');

  React.useEffect(() => {
    const t = setTimeout(() => setConn('ready'), 1500);
    return () => clearTimeout(t);
  }, []);
  React.useEffect(() => {
    if (!notice) return;
    const t = setTimeout(() => setNotice(null), 2600);
    return () => clearTimeout(t);
  }, [notice]);

  const flash = (icon, c, text) => setNotice({ icon, c, text });

  if (conn === 'connecting') {
    return (
      <div style={{ padding: '24px 0 40px', textAlign: 'center' }}>
        <LuniFace emotion="curious" size={116} state="thinking" />
        <div className="t-h3" style={{ marginTop: 18 }}>Đang mở kênh BLE…</div>
        <p className="t-sub" style={{ marginTop: 6 }}>Kết nối tới {d.name} và đọc CHR_DEVICE_INFO</p>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 8, marginTop: 18 }}>
          <Spinner color="var(--cyan)" />
        </div>
      </div>
    );
  }

  return (
    <div style={{ paddingBottom: 16 }}>
      {/* session header */}
      <div className="card" style={{ padding: 14, marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 13 }}>
          <span className="dot" style={{ background: 'var(--green)', boxShadow: '0 0 8px var(--green)', flex: 'none' }} />
          <span style={{ flex: 1, fontSize: 13.5, fontWeight: 700 }}>Đã kết nối BLE</span>
          <span className="mono" style={{ fontSize: 11, color: 'var(--tx-mute)' }}>{d.id}</span>
        </div>
        <div style={{ marginTop: 2 }}><LevelTrack level={level} maxLevel={maxLevel} /></div>
      </div>

      {/* transient write notice */}
      {notice && (
        <div className="glass pop" style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '11px 14px', borderRadius: 13, border: '1px solid var(--hairline-2)', marginBottom: 14 }}>
          <Icon name={notice.icon} size={17} color={notice.c} strokeWidth={2.2} />
          <span style={{ fontSize: 13, fontWeight: 600 }}>{notice.text}</span>
        </div>
      )}

      {/* ---- Level 0 · device info (always readable) ---- */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '0 2px 10px' }}>
        <span className="t-cap">CHR_DEVICE_INFO</span><ChrTag name="" access="R" />
      </div>
      <div className="card-2" style={{ padding: '4px 16px', marginBottom: 4 }}>
        {[['mac', d.id], ['model', d.model], ['version', 'v' + d.fwVersion], ['name', d.name]].map(([k, v], i, a) => (
          <div key={k} style={{ display: 'flex', justifyContent: 'space-between', gap: 12, padding: '11px 0', borderBottom: i < a.length - 1 ? '1px solid var(--hairline)' : 'none' }}>
            <span className="mono" style={{ fontSize: 13, color: 'var(--tx-mute)' }}>{k}</span>
            <span className="mono" style={{ fontSize: 13, fontWeight: 700, textAlign: 'right', wordBreak: 'break-word' }}>{v}</span>
          </div>
        ))}
      </div>

      {/* ---- unlock / Level 1 ---- */}
      <div style={{ marginTop: 18 }}>
        {level < 1 ? <PinUnlock onUnlock={() => { setLevel(1); flash('check', 'var(--green)', 'Đã mở khoá Level 1'); }} /> : (
          <>
            {/* network & server */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '0 2px 10px' }}>
              <span className="t-cap">MẠNG & MÁY CHỦ</span>
              <span className="pill" style={{ height: 20, background: hexA('#5BE9FF', .14), color: 'var(--cyan)' }}>Level 1</span>
            </div>
            <div style={{ display: 'grid', gap: 8 }}>
              <AdminField chr="CHR_SSID" access="R·W" label="Tên Wi‑Fi (SSID)" value={ssid} onChange={setSsid} mono />
              <AdminField chr="CHR_PASSWORD" access="W" label="Mật khẩu Wi‑Fi" value={wpass} onChange={setWpass} type="password" placeholder="Chỉ ghi — không đọc lại được" />
              <AdminField chr="CHR_WS_URL" access="R·W" label="WebSocket URL" value={wsUrl} onChange={setWsUrl} mono />
              <button className="press" onClick={() => flash('check', 'var(--green)', 'Đã ghi CHR_COMMIT — robot đang áp dụng cấu hình')} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, padding: '14px 16px', borderRadius: 14, background: hexA('#5BE9FF', .12), border: '1px solid ' + hexA('#5BE9FF', .3), width: '100%' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: 11 }}><Icon name="check" size={18} color="var(--cyan)" strokeWidth={2.4} /><span style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--cyan)' }}>Lưu & áp dụng cấu hình</span></span>
                <ChrTag name="CHR_COMMIT" access="W" />
              </button>
            </div>

            {/* account binding */}
            <div className="t-cap" style={{ margin: '20px 2px 10px' }}>GÁN TÀI KHOẢN</div>
            <div style={{ display: 'grid', gap: 8 }}>
              <AdminField chr="CHR_USER_ID" access="R·W" label="User ID" value={userId} onChange={setUserId} mono />
              <AdminField chr="CHR_DEV_TOKEN" access="W" label="Device Token" value={devToken} onChange={setDevToken} type="password" placeholder="Dán device token" mono />
            </div>

            {/* level 1 command */}
            <div className="t-cap" style={{ margin: '20px 2px 10px' }}>LỆNH · CHR_COMMAND</div>
            <button className="press" onClick={() => confirm({ title: 'Khởi động lại robot?', body: 'Ghi CHR_COMMAND = RESTART (0x01). Luni sẽ ngoại tuyến khoảng 20 giây.', cta: 'Khởi động lại' })} style={{ display: 'flex', alignItems: 'center', gap: 13, padding: 13, borderRadius: 14, background: 'var(--bg-2)', border: '1px solid var(--hairline)', width: '100%', textAlign: 'left' }}>
              <span style={{ width: 38, height: 38, borderRadius: 11, background: hexA('#5BE9FF', .14), display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="refresh" size={19} color="var(--cyan)" /></span>
              <span style={{ flex: 1 }}><span style={{ display: 'block', fontWeight: 700, fontSize: 14.5 }}>Restart <span className="mono" style={{ fontSize: 11, color: 'var(--tx-faint)', fontWeight: 600 }}>0x01</span></span><span style={{ display: 'block', fontSize: 12, color: 'var(--tx-mute)' }}>Lệnh duy nhất được phép ở Level 1</span></span>
              <Icon name="chevron" size={17} color="var(--tx-faint)" />
            </button>

            {/* elevate — khoá với tài khoản người dùng */}
            <div className="t-cap" style={{ margin: '22px 2px 10px' }}>NÂNG QUYỀN</div>
            <LockedElevateCard />
          </>
        )}
      </div>

      {/* ---- Level 2 ---- */}
      {level >= 2 && (
        <div className="screen-anim" style={{ marginTop: 24 }}>
          <div style={{ height: 1, background: 'var(--hairline)', margin: '0 0 20px' }} />

          {/* diag */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '0 2px 10px' }}>
            <span className="t-cap">CHR_DIAG_INFO</span><ChrTag name="" access="R" />
          </div>
          <div className="card-2" style={{ padding: '4px 16px' }}>
            {ADMIN_DIAG.map(([k, v], i) => (
              <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: i < ADMIN_DIAG.length - 1 ? '1px solid var(--hairline)' : 'none' }}>
                <span className="mono" style={{ fontSize: 12.5, color: 'var(--tx-mute)' }}>{k}</span>
                <span className="mono" style={{ fontSize: 12.5, fontWeight: 700 }}>{v}</span>
              </div>
            ))}
          </div>

          {/* log level */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '20px 2px 10px' }}>
            <span className="t-cap">CHR_LOG_LEVEL</span><ChrTag name="" access="R·W" />
          </div>
          <div className="card-2" style={{ padding: 14 }}>
            <div style={{ display: 'flex', gap: 6 }}>
              {['debug', 'info', 'warn', 'error'].map(l => {
                const on = d.config.logLevel === l;
                return <button key={l} className="press" onClick={() => { update({ config: { ...d.config, logLevel: l } }); flash('check', 'var(--green)', 'Đã ghi log level = ' + l.toUpperCase() + ' (NVS)'); }} style={{ flex: 1, height: 38, borderRadius: 10, fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.03em', background: on ? 'var(--cyan)' : 'var(--bg-1)', color: on ? '#06222b' : 'var(--tx-mute)', border: `1px solid ${on ? 'transparent' : 'var(--hairline)'}` }}>{l}</button>;
              })}
            </div>
            <button className="press" onClick={() => setLogsOpen(o => !o)} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7, width: '100%', marginTop: 12, padding: '8px 0', color: 'var(--tx-mute)', fontSize: 12.5, fontWeight: 600 }}>
              <Icon name="logs" size={15} color="var(--tx-mute)" /> {logsOpen ? 'Ẩn' : 'Xem'} log hệ thống realtime
              <Icon name={logsOpen ? 'chevronDown' : 'chevron'} size={14} color="var(--tx-faint)" />
            </button>
            {logsOpen && (
              <div className="screen-anim" style={{ display: 'grid', gap: 6, marginTop: 6 }}>
                {LOGS.slice(0, 6).map((l, i) => {
                  const lv = LOG_LEVELS[l.lv];
                  return (
                    <div key={i} style={{ display: 'flex', gap: 9, alignItems: 'flex-start', padding: '8px 10px', background: 'var(--bg-1)', borderRadius: 9 }}>
                      <span style={{ flex: 'none', marginTop: 1, fontSize: 8.5, fontWeight: 800, letterSpacing: '.04em', padding: '2px 5px', borderRadius: 5, color: lv.fill ? '#06121a' : lv.c, background: lv.fill ? lv.c : 'transparent', border: lv.fill ? 'none' : `1px solid ${lv.c}` }}>{l.lv}</span>
                      <span className="mono" style={{ flex: 1, minWidth: 0, fontSize: 11.5, color: 'var(--tx-soft)', lineHeight: 1.4, wordBreak: 'break-word' }}>{l.msg}</span>
                      <span className="mono" style={{ flex: 'none', fontSize: 10, color: 'var(--tx-faint)' }}>{l.t}</span>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* dangerous commands */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '22px 2px 10px' }}>
            <span className="t-cap" style={{ color: 'var(--red)' }}>CHR_COMMAND · VÙNG NGUY HIỂM</span>
            <Icon name="alert" size={14} color="var(--red)" />
          </div>
          <div style={{ display: 'grid', gap: 8 }}>
            {CMD_L2.map(c => {
              const danger = c.c === 'var(--red)';
              const tone = c.c === 'var(--red)' ? '#FF5B6E' : c.c === 'var(--orange)' ? '#FF9D5B' : c.c === 'var(--warm)' ? '#FFD166' : '#76B8FF';
              return (
                <button key={c.code} className="press" onClick={() => confirm({ title: c.label + '?', body: c.sub + '. Ghi CHR_COMMAND = ' + c.code + ' — cần quyền Level 2.', cta: c.label, danger })} style={{ display: 'flex', alignItems: 'center', gap: 13, padding: 13, borderRadius: 14, background: 'var(--bg-2)', border: '1px solid ' + (danger ? hexA('#FF5B6E', .28) : 'var(--hairline)'), width: '100%', textAlign: 'left' }}>
                  <span style={{ width: 38, height: 38, borderRadius: 11, background: hexA(tone, .14), display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name={c.icon} size={19} color={c.c} /></span>
                  <span style={{ flex: 1 }}><span style={{ display: 'block', fontWeight: 700, fontSize: 14.5, color: danger ? 'var(--red)' : 'var(--tx)' }}>{c.label} <span className="mono" style={{ fontSize: 11, color: 'var(--tx-faint)', fontWeight: 600 }}>{c.code}</span></span><span style={{ display: 'block', fontSize: 12, color: 'var(--tx-mute)' }}>{c.sub}</span></span>
                  <Icon name="chevron" size={17} color="var(--tx-faint)" />
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

/* ---------------- Locked elevation (regular user cannot reach Level 2) ---------------- */
function LockedElevateCard() {
  return (
    <div className="card" style={{ padding: 16, borderColor: 'var(--hairline)', opacity: .96 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 11, marginBottom: 4 }}>
        <span style={{ width: 36, height: 36, borderRadius: 11, background: 'var(--bg-2)', border: '1px solid var(--hairline)', display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="lock" size={18} color="var(--tx-mute)" /></span>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--tx-soft)' }}>Level 2 đã khoá</div>
          <div className="t-sub">Chỉ tài khoản Admin mới nâng được quyền</div>
        </div>
      </div>
      <p style={{ fontSize: 12.5, color: 'var(--tx-mute)', lineHeight: 1.5, margin: '6px 0 0' }}>Vai trò hiện tại là <b style={{ color: 'var(--cyan)' }}>Người dùng</b> — chỉ thao tác được đến Level 1. Chẩn đoán và lệnh nguy hiểm (<span className="mono" style={{ color: 'var(--tx-soft)' }}>factory_reset · full_wipe</span>) cần quyền Admin. Đổi sang <b style={{ color: 'var(--purple)' }}>Admin</b> ở công tắc trên để xem luồng đầy đủ.</p>
    </div>
  );
}

Object.assign(window, { AdminBleConsole, PinUnlock, ElevatePanel, LockedElevateCard, AdminField, ChrTag, LevelTrack, ADMIN_DIAG, CMD_L2 });
