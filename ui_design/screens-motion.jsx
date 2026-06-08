/* ============================================================
   Motion tab — physical control for the legged + camera variant
   (luni_v3_walk_cam): photo camera (STILL only, no video),
   4 leg motors (2 per leg), 2 arm motors (1 per arm).
   ============================================================ */

/* ---- leg motor pose targets per drive direction (4 motors, degrees) ----
   order: [chân trái·hông, chân trái·gối, chân phải·hông, chân phải·gối] */
const LEG_POSE = {
  stop:  [90, 90, 90, 90],
  up:    [64, 116, 116, 64],   // tiến
  down:  [116, 64, 64, 116],   // lùi
  left:  [58, 120, 98, 82],    // quay trái
  right: [98, 82, 58, 120],    // quay phải
};
const DIR_VI = { stop: 'Đứng yên', up: 'Tiến tới', down: 'Lùi lại', left: 'Quay trái', right: 'Quay phải' };

const MOTOR_META = [
  { id: 'M1', part: 'leg', name: 'Chân trái', joint: 'Hông', leg: 0 },
  { id: 'M2', part: 'leg', name: 'Chân trái', joint: 'Gối', leg: 1 },
  { id: 'M3', part: 'leg', name: 'Chân phải', joint: 'Hông', leg: 2 },
  { id: 'M4', part: 'leg', name: 'Chân phải', joint: 'Gối', leg: 3 },
  { id: 'M5', part: 'arm', name: 'Tay trái', joint: 'Vai', key: 'armL' },
  { id: 'M6', part: 'arm', name: 'Tay phải', joint: 'Vai', key: 'armR' },
];
const MOTOR_TEMP = [38, 36, 39, 37, 34, 35]; // °C seed per motor

/* striped placeholder standing in for a still captured by the robot camera */
function PhotoFrame({ tone = '#5BE9FF', res = '1600×1200', big = false, viewfinder = false, label = 'ẢNH ROBOT' }) {
  return (
    <div style={{
      position: 'relative', width: '100%', height: '100%', overflow: 'hidden',
      background: `repeating-linear-gradient(125deg, ${hexA(tone, .17)} 0 11px, ${hexA(tone, .055)} 11px 22px), var(--bg-2)`,
      display: 'grid', placeItems: 'center',
    }}>
      {/* faint rule-of-thirds */}
      <div style={{ position: 'absolute', inset: 0, opacity: viewfinder ? .5 : .22, pointerEvents: 'none' }}>
        <div style={{ position: 'absolute', left: '33.33%', top: 0, bottom: 0, width: 1, background: hexA('#EAF0FF', .18) }} />
        <div style={{ position: 'absolute', left: '66.66%', top: 0, bottom: 0, width: 1, background: hexA('#EAF0FF', .18) }} />
        <div style={{ position: 'absolute', top: '33.33%', left: 0, right: 0, height: 1, background: hexA('#EAF0FF', .18) }} />
        <div style={{ position: 'absolute', top: '66.66%', left: 0, right: 0, height: 1, background: hexA('#EAF0FF', .18) }} />
      </div>
      <div style={{ textAlign: 'center', lineHeight: 1.4 }}>
        <Icon name="image" size={big ? 30 : 17} color={hexA(tone, .8)} strokeWidth={1.6} style={{ margin: '0 auto' }} />
        {big && <div className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)', marginTop: 7, letterSpacing: '.08em' }}>{label} · {res}</div>}
      </div>
    </div>
  );
}

function MotionTab({ device, update }) {
  const d = device;
  const cfg = d.config;
  const off = !d.online;
  const caps = d.caps || {};

  const [dir, setDir] = useS('stop');
  const [flash, setFlash] = useS(false);
  const [shots, setShots] = useS([
    { id: 3, t: '12:02', tone: '#FFD166' },
    { id: 2, t: '11:47', tone: '#76B8FF' },
    { id: 1, t: '09:30', tone: '#7BE88E' },
  ]);
  const [flashMode, setFlashMode] = useS('auto'); // off | auto | on
  const [timer, setTimer] = useS(0);              // 0 | 3 | 10 (s)
  const [view, setView] = useS(null);             // photo opened in sheet
  const counter = _useRef(4);

  const legAngles = LEG_POSE[dir] || LEG_POSE.stop;
  const moving = dir !== 'stop';

  const drive = (nd) => {
    if (off) return;
    setDir(nd);
    window.luniToast(nd === 'stop' ? 'Đã dừng' : DIR_VI[nd], nd === 'stop'
      ? { icon: 'stop', color: 'var(--orange)' } : { icon: 'walk', color: 'var(--cyan)' });
  };

  const capture = () => {
    if (off) return;
    if (flashMode !== 'off') { setFlash(true); setTimeout(() => setFlash(false), 320); }
    const fire = () => {
      const id = counter.current++;
      const tones = ['#5BE9FF', '#FF6B9D', '#FFD166', '#7BE88E', '#B48CFF', '#FF9D5B'];
      setShots(s => [{ id, t: 'vừa xong', tone: tones[id % tones.length] }, ...s].slice(0, 12));
      window.luniToast('Đã chụp 1 ảnh', { icon: 'camera', color: 'var(--cyan)' });
    };
    timer ? setTimeout(fire, timer * 90) : fire();
  };

  const setArm = (key, v) => update({ config: { ...cfg, [key]: v } });
  const gesture = (label, l, r, icon) => {
    if (off) return;
    update({ config: { ...cfg, armL: l, armR: r } });
    window.luniToast(label, { icon, color: 'var(--cyan)' });
  };

  return (
    <>
    <Scroll style={{ padding: '14px 18px 30px' }}>

      {/* live posture strip */}
      <div className="card" style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '13px 16px', background: `linear-gradient(120deg, ${hexA('#5BE9FF', moving && !off ? .12 : .05)}, var(--bg-1))`, borderColor: moving && !off ? hexA('#5BE9FF', .26) : 'var(--hairline)' }}>
        <span style={{ width: 46, height: 46, borderRadius: 14, background: hexA('#5BE9FF', .14), display: 'grid', placeItems: 'center', flex: 'none', boxShadow: moving && !off ? '0 0 16px rgba(91,233,255,.3)' : 'none' }}>
          <Icon name="walk" size={23} color={off ? 'var(--tx-faint)' : 'var(--cyan)'} strokeWidth={1.9} style={{ animation: moving && !off ? 'floatY 1s ease-in-out infinite' : 'none' }} />
        </span>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="t-cap">CƠ THỂ ROBOT</div>
          <div className="t-h3" style={{ color: off ? 'var(--tx-mute)' : (moving ? 'var(--cyan)' : 'var(--tx)'), marginTop: 1 }}>{off ? 'Ngoại tuyến' : DIR_VI[dir]}</div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div className="mono" style={{ fontSize: 11, color: 'var(--tx-faint)' }}>{caps.legMotors + caps.armMotors} động cơ</div>
          <div className="mono" style={{ fontSize: 11, color: 'var(--tx-faint)', marginTop: 2 }}>{d.model}</div>
        </div>
      </div>

      {/* ============ CAMERA — STILL ONLY ============ */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '22px 4px 10px' }}>
        <span className="t-over">Camera</span>
        <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)' }}>ws · camera_capture</span>
      </div>

      <div className="card" style={{ padding: 12, opacity: off ? .55 : 1, pointerEvents: off ? 'none' : 'auto' }}>
        {/* viewfinder = the last still (no live video feed exists) */}
        <div style={{ position: 'relative', borderRadius: 14, overflow: 'hidden', aspectRatio: '4 / 3', border: '1px solid var(--hairline-2)' }}>
          <PhotoFrame tone={shots[0] ? shots[0].tone : '#5BE9FF'} big viewfinder label="ẢNH GẦN NHẤT" />
          {/* corner brackets */}
          {[['8px', '8px', '', ''], ['', '8px', '8px', ''], ['8px', '', '', '8px'], ['', '', '8px', '8px']].map((c, i) => (
            <span key={i} style={{ position: 'absolute', top: c[0] || 'auto', left: c[1] || 'auto', bottom: c[2] || 'auto', right: c[3] || 'auto', width: 16, height: 16, borderTop: c[0] ? '2px solid rgba(234,240,255,.45)' : 'none', borderLeft: c[1] ? '2px solid rgba(234,240,255,.45)' : 'none', borderBottom: c[2] ? '2px solid rgba(234,240,255,.45)' : 'none', borderRight: c[3] ? '2px solid rgba(234,240,255,.45)' : 'none', borderRadius: 3 }} />
          ))}
          <span className="pill" style={{ position: 'absolute', top: 10, left: 10, height: 22, background: 'rgba(5,7,13,.62)', color: 'var(--tx-soft)' }}>
            <Icon name="image" size={12} color="var(--cyan)" /> Ảnh tĩnh
          </span>
          <span className="mono" style={{ position: 'absolute', bottom: 10, right: 10, fontSize: 10, color: 'var(--tx-soft)', background: 'rgba(5,7,13,.62)', padding: '3px 7px', borderRadius: 6 }}>{shots[0] ? shots[0].t : '—'}</span>
          {/* flash overlay */}
          {flash && <div style={{ position: 'absolute', inset: 0, background: '#f0f4ff', animation: 'popIn .12s ease', opacity: .92 }} />}
        </div>

        {/* capture controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 12 }}>
          <CamChip icon="flash" label={flashMode === 'off' ? 'Tắt đèn' : flashMode === 'auto' ? 'Đèn tự động' : 'Bật đèn'} active={flashMode !== 'off'} onClick={() => setFlashMode(m => m === 'off' ? 'auto' : m === 'auto' ? 'on' : 'off')} />
          <CamChip icon="clock" label={timer ? `Hẹn ${timer}s` : 'Không hẹn'} active={!!timer} onClick={() => setTimer(t => t === 0 ? 3 : t === 3 ? 10 : 0)} />
          <button className="press" onClick={capture} aria-label="Chụp ảnh" style={{ marginLeft: 'auto', width: 60, height: 60, borderRadius: '50%', background: 'var(--cyan)', display: 'grid', placeItems: 'center', flex: 'none', boxShadow: '0 8px 22px -6px rgba(91,233,255,.6)', border: '3px solid #06222b' }}>
            <Icon name="camera" size={26} color="#06222b" strokeWidth={2} />
          </button>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, margin: '10px 4px 0', color: 'var(--tx-faint)', fontSize: 11.5, lineHeight: 1.5 }}>
        <Icon name="info" size={14} style={{ marginTop: 1, flex: 'none' }} />
        <span>Camera của Luni <b style={{ color: 'var(--tx-mute)' }}>chỉ chụp ảnh tĩnh</b> — không quay video, không có luồng xem trực tiếp.</span>
      </div>

      {/* gallery */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '18px 4px 10px' }}>
        <span className="t-cap">ẢNH ĐÃ CHỤP</span>
        <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)' }}>{shots.length} ảnh</span>
      </div>
      <div style={{ display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 4, opacity: off ? .55 : 1 }}>
        {shots.map(p => (
          <button key={p.id} className="press" onClick={() => setView(p)} style={{ flex: 'none', width: 96, textAlign: 'left' }}>
            <div style={{ width: 96, height: 72, borderRadius: 11, overflow: 'hidden', border: '1px solid var(--hairline)' }}><PhotoFrame tone={p.tone} /></div>
            <div className="mono" style={{ fontSize: 10, color: 'var(--tx-faint)', marginTop: 5 }}>{p.t}</div>
          </button>
        ))}
      </div>

      {/* ============ LOCOMOTION — 4 leg motors ============ */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '24px 4px 10px' }}>
        <span className="t-over">Di chuyển · 2 chân</span>
        <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)' }}>ws · move · 4 động cơ</span>
      </div>

      <div className="card" style={{ padding: 18, opacity: off ? .55 : 1, pointerEvents: off ? 'none' : 'auto' }}>
        <DPad dir={dir} onDrive={drive} />
        {/* live leg motor readout */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginTop: 18 }}>
          {legAngles.map((a, i) => (
            <div key={i} style={{ textAlign: 'center' }}>
              <div style={{ height: 44, borderRadius: 8, background: 'var(--bg-2)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'flex-end' }}>
                <div style={{ width: '100%', height: `${(a / 180) * 100}%`, background: moving ? 'linear-gradient(var(--cyan),#2aa9c4)' : 'var(--bg-3)', borderRadius: '0 0 8px 8px', transition: 'height .5s var(--ease), background .3s' }} />
              </div>
              <div className="mono" style={{ fontSize: 10.5, fontWeight: 700, color: moving ? 'var(--cyan)' : 'var(--tx-mute)', marginTop: 5 }}>{a}°</div>
              <div className="mono" style={{ fontSize: 9, color: 'var(--tx-faint)' }}>{MOTOR_META[i].id}</div>
            </div>
          ))}
        </div>
      </div>

      <Section>Tốc độ di chuyển</Section>
      <div style={{ opacity: off ? .55 : 1, pointerEvents: off ? 'none' : 'auto' }}>
        <Slider value={cfg.moveSpeed} onChange={v => update({ config: { ...cfg, moveSpeed: v } })} icon={<><Icon name="gauge" size={19} /><span style={{ fontSize: 13.5, fontWeight: 600 }}>Tốc độ</span></>} />
      </div>

      <Section>Tư thế</Section>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, opacity: off ? .55 : 1, pointerEvents: off ? 'none' : 'auto' }}>
        <PoseAction icon="arrowUp" label="Đứng" onClick={() => { setDir('stop'); window.luniToast('Tư thế đứng', { icon: 'walk', color: 'var(--cyan)' }); }} />
        <PoseAction icon="arrowDown" label="Ngồi" onClick={() => { setDir('stop'); window.luniToast('Tư thế ngồi', { icon: 'walk', color: 'var(--cyan)' }); }} />
        <PoseAction icon="hand" label="Cúi chào" onClick={() => { gesture('Luni cúi chào', 30, 30, 'hand'); }} />
      </div>

      {/* ============ ARMS — 2 motors ============ */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '24px 4px 10px' }}>
        <span className="t-over">Cánh tay · 2 tay</span>
        <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)' }}>ws · arm_set · 2 động cơ</span>
      </div>

      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', opacity: off ? .55 : 1, pointerEvents: off ? 'none' : 'auto' }}>
        {[['Vẫy tay 👋', 18, 165, 'hand'], ['Giơ hai tay', 168, 168, 'arrowUp'], ['Chỉ tay', 12, 150, 'arrowRight'], ['Hạ tay', 10, 10, 'arrowDown']].map(([label, l, r, ic]) => (
          <button key={label} className="press" onClick={() => gesture(label, l, r, ic)} style={{ height: 38, padding: '0 14px', borderRadius: 99, background: 'var(--bg-2)', border: '1px solid var(--hairline)', display: 'inline-flex', alignItems: 'center', gap: 8, fontSize: 13, fontWeight: 600, color: 'var(--tx-soft)' }}>
            <Icon name={ic} size={15} color="var(--cyan)" strokeWidth={2} />{label}
          </button>
        ))}
      </div>

      <div className="card" style={{ padding: 14, marginTop: 12, display: 'grid', gap: 12, opacity: off ? .55 : 1, pointerEvents: off ? 'none' : 'auto' }}>
        <ArmDial label="Tay trái" id="M5" value={cfg.armL} onChange={v => setArm('armL', v)} />
        <div style={{ height: 1, background: 'var(--hairline)' }} />
        <ArmDial label="Tay phải" id="M6" value={cfg.armR} onChange={v => setArm('armR', v)} />
      </div>

      {/* ============ MOTOR DIAGNOSTICS — 6 motors ============ */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '24px 4px 10px' }}>
        <span className="t-over">Trạng thái động cơ</span>
        <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)' }}>chr · diag · servo</span>
      </div>
      <div className="card" style={{ padding: '4px 0' }}>
        {MOTOR_META.map((m, i) => {
          const angle = m.part === 'leg' ? legAngles[m.leg] : cfg[m.key];
          const active = m.part === 'leg' ? moving : false;
          const limit = angle <= 8 || angle >= 172;
          const stat = off ? { t: 'Mất kết nối', c: 'var(--tx-faint)' }
            : limit ? { t: 'Giới hạn', c: 'var(--orange)' }
            : active ? { t: 'Hoạt động', c: 'var(--cyan)' }
            : { t: 'Sẵn sàng', c: 'var(--green)' };
          return (
            <div key={m.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 14px', borderBottom: i < MOTOR_META.length - 1 ? '1px solid var(--hairline)' : 'none' }}>
              <span className="mono" style={{ fontSize: 11, fontWeight: 700, color: 'var(--tx-mute)', width: 26, flex: 'none' }}>{m.id}</span>
              <span style={{ width: 34, height: 34, borderRadius: 10, background: hexA(m.part === 'leg' ? '#5BE9FF' : '#FF6B9D', .12), display: 'grid', placeItems: 'center', flex: 'none' }}>
                <Icon name={m.part === 'leg' ? 'walk' : 'hand'} size={17} color={m.part === 'leg' ? 'var(--cyan)' : 'var(--rose)'} strokeWidth={1.8} />
              </span>
              <span style={{ flex: 1, minWidth: 0 }}>
                <span style={{ display: 'block', fontSize: 13.5, fontWeight: 600 }}>{m.name} <span style={{ color: 'var(--tx-mute)', fontWeight: 400 }}>· {m.joint}</span></span>
                <span className="mono" style={{ display: 'flex', gap: 12, fontSize: 10.5, color: 'var(--tx-faint)', marginTop: 2 }}>
                  <span>{off ? '—' : `${angle}°`}</span>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}><Icon name="temp" size={11} color="var(--tx-faint)" />{off ? '—' : `${MOTOR_TEMP[i] + (active ? 3 : 0)}°C`}</span>
                </span>
              </span>
              <span className="pill" style={{ height: 22, background: hexA(stat.c === 'var(--cyan)' ? '#5BE9FF' : stat.c === 'var(--orange)' ? '#FF9D5B' : stat.c === 'var(--green)' ? '#7BE88E' : '#5C6680', .14), color: stat.c }}>
                <span className="dot" style={{ background: stat.c, boxShadow: off ? 'none' : `0 0 6px ${stat.c}` }} />{stat.t}
              </span>
            </div>
          );
        })}
      </div>

      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, margin: '20px 4px 0', color: 'var(--tx-faint)', fontSize: 11.5, lineHeight: 1.5 }}>
        <Icon name="info" size={14} style={{ marginTop: 1, flex: 'none' }} />
        <span>Lệnh vận động & chụp ảnh gửi qua máy chủ tới robot bằng WebSocket (<span className="mono">move · set_pose · arm_set · camera_capture</span>).</span>
      </div>
    </Scroll>

      {/* photo preview sheet */}
      <Sheet open={!!view} onClose={() => setView(null)} title="Ảnh đã chụp">
        {view && (
          <>
            <div style={{ borderRadius: 16, overflow: 'hidden', aspectRatio: '4 / 3', border: '1px solid var(--hairline-2)' }}><PhotoFrame tone={view.tone} big label="ẢNH ROBOT" /></div>
            <div className="mono" style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: 'var(--tx-faint)', margin: '12px 2px 16px' }}>
              <span>1600×1200 · JPEG</span><span>{view.t}</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              <button className="cta-ghost" style={{ height: 48, fontSize: 14 }} onClick={() => window.luniToast('Đã lưu vào máy')}><Icon name="download" size={18} strokeWidth={2} /> Lưu</button>
              <button className="cta-ghost" style={{ height: 48, fontSize: 14, color: 'var(--red)', borderColor: hexA('#FF5B6E', .3) }} onClick={() => { setShots(s => s.filter(p => p.id !== view.id)); setView(null); window.luniToast('Đã xoá ảnh', { icon: 'trash', color: 'var(--red)' }); }}><Icon name="trash" size={18} color="var(--red)" strokeWidth={2} /> Xoá</button>
            </div>
          </>
        )}
      </Sheet>
    </>
  );
}

/* directional drive pad */
function DPad({ dir, onDrive }) {
  const cell = (nd, icon, ariaLabel) => {
    const on = dir === nd;
    const isStop = nd === 'stop';
    return (
      <button className="press" aria-label={ariaLabel} onClick={() => onDrive(nd)} style={{
        width: '100%', aspectRatio: '1', borderRadius: 16, display: 'grid', placeItems: 'center',
        background: on ? (isStop ? hexA('#FF9D5B', .18) : 'var(--cyan)') : 'var(--bg-2)',
        border: `1px solid ${on ? (isStop ? hexA('#FF9D5B', .5) : 'transparent') : 'var(--hairline)'}`,
        boxShadow: on && !isStop ? '0 6px 18px -6px rgba(91,233,255,.55)' : 'none',
        transition: 'all .16s var(--ease)',
      }}>
        <Icon name={icon} size={isStop ? 22 : 26} color={on ? (isStop ? 'var(--orange)' : '#06222b') : 'var(--tx-soft)'} strokeWidth={2.1} />
      </button>
    );
  };
  const blank = <div />;
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, maxWidth: 232, margin: '0 auto' }}>
      {blank}{cell('up', 'arrowUp', 'Tiến')}{blank}
      {cell('left', 'arrowLeft', 'Quay trái')}{cell('stop', 'stop', 'Dừng')}{cell('right', 'arrowRight', 'Quay phải')}
      {blank}{cell('down', 'arrowDown', 'Lùi')}{blank}
    </div>
  );
}

function PoseAction({ icon, label, onClick }) {
  return (
    <button className="press" onClick={onClick} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, padding: '16px 4px', borderRadius: 16, background: 'var(--bg-1)', border: '1px solid var(--hairline)' }}>
      <Icon name={icon} size={21} color="var(--tx-soft)" strokeWidth={1.9} />
      <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--tx-soft)' }}>{label}</span>
    </button>
  );
}

/* arm angle dial — drives one shoulder motor (0–180°) */
function ArmDial({ label, id, value, onChange }) {
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 9 }}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8, fontSize: 13.5, fontWeight: 600 }}>
          <Icon name="hand" size={17} color="var(--rose)" strokeWidth={1.8} />{label}
          <span className="mono" style={{ fontSize: 10, color: 'var(--tx-faint)' }}>{id}</span>
        </span>
        <span className="mono" style={{ fontSize: 13, fontWeight: 700, color: 'var(--rose)' }}>{value}°</span>
      </div>
      <Slider value={value} onChange={onChange} color="var(--warm)" min={0} max={180} icon={<span style={{ fontSize: 11.5, color: 'var(--tx-faint)' }} className="mono">0°–180°</span>} />
    </div>
  );
}

function CamChip({ icon, label, active, onClick }) {
  return (
    <button className="press" onClick={onClick} style={{ height: 36, padding: '0 13px', borderRadius: 99, display: 'inline-flex', alignItems: 'center', gap: 7, background: active ? hexA('#5BE9FF', .12) : 'var(--bg-2)', border: `1px solid ${active ? hexA('#5BE9FF', .4) : 'var(--hairline)'}`, fontSize: 12.5, fontWeight: 600, color: active ? 'var(--cyan)' : 'var(--tx-mute)' }}>
      <Icon name={icon} size={15} color={active ? 'var(--cyan)' : 'var(--tx-faint)'} strokeWidth={1.9} />{label}
    </button>
  );
}

Object.assign(window, { MotionTab, DPad, PoseAction, ArmDial, CamChip, PhotoFrame });
