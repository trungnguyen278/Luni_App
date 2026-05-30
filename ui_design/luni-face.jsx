/* ============================================================
   LuniFace — the signature animated robot face.
   A glowing "moon" disc with expressive eyes that morph per emotion.
   Props: emotion, size, state ('idle'|'listening'|'speaking'|'thinking'),
          dim (offline), onTap
   ============================================================ */
const { useState: _useState, useEffect: _useEffect, useRef: _useRef } = React;

// Emotions the firmware can actually be commanded into (WS SET_EMOTION → StateManager).
// `face` = eye-shape archetype; `tone` follows the robot's 9-tone palette.
// settable:true = controllable via SET_EMOTION; others are display-only (autonomous).
const LUNI_EMOTIONS = {
  neutral:   { color: '#5BE9FF', label: 'Bình thường', face: 'idle',    settable: true },
  idle:      { color: '#5BE9FF', label: 'Bình thường', face: 'idle' },
  happy:     { color: '#FFD166', label: 'Vui vẻ',      face: 'arc',     settable: true },
  excited:   { color: '#FFD166', label: 'Phấn khích',  face: 'wide',    settable: true },
  curious:   { color: '#FF9D5B', label: 'Tò mò',       face: 'curious', settable: true },
  confused:  { color: '#FF9D5B', label: 'Bối rối',     face: 'curious', settable: true },
  annoyed:   { color: '#FF9D5B', label: 'Khó chịu',    face: 'angry',   settable: true },
  nervous:   { color: '#FF9D5B', label: 'Lo lắng',     face: 'curious', settable: true },
  calm:      { color: '#76B8FF', label: 'Thư giãn',    face: 'oval',    settable: true },
  cool:      { color: '#5BE9FF', label: 'Ngầu',        face: 'oval',    settable: true },
  thinking:  { color: '#5BE9FF', label: 'Đang nghĩ',   face: 'idle',    settable: true },
  sad:       { color: '#76B8FF', label: 'Buồn',        face: 'sad',     settable: true },
  angry:     { color: '#FF5B6E', label: 'Giận',        face: 'angry',   settable: true },
  disgusted: { color: '#7BE88E', label: 'Ghê',         face: 'sad',     settable: true },
  // display-only (robot expresses these on its own; not on SET_EMOTION map)
  love:      { color: '#FF6B9D', label: 'Yêu thích',   face: 'arc' },
  sleepy:    { color: '#B48CFF', label: 'Buồn ngủ',    face: 'sleepy' },
  alert:     { color: '#FF5B6E', label: 'Cảnh báo',    face: 'wide' },
};

function hexA(hex, a) {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
}

// Eyes geometry per archetype, drawn in a 100x100 viewBox
function Eyes({ face, color, blink }) {
  const sy = blink ? 0.08 : 1;
  const grp = { transform: `scaleY(${sy})`, transformOrigin: '50px 50px', transition: 'transform .12s ease' };
  const glow = { filter: `drop-shadow(0 0 5px ${hexA(color, 0.9)})` };

  if (face === 'arc') {
    // smiling arcs ⌣ ⌣
    return (
      <g style={{ ...grp, ...glow }} stroke={color} strokeWidth="7" strokeLinecap="round" fill="none">
        <path d="M24 47 Q34 60 44 47" />
        <path d="M56 47 Q66 60 76 47" />
      </g>
    );
  }
  if (face === 'sad') {
    // downturned arcs ⌢ ⌢
    return (
      <g style={{ ...grp, ...glow }} stroke={color} strokeWidth="7" strokeLinecap="round" fill="none">
        <path d="M24 56 Q34 45 44 56" />
        <path d="M56 56 Q66 45 76 56" />
      </g>
    );
  }
  if (face === 'angry') {
    // slanted brows over eyes
    return (
      <g style={{ ...grp, ...glow }}>
        <g fill={color}>
          <rect x="28" y="42" width="13" height="22" rx="6" />
          <rect x="59" y="42" width="13" height="22" rx="6" />
        </g>
        <g stroke={color} strokeWidth="6" strokeLinecap="round">
          <path d="M26 34 L44 40" />
          <path d="M74 34 L56 40" />
        </g>
      </g>
    );
  }
  if (face === 'sleepy') {
    return (
      <g style={{ ...grp, ...glow }} stroke={color} strokeWidth="6.5" strokeLinecap="round" fill="none">
        <path d="M24 51 Q34 56 44 51" />
        <path d="M56 51 Q66 56 76 51" />
      </g>
    );
  }
  if (face === 'curious') {
    // one wide, one normal (the "huh?" look)
    return (
      <g style={{ ...grp, ...glow }} fill={color}>
        <rect x="27" y="36" width="13" height="28" rx="6.5" />
        <circle cx="66" cy="49" r="11" />
      </g>
    );
  }
  if (face === 'wide') {
    return (
      <g style={{ ...grp, ...glow }} fill={color}>
        <circle cx="34" cy="49" r="12.5" />
        <circle cx="66" cy="49" r="12.5" />
        <circle cx="34" cy="49" r="4.5" fill="#0a0c14" />
        <circle cx="66" cy="49" r="4.5" fill="#0a0c14" />
      </g>
    );
  }
  if (face === 'oval') {
    return (
      <g style={{ ...grp, ...glow }} fill={color}>
        <rect x="27" y="42" width="14" height="16" rx="7" />
        <rect x="59" y="42" width="14" height="16" rx="7" />
      </g>
    );
  }
  // idle — rounded pills
  return (
    <g style={{ ...grp, ...glow }} fill={color}>
      <rect x="28" y="36" width="13" height="28" rx="6.5" />
      <rect x="59" y="36" width="13" height="28" rx="6.5" />
    </g>
  );
}

function LuniFace({ emotion = 'idle', size = 160, state = 'idle', dim = false, onTap, style }) {
  const em = LUNI_EMOTIONS[emotion] || LUNI_EMOTIONS.idle;
  const color = dim ? '#5C6680' : em.color;
  const [blink, setBlink] = _useState(false);

  _useEffect(() => {
    if (dim) return;
    let t;
    const loop = () => {
      const next = 2200 + Math.random() * 3600;
      t = setTimeout(() => {
        setBlink(true);
        setTimeout(() => setBlink(false), 130);
        loop();
      }, next);
    };
    loop();
    return () => clearTimeout(t);
  }, [dim]);

  const breatheDur = emotion === 'sleepy' || emotion === 'calm' ? '5.5s'
    : emotion === 'alert' ? '1.6s' : '3.6s';

  return (
    <div
      onClick={onTap}
      style={{
        position: 'relative', width: size, height: size,
        cursor: onTap ? 'pointer' : 'default', flex: 'none',
        ...style,
      }}
    >
      {/* outer glow */}
      <div style={{
        position: 'absolute', inset: '-22%', borderRadius: '50%',
        background: `radial-gradient(circle, ${hexA(color, dim ? .12 : .42)} 0%, transparent 62%)`,
        animation: dim ? 'none' : `glowPulse ${breatheDur} var(--ease) infinite`,
        pointerEvents: 'none',
      }} />

      {/* listening radar rings */}
      {state === 'listening' && [0, 1, 2].map(i => (
        <div key={i} style={{
          position: 'absolute', inset: 0, borderRadius: '50%',
          border: `2px solid ${hexA(color, .5)}`,
          animation: `radar 2s ${i * 0.66}s ease-out infinite`,
        }} />
      ))}

      {/* the orb */}
      <div style={{
        position: 'absolute', inset: 0, borderRadius: '50%',
        background: `
          radial-gradient(120% 120% at 32% 26%, ${hexA(color, dim ? .08 : .20)} 0%, transparent 46%),
          radial-gradient(100% 100% at 50% 118%, ${hexA(color, .14)} 0%, transparent 55%),
          linear-gradient(160deg, #161b29 0%, #0c0f18 100%)`,
        border: `1.5px solid ${hexA(color, dim ? .14 : .34)}`,
        boxShadow: dim ? 'inset 0 2px 14px rgba(0,0,0,.5)'
          : `inset 0 2px 18px rgba(0,0,0,.45), inset 0 0 30px ${hexA(color, .12)}`,
        animation: dim ? 'none' : `luniBreathe ${breatheDur} var(--ease) infinite`,
        display: 'grid', placeItems: 'center', overflow: 'hidden',
      }}>
        {/* rim crescent highlight (the "moon") */}
        <div style={{
          position: 'absolute', inset: 0, borderRadius: '50%',
          background: `radial-gradient(120% 120% at 76% 80%, ${hexA(color, .10)} 0%, transparent 40%)`,
        }} />
        <svg viewBox="0 0 100 100" width="100%" height="100%" style={{ position: 'absolute', inset: 0 }}>
          <Eyes face={dim ? 'sleepy' : (em.face || 'idle')} color={color} blink={blink} />
        </svg>
      </div>

      {/* accessory glyphs */}
      {!dim && emotion === 'love' && (
        <div style={{ position: 'absolute', top: '-6%', right: '4%', color, animation: 'floatY 2.4s ease-in-out infinite' }}>
          <svg width={size * 0.16} height={size * 0.16} viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 21s-7-4.6-9.3-9C1 9 2.5 5.5 6 5.5c2 0 3.2 1.2 4 2.3.8-1.1 2-2.3 4-2.3 3.5 0 5 3.5 3.3 6.5C19 16.4 12 21 12 21z"/>
          </svg>
        </div>
      )}
      {!dim && emotion === 'sleepy' && (
        <div style={{ position: 'absolute', top: '-4%', right: '2%', color, fontWeight: 800, fontSize: size * 0.14, opacity: .8, animation: 'floatY 3s ease-in-out infinite' }}>z</div>
      )}
      {!dim && emotion === 'curious' && (
        <div style={{ position: 'absolute', top: '-8%', right: '6%', color, fontWeight: 800, fontSize: size * 0.2, animation: 'floatY 2.2s ease-in-out infinite' }}>?</div>
      )}

      {/* speaking / thinking mouth-wave at base */}
      {(state === 'speaking' || state === 'thinking') && (
        <div style={{
          position: 'absolute', left: '50%', bottom: '14%', transform: 'translateX(-50%)',
          display: 'flex', alignItems: 'center', gap: size * 0.025, height: size * 0.12,
        }}>
          {[0, 1, 2, 3, 4].map(i => (
            <div key={i} style={{
              width: size * 0.028, borderRadius: 999, background: color,
              height: state === 'speaking' ? '100%' : '40%',
              animation: `thinkDot 1s ${i * 0.12}s ease-in-out infinite`,
              boxShadow: `0 0 6px ${hexA(color, .8)}`,
            }} />
          ))}
        </div>
      )}
    </div>
  );
}

// Tiny mood chip used in lists / headers
function MoodDot({ emotion = 'idle', size = 10, dim = false }) {
  const c = dim ? '#5C6680' : (LUNI_EMOTIONS[emotion] || LUNI_EMOTIONS.idle).color;
  return (
    <span style={{
      width: size, height: size, borderRadius: '50%', display: 'inline-block',
      background: c, boxShadow: dim ? 'none' : `0 0 8px ${hexA(c, .8)}`, flex: 'none',
    }} />
  );
}

Object.assign(window, { LuniFace, MoodDot, LUNI_EMOTIONS, hexA, Eyes });
