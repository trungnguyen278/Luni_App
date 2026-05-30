/* ============================================================
   Pairing — BLE wizard: scan → connect → PIN → wifi → server → name → provision → done
   ============================================================ */
const PAIR_STEPS = ['scan', 'connect', 'pin', 'wifi', 'server', 'name', 'provision', 'done'];

const FOUND_DEVICES = [
  { id: 'AA:BB:CC:DD:EE:07', name: 'Luni-07A3', rssi: -48, model: 'luni_v2_s3c5' },
  { id: 'AA:BB:CC:DD:EE:12', name: 'Luni-12F9', rssi: -71, model: 'luni_v2_s3c5' },
];
const WIFI_NETS = [
  { ssid: 'Nha_Cua_Tui_5G', rssi: -41, lock: true },
  { ssid: 'Luni_Office', rssi: -58, lock: true },
  { ssid: 'TP-Link_Guest', rssi: -67, lock: false },
  { ssid: 'VNPT-Home', rssi: -79, lock: true },
];

function SignalBars({ rssi, size = 16, color = 'var(--tx-soft)' }) {
  const lvl = rssi > -55 ? 4 : rssi > -67 ? 3 : rssi > -78 ? 2 : 1;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'flex-end', gap: 2, height: size }}>
      {[1, 2, 3, 4].map(i => (
        <span key={i} style={{ width: 3, height: `${i * 25}%`, borderRadius: 1, background: i <= lvl ? color : 'var(--bg-3)' }} />
      ))}
    </span>
  );
}

function StepDots({ idx, total }) {
  return (
    <div style={{ display: 'flex', gap: 6, padding: '0 18px 4px' }}>
      {Array.from({ length: total }).map((_, i) => (
        <span key={i} style={{ flex: 1, height: 4, borderRadius: 99, background: i <= idx ? 'var(--cyan)' : 'var(--bg-3)', transition: 'background .3s var(--ease)', boxShadow: i === idx ? '0 0 8px var(--cyan)' : 'none' }} />
      ))}
    </div>
  );
}

function PairBtn({ children, onClick, disabled, ghost }) {
  return <button className={ghost ? 'cta-ghost' : 'cta'} disabled={disabled} onClick={onClick}>{children}</button>;
}

function PairingFlow({ onCancel, onComplete }) {
  const [step, setStep] = useS('scan');
  const [scanList, setScanList] = useS([]);
  const [picked, setPicked] = useS(null);
  const [pin, setPin] = useS('');
  const [wifi, setWifi] = useS(null);
  const [wpass, setWpass] = useS('');
  const [server, setServer] = useS('wss://api.luni.vn/ws');
  const [autoServer, setAutoServer] = useS(true);
  const [name, setName] = useS('Luni');
  const [loc, setLoc] = useS('Phòng khách');
  const [prog, setProg] = useS(0);
  const idx = PAIR_STEPS.indexOf(step);

  // scanning reveal
  React.useEffect(() => {
    if (step !== 'scan') return;
    setScanList([]);
    const t1 = setTimeout(() => setScanList([FOUND_DEVICES[0]]), 1100);
    const t2 = setTimeout(() => setScanList(FOUND_DEVICES), 2600);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [step]);

  // connect auto-advance
  React.useEffect(() => {
    if (step !== 'connect') return;
    const t = setTimeout(() => setStep('pin'), 2200);
    return () => clearTimeout(t);
  }, [step]);

  // pin auto-demo fill
  React.useEffect(() => {
    if (step !== 'pin') return;
    let i = 0; const code = '481-205'.replace('-', '');
    const iv = setInterval(() => { i++; setPin(code.slice(0, i)); if (i >= 6) { clearInterval(iv); setTimeout(() => setStep('wifi'), 600); } }, 320);
    return () => clearInterval(iv);
  }, [step]);

  // provisioning sequence
  React.useEffect(() => {
    if (step !== 'provision') return;
    setProg(0);
    const iv = setInterval(() => setProg(p => {
      if (p >= PROVISION_STEPS.length) { clearInterval(iv); setTimeout(() => setStep('done'), 700); return p; }
      return p + 1;
    }), 950);
    return () => clearInterval(iv);
  }, [step]);

  const finish = () => onComplete({
    id: picked?.id || 'AA:BB:CC:DD:EE:07', name, location: loc, city: 'Hà Nội',
    model: 'luni_v2_s3c5', fwVersion: '2.1.0', online: true, batteryPercent: 96, charging: false,
    rssi: picked?.rssi || -48, emotion: 'happy', scene: 'home', config: { volume: 60, brightness: 100, logLevel: 'info', autoOta: true },
  });

  return (
    <>
      <TopBar
        title={step === 'done' ? '' : 'Ghép nối Luni'}
        onBack={step === 'done' ? null : onCancel}
        right={step !== 'done' && <span className="t-cap" style={{ paddingRight: 12 }}>{idx + 1}/7</span>}
        transparent
      />
      {step !== 'done' && <StepDots idx={idx} total={7} />}

      <Scroll style={{ padding: '0 22px 26px' }}>
        <div className="screen-anim" key={step}>

          {step === 'scan' && (<>
            <div style={{ display: 'grid', placeItems: 'center', padding: '26px 0 6px' }}>
              <div style={{ position: 'relative', width: 150, height: 150, display: 'grid', placeItems: 'center' }}>
                {[0, 1, 2].map(i => <div key={i} style={{ position: 'absolute', inset: 0, borderRadius: '50%', border: '2px solid var(--cyan)', animation: `radar 2.4s ${i * 0.8}s ease-out infinite` }} />)}
                <div style={{ width: 72, height: 72, borderRadius: '50%', background: hexA('#5BE9FF', .14), display: 'grid', placeItems: 'center', border: '1px solid ' + hexA('#5BE9FF', .4) }}>
                  <Icon name="bluetooth" size={32} color="var(--cyan)" strokeWidth={2} />
                </div>
              </div>
            </div>
            <h1 className="t-h2" style={{ textAlign: 'center', margin: '10px 0 4px' }}>Đang tìm Luni gần đây…</h1>
            <p className="t-sub" style={{ textAlign: 'center', margin: '0 0 22px' }}>Đảm bảo robot đã bật và ở chế độ ghép nối (đèn xanh nhấp nháy).</p>
            <div style={{ display: 'grid', gap: 10 }}>
              {scanList.length === 0 && [0, 1].map(i => <div key={i} className="shim" style={{ height: 70, borderRadius: 16 }} />)}
              {scanList.map(d => (
                <button key={d.id} className="press pop" onClick={() => { setPicked(d); setStep('connect'); }} style={{
                  display: 'flex', alignItems: 'center', gap: 13, padding: 14, borderRadius: 16, textAlign: 'left',
                  background: 'var(--bg-1)', border: '1px solid var(--hairline)', width: '100%',
                }}>
                  <span style={{ width: 46, height: 46, borderRadius: 13, background: hexA('#5BE9FF', .1), display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="speaker" size={22} color="var(--cyan)" /></span>
                  <span style={{ flex: 1, minWidth: 0 }}>
                    <span style={{ display: 'block', fontWeight: 700, fontSize: 15 }}>{d.name}</span>
                    <span className="mono" style={{ display: 'block', fontSize: 11.5, color: 'var(--tx-mute)' }}>{d.id}</span>
                  </span>
                  <SignalBars rssi={d.rssi} />
                  <Icon name="chevron" size={18} color="var(--tx-faint)" />
                </button>
              ))}
            </div>
          </>)}

          {step === 'connect' && <CenterStep emotion="curious" title={`Đang kết nối ${picked?.name || 'Luni'}…`} sub="Thiết lập kênh BLE bảo mật và đọc thông tin thiết bị." showSpin info={[['Model', 'luni_v2_s3c5'], ['Firmware', 'v2.1.0'], ['MAC', picked?.id]]} />}

          {step === 'pin' && (<>
            <CenterStep emotion="alert" title="Nhập mã PIN" sub="Mã gồm 6 số đang hiển thị trên màn hình của Luni." />
            <div style={{ display: 'flex', justifyContent: 'center', gap: 9, margin: '6px 0 16px' }}>
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} style={{ width: 42, height: 54, borderRadius: 13, background: 'var(--bg-2)', border: `1.5px solid ${i === pin.length ? 'var(--cyan)' : 'var(--hairline)'}`, display: 'grid', placeItems: 'center', fontSize: 24, fontWeight: 800 }}>{pin[i] || ''}</div>
              ))}
            </div>
            <p className="t-sub" style={{ textAlign: 'center' }}>Đang xác thực Level 1…</p>
          </>)}

          {step === 'wifi' && (<>
            <h1 className="t-h2" style={{ margin: '22px 0 4px' }}>Kết nối Wi‑Fi</h1>
            <p className="t-sub" style={{ margin: '0 0 18px' }}>Chọn mạng để Luni lên mạng và đồng bộ với máy chủ.</p>
            {!wifi ? (
              <div style={{ display: 'grid', gap: 8 }}>
                {WIFI_NETS.map(n => (
                  <button key={n.ssid} className="press" onClick={() => setWifi(n)} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '13px 14px', borderRadius: 14, background: 'var(--bg-1)', border: '1px solid var(--hairline)', width: '100%', textAlign: 'left' }}>
                    <Icon name="wifi" size={20} color="var(--cyan)" />
                    <span style={{ flex: 1, fontWeight: 600, fontSize: 14.5 }}>{n.ssid}</span>
                    {n.lock && <Icon name="lock" size={15} color="var(--tx-faint)" />}
                    <SignalBars rssi={n.rssi} />
                  </button>
                ))}
                <button className="press" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: 13, color: 'var(--tx-mute)', fontSize: 14, fontWeight: 600 }}><Icon name="refresh" size={16} /> Quét lại</button>
              </div>
            ) : (
              <div className="pop">
                <div className="card-2" style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 14, marginBottom: 16 }}>
                  <Icon name="wifi" size={20} color="var(--cyan)" />
                  <span style={{ flex: 1, fontWeight: 700 }}>{wifi.ssid}</span>
                  <button className="press" onClick={() => { setWifi(null); setWpass(''); }} style={{ color: 'var(--cyan)', fontSize: 13, fontWeight: 700 }}>Đổi</button>
                </div>
                <TextField icon="lock" label="Mật khẩu Wi‑Fi" value={wpass} onChange={setWpass} type="password" placeholder="Nhập mật khẩu" />
                <PairBtn onClick={() => setStep('server')} disabled={wifi.lock && wpass.length < 1}><span>Tiếp tục</span><Icon name="chevron" size={20} color="#04222b" strokeWidth={2.4} /></PairBtn>
              </div>
            )}
          </>)}

          {step === 'server' && (<>
            <h1 className="t-h2" style={{ margin: '22px 0 4px' }}>Máy chủ Luni</h1>
            <p className="t-sub" style={{ margin: '0 0 18px' }}>Luni sẽ kết nối tới máy chủ này để xử lý hội thoại và realtime.</p>
            <div className="card" style={{ padding: 16, marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: 10, fontWeight: 600, fontSize: 14.5 }}><Icon name="sparkle" size={18} color="var(--cyan)" /> Tự động (khuyến nghị)</span>
                <Toggle on={autoServer} onChange={setAutoServer} />
              </div>
              <p className="t-sub" style={{ margin: '8px 0 0' }}>Dùng máy chủ chính thức của Luni.</p>
            </div>
            <div style={{ opacity: autoServer ? .45 : 1, transition: 'opacity .2s', pointerEvents: autoServer ? 'none' : 'auto' }}>
              <TextField icon="globe" label="Địa chỉ máy chủ (WS_URL)" value={server} onChange={setServer} placeholder="wss://…" />
            </div>
            <PairBtn onClick={() => setStep('name')}><span>Tiếp tục</span><Icon name="chevron" size={20} color="#04222b" strokeWidth={2.4} /></PairBtn>
          </>)}

          {step === 'name' && (<>
            <div style={{ display: 'grid', placeItems: 'center', padding: '18px 0 2px' }}><LuniFace emotion="happy" size={120} /></div>
            <h1 className="t-h2" style={{ textAlign: 'center', margin: '12px 0 4px' }}>Đặt tên cho bé</h1>
            <p className="t-sub" style={{ textAlign: 'center', margin: '0 0 20px' }}>Bạn sẽ thấy tên này ở màn hình chính.</p>
            <TextField icon="sparkle" label="Tên robot" value={name} onChange={setName} placeholder="Luni" />
            <div className="t-cap" style={{ margin: '16px 4px 8px' }}>VỊ TRÍ</div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {['Phòng khách', 'Phòng ngủ', 'Bàn làm việc', 'Bếp', 'Phòng trẻ'].map(l => (
                <button key={l} className="press" onClick={() => setLoc(l)} style={{ height: 36, padding: '0 14px', borderRadius: 99, fontSize: 13.5, fontWeight: 600, background: loc === l ? 'var(--cyan)' : 'var(--bg-2)', color: loc === l ? '#06222b' : 'var(--tx-soft)', border: `1px solid ${loc === l ? 'transparent' : 'var(--hairline)'}` }}>{l}</button>
              ))}
            </div>
            <PairBtn onClick={() => setStep('provision')}><Icon name="check" size={20} color="#04222b" strokeWidth={2.6} /> Hoàn tất ghép nối</PairBtn>
          </>)}

          {step === 'provision' && (<>
            <CenterStep emotion="calm" title="Đang thiết lập…" sub="Ghi cấu hình vào Luni và đăng ký với máy chủ." showSpin />
            <div style={{ display: 'grid', gap: 4, marginTop: 8 }}>
              {PROVISION_STEPS.map((s, i) => {
                const state = i < prog ? 'done' : i === prog ? 'active' : 'wait';
                return (
                  <div key={s} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 14px', borderRadius: 13, background: state === 'active' ? 'var(--bg-2)' : 'transparent', opacity: state === 'wait' ? .4 : 1, transition: 'all .3s' }}>
                    <span style={{ width: 24, height: 24, borderRadius: '50%', display: 'grid', placeItems: 'center', background: state === 'done' ? hexA('#7BE88E', .16) : 'var(--bg-3)', flex: 'none' }}>
                      {state === 'done' ? <Icon name="check" size={15} color="var(--green)" strokeWidth={2.6} /> : state === 'active' ? <Spinner size={14} color="var(--cyan)" /> : <span style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--tx-faint)' }} />}
                    </span>
                    <span style={{ fontSize: 14, fontWeight: 600, color: state === 'wait' ? 'var(--tx-mute)' : 'var(--tx)' }}>{s}</span>
                  </div>
                );
              })}
            </div>
          </>)}

          {step === 'done' && (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', paddingTop: 40 }}>
              <div style={{ position: 'relative' }}>
                <div style={{ position: 'absolute', inset: '-30%', borderRadius: '50%', background: 'radial-gradient(circle, rgba(123,232,142,.25), transparent 65%)' }} />
                <LuniFace emotion="happy" size={170} />
              </div>
              <h1 className="t-h1" style={{ margin: '28px 0 8px' }}>Tuyệt vời! 🎉</h1>
              <p className="t-body" style={{ color: 'var(--tx-mute)', maxWidth: 270, margin: '0 0 6px' }}><b style={{ color: 'var(--tx)' }}>{name}</b> đã trực tuyến và sẵn sàng trò chuyện.</p>
              <div className="pill" style={{ background: hexA('#7BE88E', .14), color: 'var(--green)', marginBottom: 30 }}><span className="dot" style={{ background: 'var(--green)' }} /> Đã xác minh kết nối máy chủ</div>
              <button className="cta" onClick={finish} style={{ maxWidth: 300 }}>Mở bảng điều khiển <Icon name="chevron" size={20} color="#04222b" strokeWidth={2.4} /></button>
            </div>
          )}
        </div>
      </Scroll>
    </>
  );
}

const PROVISION_STEPS = ['Ghi thông tin Wi‑Fi', 'Tạo device token', 'Đăng ký với máy chủ', 'Ghi URL & admin secret', 'Khởi động lại robot', 'Xác minh trực tuyến'];

function CenterStep({ emotion, title, sub, showSpin, info }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: '30px 0 14px' }}>
      <LuniFace emotion={emotion} size={130} state={showSpin ? 'thinking' : 'idle'} />
      <h1 className="t-h2" style={{ margin: '22px 0 6px' }}>{title}</h1>
      <p className="t-sub" style={{ maxWidth: 280, margin: 0 }}>{sub}</p>
      {info && (
        <div className="card-2" style={{ width: '100%', marginTop: 20, padding: '4px 16px' }}>
          {info.map(([k, v]) => (
            <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '11px 0', borderBottom: '1px solid var(--hairline)', fontSize: 14 }}>
              <span style={{ color: 'var(--tx-mute)' }}>{k}</span><span className="mono" style={{ fontWeight: 700 }}>{v}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

Object.assign(window, { PairingFlow, SignalBars, StepDots, CenterStep, FOUND_DEVICES, WIFI_NETS });
