/* ============================================================
   Data tabs — Logs, Stats, OTA firmware update
   ============================================================ */

/* ---------------- SYSTEM LOGS (technical — used by Admin Level 2) ---------------- */
const LOG_LEVELS = {
  DEBUG: { c: 'var(--purple)', fill: false },
  INFO: { c: 'var(--cyan)', fill: true },
  WARN: { c: 'var(--orange)', fill: true },
  ERROR: { c: 'var(--red)', fill: true },
};
const LOGS = [
  { lv: 'INFO', tag: 'ws', msg: 'WebSocket connected to api.luni.vn', t: '12:14:08' },
  { lv: 'INFO', tag: 'llm', msg: 'interaction id=4821 latency=860ms', t: '12:13:55' },
  { lv: 'DEBUG', tag: 'audio', msg: 'TTS buffer flushed (24kHz, 1.2s)', t: '12:13:54' },
  { lv: 'WARN', tag: 'wifi', msg: 'RSSI dropped to -74 dBm, roaming…', t: '12:11:02' },
  { lv: 'INFO', tag: 'power', msg: 'battery 84% discharging (3.85V)', t: '12:08:30' },
  { lv: 'DEBUG', tag: 'ble', msg: 'advertising stopped (provisioned)', t: '12:02:11' },
  { lv: 'ERROR', tag: 'ota', msg: 'manifest fetch retry 1/3 (timeout)', t: '11:58:47' },
  { lv: 'INFO', tag: 'sys', msg: 'boot ok, partition=ota_0 fw=2.1.0', t: '11:58:40' },
];

/* ---------------- CONVERSATION HISTORY ---------------- */
// Spoken conversation transcript between the user and Luni, synced from the server.
const TALKS = [
  { day: 'Hôm nay', msgs: [
    { who: 'luni', em: 'happy',   t: '07:12', text: 'Chào buổi sáng! Hà Nội hôm nay 24°, trời se lạnh. Nhớ khoác thêm áo nha! ☀️' },
    { who: 'me',                  t: '07:13', voice: true, dur: '0:03', text: 'Cảm ơn Luni. Mấy giờ rồi nhỉ?' },
    { who: 'luni', em: 'neutral', t: '07:13', text: 'Bây giờ là 7 giờ 13 phút. Bạn còn 32 phút trước cuộc họp lúc 7:45.' },
    { who: 'me',                  t: '12:30', voice: true, dur: '0:02', text: 'Đặt hẹn giờ 20 phút giúp mình' },
    { who: 'luni', em: 'curious', t: '12:30', text: 'Đã đặt hẹn 20 phút. Mình sẽ nhắc bạn lúc 12:50 nhé.' },
    { who: 'me',                  t: '12:48', voice: true, dur: '0:02', text: 'Kể chuyện cười đi' },
    { who: 'luni', em: 'excited', t: '12:48', text: 'Vì sao con cá chơi quần vợt dở tệ? Vì nó cứ sợ… cái lưới! 😆' },
    { who: 'luni', em: 'happy',   t: '12:50', text: 'Hết 20 phút rồi nha! Nghỉ tay một chút rồi quay lại nhé.' },
  ] },
  { day: 'Hôm qua', msgs: [
    { who: 'me',                t: '21:05', voice: true, dur: '0:04', text: 'Luni ơi, kể chuyện trước khi ngủ đi' },
    { who: 'luni', em: 'calm',  t: '21:05', text: 'Được thôi. Ngày xửa ngày xưa, có một chú robot nhỏ tên Luni sống trên một đám mây bồng bềnh…' },
    { who: 'me',                t: '21:18', text: 'Hay quá, ngủ ngon nhé Luni' },
    { who: 'luni', em: 'love',  t: '21:18', text: 'Ngủ ngon nha! Mình giảm đèn và bật tiếng mưa rơi cho bạn dễ ngủ. 🌙' },
  ] },
];

function VoiceLine({ dur, dark }) {
  const bars = [6, 11, 7, 14, 9, 5, 12, 8, 4, 10, 6, 13];
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 7 }}>
      <Icon name="mic" size={15} color={dark ? '#06222b' : 'var(--cyan)'} strokeWidth={2} />
      <span style={{ display: 'flex', alignItems: 'center', gap: 2.5, height: 16 }}>
        {bars.map((h, i) => <span key={i} style={{ width: 2.5, height: h, borderRadius: 2, background: dark ? 'rgba(6,34,43,.45)' : hexA('#5BE9FF', .5) }} />)}
      </span>
      <span className="mono" style={{ fontSize: 11, fontWeight: 700, color: dark ? 'rgba(6,34,43,.7)' : 'var(--tx-mute)' }}>{dur}</span>
    </div>
  );
}

function Bubble({ m, dim }) {
  const me = m.who === 'me';
  const em = LUNI_EMOTIONS[m.em] || LUNI_EMOTIONS.idle;
  if (me) {
    return (
      <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
        <div style={{ maxWidth: '82%' }}>
          <div style={{ padding: '11px 14px', borderRadius: '18px 18px 6px 18px', background: 'var(--cyan)' }}>
            {m.voice && <VoiceLine dur={m.dur} dark />}
            <div style={{ fontSize: 14.5, lineHeight: 1.45, fontWeight: 500, color: '#06222b' }}>{m.text}</div>
          </div>
          <div className="mono" style={{ textAlign: 'right', fontSize: 11, color: 'var(--tx-faint)', margin: '4px 4px 0' }}>{m.t}</div>
        </div>
      </div>
    );
  }
  return (
    <div style={{ display: 'flex', gap: 9, alignItems: 'flex-end' }}>
      <span style={{ flex: 'none', marginBottom: 22 }}><LuniFace emotion={m.em} size={34} dim={dim} /></span>
      <div style={{ maxWidth: '80%' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, margin: '0 0 5px 3px' }}>
          <span style={{ fontSize: 12.5, fontWeight: 700, color: 'var(--tx-soft)' }}>Luni</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            <span style={{ width: 6, height: 6, borderRadius: 99, background: em.color, boxShadow: `0 0 6px ${hexA(em.color, .7)}` }} />
            <span style={{ fontSize: 10.5, fontWeight: 700, color: em.color }}>{em.label}</span>
          </span>
        </div>
        <div className="card" style={{ padding: '11px 14px', borderRadius: '18px 18px 18px 6px' }}>
          {m.voice && <VoiceLine dur={m.dur} />}
          <div style={{ fontSize: 14.5, lineHeight: 1.45, color: 'var(--tx)' }}>{m.text}</div>
        </div>
        <div className="mono" style={{ fontSize: 11, color: 'var(--tx-faint)', margin: '4px 0 0 3px' }}>{m.t}</div>
      </div>
    </div>
  );
}

function ConversationTab({ device }) {
  const [q, setQ] = useS('');
  const query = q.trim().toLowerCase();
  const groups = TALKS
    .map(g => ({ ...g, msgs: query ? g.msgs.filter(m => m.text.toLowerCase().includes(query)) : g.msgs }))
    .filter(g => g.msgs.length);
  const total = TALKS.reduce((n, g) => n + g.msgs.length, 0);

  return (
    <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 'none', padding: '12px 16px 10px' }}>
        <div style={{ position: 'relative' }}>
          <span style={{ position: 'absolute', left: 13, top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none' }}><Icon name="search" size={17} color="var(--tx-faint)" /></span>
          <input value={q} onChange={e => setQ(e.target.value)} placeholder="Tìm trong hội thoại…" style={{ width: '100%', height: 44, padding: '0 14px 0 40px', background: 'var(--bg-2)', border: '1px solid var(--hairline)', borderRadius: 13, color: 'var(--tx)', fontSize: 14, outline: 'none' }} />
        </div>
      </div>
      <Scroll style={{ padding: '2px 16px 24px' }}>
        {groups.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '52px 20px', color: 'var(--tx-faint)' }}>
            <Icon name="search" size={30} color="var(--tx-faint)" strokeWidth={1.6} style={{ margin: '0 auto 12px' }} />
            <div style={{ fontSize: 14 }}>Không tìm thấy đoạn hội thoại nào khớp “{q}”.</div>
          </div>
        ) : groups.map(g => (
          <div key={g.day}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, margin: '16px 2px 14px' }}>
              <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
              <span className="t-cap">{g.day}</span>
              <div style={{ flex: 1, height: 1, background: 'var(--hairline)' }} />
            </div>
            <div style={{ display: 'grid', gap: 13 }}>
              {g.msgs.map((m, i) => <Bubble key={i} m={m} dim={!device.online} />)}
            </div>
          </div>
        ))}
        {!query && <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7, padding: '22px 0 0', color: 'var(--tx-faint)', fontSize: 12 }}><Icon name="shield" size={13} color="var(--tx-faint)" /> {total} lượt · đồng bộ từ máy chủ · lưu 30 ngày</div>}
      </Scroll>
    </div>
  );
}

/* ---------------- STATS ---------------- */
const BARS = [12, 18, 9, 22, 28, 16, 24];
const DAYS = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
const BATT = [62, 70, 88, 95, 80, 66, 84, 91];

function StatsTab() {
  return (
    <Scroll style={{ padding: '16px 18px 28px' }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        <MiniStat icon="chat" color="var(--cyan)" big="129" label="Lượt tương tác / tuần" />
        <MiniStat icon="clock" color="var(--green)" big="38g" label="Thời gian hoạt động" />
        <MiniStat icon="volume" color="var(--rose)" big="1.4g" label="Thời lượng âm thanh" />
        <MiniStat icon="bolt" color="var(--warm)" big="2.1" label="Chu kỳ sạc / ngày" />
      </div>

      <Section>Tương tác mỗi ngày</Section>
      <div className="card" style={{ padding: '20px 16px 14px' }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 8, height: 130 }}>
          {BARS.map((v, i) => (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, height: '100%', justifyContent: 'flex-end' }}>
              <span style={{ fontSize: 11, fontWeight: 700, color: i === 4 ? 'var(--cyan)' : 'var(--tx-faint)' }}>{v}</span>
              <div style={{ width: '100%', maxWidth: 26, height: `${(v / 28) * 100}%`, borderRadius: 7, background: i === 4 ? 'linear-gradient(var(--cyan), #2aa9c4)' : 'var(--bg-3)', transformOrigin: 'bottom', animation: `barGrow .6s ${i * .06}s var(--spring) both`, boxShadow: i === 4 ? '0 0 14px rgba(91,233,255,.4)' : 'none' }} />
              <span style={{ fontSize: 11, color: 'var(--tx-faint)' }}>{DAYS[i]}</span>
            </div>
          ))}
        </div>
      </div>

      <Section>Lịch sử pin (24 giờ)</Section>
      <div className="card" style={{ padding: 16 }}>
        <AreaChart data={BATT} color="#7BE88E" />
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 11, color: 'var(--tx-faint)' }}><span>00:00</span><span>12:00</span><span>Hiện tại 84%</span></div>
      </div>

      <Section>Phân bố cảm xúc</Section>
      <div className="card" style={{ padding: 16, display: 'grid', gap: 10 }}>
        {[['happy', 42], ['curious', 28], ['calm', 18], ['love', 8], ['sleepy', 4]].map(([em, pct]) => {
          const c = LUNI_EMOTIONS[em].color;
          return (
            <div key={em} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <span style={{ width: 64, fontSize: 12.5, fontWeight: 600, color: 'var(--tx-soft)' }}>{LUNI_EMOTIONS[em].label}</span>
              <div style={{ flex: 1, height: 10, borderRadius: 99, background: 'var(--bg-3)', overflow: 'hidden' }}>
                <div style={{ width: `${pct}%`, height: '100%', borderRadius: 99, background: c, boxShadow: `0 0 8px ${hexA(c, .5)}` }} />
              </div>
              <span className="mono" style={{ fontSize: 12, fontWeight: 700, width: 32, textAlign: 'right', color: c }}>{pct}%</span>
            </div>
          );
        })}
      </div>
    </Scroll>
  );
}

function MiniStat({ icon, color, big, label }) {
  return (
    <div className="card" style={{ padding: 16 }}>
      <Icon name={icon} size={20} color={color} strokeWidth={1.8} />
      <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: '-.02em', marginTop: 10 }}>{big}</div>
      <div style={{ fontSize: 12, color: 'var(--tx-mute)', marginTop: 2 }}>{label}</div>
    </div>
  );
}

function AreaChart({ data, color }) {
  const w = 300, h = 90, max = 100;
  const pts = data.map((v, i) => [(i / (data.length - 1)) * w, h - (v / max) * h]);
  const line = pts.map((p, i) => `${i ? 'L' : 'M'}${p[0].toFixed(1)} ${p[1].toFixed(1)}`).join(' ');
  const area = `${line} L${w} ${h} L0 ${h} Z`;
  return (
    <svg viewBox={`0 0 ${w} ${h}`} width="100%" height={h} preserveAspectRatio="none">
      <defs><linearGradient id="ag" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor={color} stopOpacity=".35" /><stop offset="1" stopColor={color} stopOpacity="0" /></linearGradient></defs>
      <path d={area} fill="url(#ag)" />
      <path d={line} fill="none" stroke={color} strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" style={{ filter: `drop-shadow(0 0 4px ${hexA(color, .6)})` }} />
      {pts.map((p, i) => i === pts.length - 1 && <circle key={i} cx={p[0]} cy={p[1]} r="4" fill={color} />)}
    </svg>
  );
}

/* ---------------- OTA ---------------- */
function OtaTab({ device, update }) {
  const [phase, setPhase] = useS('avail'); // avail | downloading | installing | done
  const [pct, setPct] = useS(0);

  React.useEffect(() => {
    if (phase !== 'downloading') return;
    const iv = setInterval(() => setPct(p => { if (p >= 100) { clearInterval(iv); setPhase('installing'); setTimeout(() => { setPhase('done'); update({ fwVersion: '2.2.0' }); }, 2600); return 100; } return p + 4; }), 110);
    return () => clearInterval(iv);
  }, [phase]);

  return (
    <Scroll style={{ padding: '16px 18px 28px' }}>
      <div className="card" style={{ padding: 18, textAlign: 'center', background: 'radial-gradient(120% 90% at 50% -10%, rgba(180,140,255,.12), var(--bg-1) 60%)', borderColor: hexA('#B48CFF', .22) }}>
        <span style={{ width: 60, height: 60, borderRadius: 18, background: hexA('#B48CFF', .14), display: 'inline-grid', placeItems: 'center' }}><Icon name="cpu" size={30} color="var(--purple)" strokeWidth={1.6} /></span>
        {phase === 'done' ? (
          <><div className="t-h2" style={{ marginTop: 14, color: 'var(--green)' }}>Đã cập nhật!</div><p className="t-sub" style={{ margin: '6px 0 0' }}>Luni đang chạy firmware <b className="mono" style={{ color: 'var(--tx-soft)' }}>v2.2.0</b></p></>
        ) : (
          <><div style={{ fontSize: 13, color: 'var(--tx-mute)', marginTop: 14 }}>Phiên bản mới sẵn sàng</div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, marginTop: 6 }}>
              <span className="mono" style={{ fontSize: 15, color: 'var(--tx-faint)' }}>v2.1.0</span>
              <Icon name="chevron" size={16} color="var(--tx-faint)" />
              <span className="mono t-h2" style={{ color: 'var(--purple)' }}>v2.2.0</span>
            </div>
            <div className="t-sub" style={{ marginTop: 6 }}>14.2 MB · ~3 phút</div>
          </>
        )}
      </div>

      {(phase === 'downloading' || phase === 'installing') && (
        <div className="card" style={{ padding: 18, marginTop: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 10, fontSize: 13.5, fontWeight: 600 }}>
            <span>{phase === 'downloading' ? 'Đang tải về Luni…' : 'Đang cài đặt & khởi động lại…'}</span>
            <span className="mono" style={{ color: 'var(--purple)' }}>{phase === 'downloading' ? `${pct}%` : ''}</span>
          </div>
          <div style={{ height: 10, borderRadius: 99, background: 'var(--bg-3)', overflow: 'hidden' }}>
            {phase === 'downloading'
              ? <div style={{ width: `${pct}%`, height: '100%', borderRadius: 99, background: 'linear-gradient(90deg,#B48CFF,#5BE9FF)', transition: 'width .1s' }} />
              : <div style={{ width: '40%', height: '100%', borderRadius: 99, background: 'linear-gradient(90deg,transparent,#B48CFF,transparent)', animation: 'sweep 1.1s linear infinite' }} />}
          </div>
          {phase === 'installing' && <p className="t-sub" style={{ margin: '12px 0 0', display: 'flex', alignItems: 'center', gap: 8 }}><Icon name="alert" size={15} color="var(--orange)" /> Không tắt nguồn robot trong lúc này.</p>}
        </div>
      )}

      <Section>Có gì mới trong 2.2.0</Section>
      <div className="card" style={{ padding: '4px 16px' }}>
        {[['sparkle', 'var(--cyan)', 'Cảm xúc mượt hơn', 'Chuyển trạng thái khuôn mặt tự nhiên hơn 30%'], ['volume', 'var(--rose)', 'Giọng nói tiếng Việt mới', 'Thêm 2 giọng đọc tự nhiên'], ['shield', 'var(--green)', 'Vá bảo mật BLE', 'Cải thiện xác thực Level 2'], ['bolt', 'var(--warm)', 'Tiết kiệm pin', 'Tăng ~15% thời lượng chờ']].map(([ic, c, t, s], i, a) => (
          <div key={t} style={{ display: 'flex', gap: 13, padding: '13px 0', borderBottom: i < a.length - 1 ? '1px solid var(--hairline)' : 'none' }}>
            <Icon name={ic} size={19} color={c} style={{ marginTop: 2 }} />
            <div><div style={{ fontSize: 14, fontWeight: 600 }}>{t}</div><div style={{ fontSize: 12.5, color: 'var(--tx-mute)', marginTop: 1 }}>{s}</div></div>
          </div>
        ))}
      </div>

      {phase === 'avail' && <button className="cta" onClick={() => { setPct(0); setPhase('downloading'); }} style={{ marginTop: 18, background: 'var(--purple)', color: '#1a0d33', boxShadow: '0 10px 30px -8px rgba(180,140,255,.5)' }}><Icon name="download" size={20} color="#1a0d33" strokeWidth={2.2} /> Cập nhật ngay</button>}
      {phase === 'done' && <button className="cta-ghost" style={{ marginTop: 18 }}><Icon name="check" size={19} color="var(--green)" strokeWidth={2.4} /> Đã là phiên bản mới nhất</button>}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginTop: 16, color: 'var(--tx-mute)', fontSize: 12.5 }}>
        <Icon name="info" size={15} /> Tự động cập nhật {device.config.autoOta ? 'đang bật' : 'đang tắt'}
      </div>
    </Scroll>
  );
}

Object.assign(window, { ConversationTab, Bubble, VoiceLine, TALKS, StatsTab, OtaTab, MiniStat, AreaChart, LOGS, LOG_LEVELS });
