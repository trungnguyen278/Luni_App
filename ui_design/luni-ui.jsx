/* ============================================================
   Luni UI kit — phone frame, chrome, and shared primitives
   ============================================================ */

/* ---------- Android-style status bar (dark) ---------- */
function StatusBar({ tint = 'var(--tx)' }) {
  return (
    <div style={{
      height: 38, flex: 'none', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', padding: '0 22px 0 24px', position: 'relative',
      color: tint, fontSize: 14.5, fontWeight: 600, letterSpacing: '.01em',
    }}>
      <span style={{ fontVariantNumeric: 'tabular-nums' }}>12:15</span>
      <div style={{
        position: 'absolute', left: '50%', top: 9, transform: 'translateX(-50%)',
        width: 9, height: 9, borderRadius: 99, background: '#000',
        boxShadow: '0 0 0 2px #0b0e16',
      }} />
      <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
        <Icon name="signal" size={15} color={tint} strokeWidth={2.2} />
        <Icon name="wifi" size={15} color={tint} strokeWidth={2} />
        <span style={{ fontSize: 12.5, fontWeight: 700 }}>100</span>
        <Icon name="battery" size={20} color={tint} strokeWidth={1.8} />
      </div>
    </div>
  );
}

function NavPill({ tint = 'var(--tx)' }) {
  return (
    <div style={{ height: 22, flex: 'none', display: 'grid', placeItems: 'center' }}>
      <div style={{ width: 128, height: 4.5, borderRadius: 99, background: tint, opacity: .55 }} />
    </div>
  );
}

/* ---------- Phone frame ---------- */
function Phone({ children, bg = 'var(--bg-base)', tint = 'var(--tx)' }) {
  return (
    <div style={{
      width: 384, height: 832, borderRadius: 46, padding: 6,
      background: 'linear-gradient(160deg,#23262e,#0c0d11)',
      boxShadow: '0 40px 120px -20px rgba(0,0,0,.8), inset 0 0 0 1px rgba(255,255,255,.06)',
      flex: 'none',
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: 40, overflow: 'hidden',
        background: bg, display: 'flex', flexDirection: 'column', position: 'relative',
      }}>
        <StatusBar tint={tint} />
        <div style={{ flex: 1, minHeight: 0, position: 'relative', display: 'flex', flexDirection: 'column' }}>
          {children}
        </div>
        <NavPill tint={tint} />
      </div>
    </div>
  );
}

/* ---------- Top bar ---------- */
function TopBar({ title, onBack, right, sub, transparent }) {
  return (
    <div style={{
      flex: 'none', height: 56, padding: '0 8px 0 6px',
      display: 'flex', alignItems: 'center', gap: 4,
      background: transparent ? 'transparent' : 'var(--bg-base)',
    }}>
      {onBack && (
        <button className="press" onClick={onBack} style={iconBtn}>
          <Icon name="back" size={22} />
        </button>
      )}
      <div style={{ flex: 1, minWidth: 0, paddingLeft: onBack ? 2 : 12 }}>
        {title && <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-.01em', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>}
        {sub && <div style={{ fontSize: 12, color: 'var(--tx-mute)', marginTop: 1 }}>{sub}</div>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 2 }}>{right}</div>
    </div>
  );
}
const iconBtn = {
  width: 44, height: 44, borderRadius: 12, display: 'grid', placeItems: 'center',
  color: 'var(--tx)', flex: 'none',
};

/* ---------- Status pill ---------- */
function StatusPill({ online }) {
  const c = online ? 'var(--green)' : 'var(--tx-faint)';
  return (
    <span className="pill" style={{ background: hexA(online ? '#7BE88E' : '#5C6680', .14), color: c }}>
      <span className="dot" style={{ background: c, boxShadow: online ? `0 0 8px ${c}` : 'none' }} />
      {online ? 'Trực tuyến' : 'Ngoại tuyến'}
    </span>
  );
}

/* ---------- Battery indicator ---------- */
function Battery({ pct, charging, size = 'sm' }) {
  const col = charging ? 'var(--green)' : pct <= 15 ? 'var(--red)' : pct <= 35 ? 'var(--orange)' : 'var(--tx-soft)';
  const w = size === 'lg' ? 44 : 30, h = size === 'lg' ? 18 : 13;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, color: col, fontWeight: 700, fontSize: size === 'lg' ? 15 : 13 }}>
      <span style={{ position: 'relative', width: w, height: h, borderRadius: 4, border: `1.6px solid ${col}`, display: 'inline-block' }}>
        <span style={{ position: 'absolute', right: -3.5, top: '50%', transform: 'translateY(-50%)', width: 2.4, height: h * 0.45, borderRadius: 2, background: col }} />
        <span style={{ position: 'absolute', inset: 2, width: `calc(${pct}% - 4px)`, minWidth: 2, borderRadius: 2, background: col, animation: charging ? 'chargePulse 1.6s ease-in-out infinite' : 'none' }} />
      </span>
      {pct}%{charging && <Icon name="bolt" size={13} color="var(--green)" />}
    </span>
  );
}

/* ---------- SVG progress / gauge ring ---------- */
function Ring({ value = 0, size = 132, stroke = 9, color = 'var(--cyan)', track = 'var(--bg-2)', children }) {
  const r = (size - stroke) / 2, c = 2 * Math.PI * r;
  const off = c * (1 - Math.max(0, Math.min(1, value / 100)));
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={track} strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={stroke}
          strokeLinecap="round" strokeDasharray={c} strokeDashoffset={off}
          style={{ transition: 'stroke-dashoffset .7s var(--ease)', filter: `drop-shadow(0 0 6px ${color})` }} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', textAlign: 'center' }}>{children}</div>
    </div>
  );
}

/* ---------- Slider (draggable) ---------- */
function Slider({ value, onChange, icon, color = 'var(--cyan)', min = 0, max = 100 }) {
  const ref = _useRef(null);
  const set = (clientX) => {
    const el = ref.current; if (!el) return;
    const r = el.getBoundingClientRect();
    let p = (clientX - r.left) / r.width;
    p = Math.max(0, Math.min(1, p));
    onChange(Math.round(min + p * (max - min)));
  };
  const down = (e) => {
    e.preventDefault();
    const move = (ev) => set((ev.touches ? ev.touches[0] : ev).clientX);
    move(e.nativeEvent);
    const up = () => { window.removeEventListener('pointermove', move); window.removeEventListener('pointerup', up); };
    window.addEventListener('pointermove', move); window.addEventListener('pointerup', up);
  };
  const pct = ((value - min) / (max - min)) * 100;
  return (
    <div ref={ref} onPointerDown={down} style={{ position: 'relative', height: 52, borderRadius: 16, background: 'var(--bg-2)', overflow: 'hidden', cursor: 'pointer', touchAction: 'none', userSelect: 'none' }}>
      <div style={{ position: 'absolute', inset: 0, width: `${pct}%`, background: `linear-gradient(90deg, ${hexA(color === 'var(--cyan)' ? '#5BE9FF' : '#FFD166', .22)}, ${hexA(color === 'var(--cyan)' ? '#5BE9FF' : '#FFD166', .42)})`, transition: 'width .08s linear' }} />
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 16px', pointerEvents: 'none' }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 10, color: 'var(--tx)' }}>{icon}</span>
        <span style={{ fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: 'var(--tx)' }}>{value}{max === 100 ? '%' : ''}</span>
      </div>
    </div>
  );
}

/* ---------- Toggle switch ---------- */
function Toggle({ on, onChange }) {
  return (
    <button className="press" onClick={() => onChange(!on)} style={{
      width: 50, height: 30, borderRadius: 99, padding: 3, flex: 'none',
      background: on ? 'var(--cyan)' : 'var(--bg-3)', transition: 'background .2s var(--ease)',
      display: 'flex', justifyContent: on ? 'flex-end' : 'flex-start',
    }}>
      <span style={{ width: 24, height: 24, borderRadius: '50%', background: on ? '#06222b' : '#7a85a0', transition: 'all .2s var(--spring)', boxShadow: '0 2px 5px rgba(0,0,0,.4)' }} />
    </button>
  );
}

/* ---------- Scrollable tab strip ---------- */
function TabStrip({ tabs, active, onSelect }) {
  return (
    <div style={{ flex: 'none', display: 'flex', gap: 8, overflowX: 'auto', padding: '4px 16px 12px', borderBottom: '1px solid var(--hairline)' }}>
      {tabs.map(t => {
        const on = t.id === active;
        return (
          <button key={t.id} className="press" onClick={() => onSelect(t.id)} style={{
            flex: 'none', display: 'flex', alignItems: 'center', gap: 7, height: 38, padding: '0 14px',
            borderRadius: 99, fontSize: 13.5, fontWeight: 700, whiteSpace: 'nowrap',
            background: on ? 'var(--cyan)' : 'var(--bg-2)', color: on ? '#06222b' : 'var(--tx-mute)',
            border: `1px solid ${on ? 'transparent' : 'var(--hairline)'}`, transition: 'all .18s var(--ease)',
          }}>
            <Icon name={t.icon} size={16} strokeWidth={2} />
            {t.label}
          </button>
        );
      })}
    </div>
  );
}

/* ---------- Bottom sheet ---------- */
function Sheet({ open, onClose, title, children, height }) {
  if (!open) return null;
  return (
    <div onClick={onClose} style={{ position: 'absolute', inset: 0, zIndex: 50, display: 'flex', alignItems: 'flex-end' }}>
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(3,5,10,.66)', animation: 'popIn .2s ease' }} />
      <div onClick={e => e.stopPropagation()} className="glass" style={{
        position: 'relative', width: '100%', maxHeight: height || '78%', borderRadius: '26px 26px 0 0',
        border: '1px solid var(--hairline)', borderBottom: 'none', padding: '10px 18px 22px',
        animation: 'slideUp .3s var(--ease)', display: 'flex', flexDirection: 'column',
      }}>
        <div style={{ width: 40, height: 4.5, borderRadius: 99, background: 'var(--hairline-2)', margin: '4px auto 14px' }} />
        {title && <div className="t-h3" style={{ marginBottom: 14 }}>{title}</div>}
        <div style={{ overflowY: 'auto', minHeight: 0 }}>{children}</div>
      </div>
    </div>
  );
}

/* ---------- Section label ---------- */
function Section({ children, style }) {
  return <div className="t-over" style={{ margin: '22px 4px 10px', ...style }}>{children}</div>;
}

/* ---------- Setting row ---------- */
function Row({ icon, iconColor = 'var(--tx-soft)', label, sub, right, onClick, danger }) {
  const Tag = onClick ? 'button' : 'div';
  return (
    <Tag className={onClick ? 'press' : ''} onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 13, padding: '14px 16px',
      textAlign: 'left', background: 'transparent',
    }}>
      {icon && (
        <span style={{ width: 38, height: 38, borderRadius: 11, background: hexA(danger ? '#FF5B6E' : '#7d91b9', .12), display: 'grid', placeItems: 'center', flex: 'none' }}>
          <Icon name={icon} size={19} color={danger ? 'var(--red)' : iconColor} strokeWidth={1.8} />
        </span>
      )}
      <span style={{ flex: 1, minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 15, fontWeight: 600, color: danger ? 'var(--red)' : 'var(--tx)' }}>{label}</span>
        {sub && <span style={{ display: 'block', fontSize: 12.5, color: 'var(--tx-mute)', marginTop: 1 }}>{sub}</span>}
      </span>
      {right !== undefined ? right : (onClick && <Icon name="chevron" size={18} color="var(--tx-faint)" />)}
    </Tag>
  );
}

function Scroll({ children, style }) {
  return <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', overflowX: 'hidden', ...style }}>{children}</div>;
}

Object.assign(window, {
  StatusBar, NavPill, Phone, TopBar, StatusPill, Battery, Ring, Slider, Toggle,
  TabStrip, Sheet, Section, Row, Scroll, iconBtn,
});
