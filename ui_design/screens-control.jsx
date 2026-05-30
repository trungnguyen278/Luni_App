/* ============================================================
   Control tab — emotions, scenes, volume, brightness, actions
   ============================================================ */
// Only emotions the firmware maps in WS SET_EMOTION (see WsMessageHandler::handleSetEmotion)
const EMOTION_LIST = [
  { id: 'neutral', icon: 'eye' }, { id: 'happy', icon: 'sun' }, { id: 'excited', icon: 'sparkle' },
  { id: 'curious', icon: 'search' }, { id: 'confused', icon: 'info' }, { id: 'calm', icon: 'wave' },
  { id: 'cool', icon: 'shield' }, { id: 'thinking', icon: 'cpu' }, { id: 'sad', icon: 'heart' },
  { id: 'angry', icon: 'bolt' }, { id: 'annoyed', icon: 'alert' }, { id: 'disgusted', icon: 'close' },
];
const SCENE_LIST = [
  { id: 'home', icon: 'home', color: 'var(--cyan)' }, { id: 'weather', icon: 'wifi', color: 'var(--blue)' },
  { id: 'clock', icon: 'clock', color: 'var(--warm)' }, { id: 'calendar', icon: 'logs', color: 'var(--green)' },
  { id: 'sleep', icon: 'moon', color: 'var(--purple)' }, { id: 'music', icon: 'wave', color: 'var(--rose)' },
];

function ControlTab({ device, update }) {
  const d = device;
  const cfg = d.config;
  const [flash, setFlash] = useS(null);
  const [tts, setTts] = useS('');
  const [emoSheet, setEmoSheet] = useS(false);
  const [sceneSheet, setSceneSheet] = useS(false);
  const pickRow = (dis) => ({ width: '100%', display: 'flex', alignItems: 'center', gap: 13, padding: '13px 14px', textAlign: 'left', background: 'transparent', opacity: dis ? .5 : 1 });
  const em = LUNI_EMOTIONS[d.emotion] || LUNI_EMOTIONS.idle;
  const ping = (msg) => { setFlash(msg); setTimeout(() => setFlash(null), 1700); };
  const off = !d.online;

  return (
    <>
    <Scroll style={{ padding: '14px 18px 30px' }}>
      {/* live preview */}
      <div className="card" style={{ display: 'flex', alignItems: 'center', gap: 16, padding: 16, background: `linear-gradient(120deg, ${hexA(em.color, .1)}, var(--bg-1))`, borderColor: hexA(em.color, .2) }}>
        <LuniFace emotion={d.emotion} size={68} dim={off} />
        <div style={{ flex: 1 }}>
          <div className="t-cap">TRẠNG THÁI TRỰC TIẾP</div>
          <div className="t-h3" style={{ color: off ? 'var(--tx-mute)' : em.color, marginTop: 2 }}>{off ? 'Ngoại tuyến' : em.label}</div>
          <div style={{ fontSize: 12.5, color: 'var(--tx-mute)', marginTop: 2 }}>Cảnh: {SCENE_VI[d.scene] || d.scene}</div>
        </div>
        {off && <span className="pill" style={{ background: hexA('#FF9D5B', .14), color: 'var(--orange)' }}>Offline</span>}
      </div>

      <Section>Biểu hiện trên màn hình</Section>
      <div className="card" style={{ padding: '2px 0' }}>
        {/* Emotion — opens override sheet */}
        <button className="press" disabled={off} onClick={() => setEmoSheet(true)} style={pickRow(off)}>
          <span style={{ width: 42, height: 42, borderRadius: '50%', display: 'grid', placeItems: 'center', background: hexA(em.color, .16), flex: 'none', boxShadow: off ? 'none' : `0 0 14px ${hexA(em.color, .28)}` }}>
            <Icon name={(EMOTION_LIST.find(e => e.id === d.emotion) || {}).icon || 'eye'} size={20} color={em.color} strokeWidth={2} />
          </span>
          <span style={{ flex: 1, minWidth: 0 }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 15, fontWeight: 700 }}>Cảm xúc</span>
              <span className="pill" style={{ height: 18, padding: '0 8px', background: hexA('#FF9D5B', .14), color: 'var(--orange)', fontSize: 9.5 }}>Đang xem xét</span>
            </span>
            <span style={{ display: 'block', fontSize: 12.5, color: 'var(--tx-mute)', marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Hiện tại: <span style={{ color: em.color, fontWeight: 600 }}>{em.label}</span> · 47 biểu cảm</span>
          </span>
          <Icon name="chevron" size={18} color="var(--tx-faint)" />
        </button>
        <div style={{ height: 1, background: 'var(--hairline)', margin: '0 14px' }} />
        {/* Scene — opens info sheet */}
        <button className="press" disabled={off} onClick={() => setSceneSheet(true)} style={pickRow(off)}>
          <span style={{ width: 42, height: 42, borderRadius: '50%', display: 'grid', placeItems: 'center', background: hexA('#5BE9FF', .14), flex: 'none' }}>
            <Icon name={(SCENE_LIST.find(s => s.id === d.scene) || {}).icon || 'grid'} size={20} color="var(--cyan)" strokeWidth={1.9} />
          </span>
          <span style={{ flex: 1, minWidth: 0 }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 15, fontWeight: 700 }}>Cảnh hiển thị</span>
              <span className="pill" style={{ height: 18, padding: '0 8px', background: hexA('#5BE9FF', .12), color: 'var(--cyan)', fontSize: 9.5 }}>Tự động</span>
            </span>
            <span style={{ display: 'block', fontSize: 12.5, color: 'var(--tx-mute)', marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{SCENE_VI[d.scene] || d.scene} · 32 cảnh</span>
          </span>
          <Icon name="chevron" size={18} color="var(--tx-faint)" />
        </button>
      </div>

      {/* TTS — make Luni speak (WS TTS_PLAY) */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '22px 4px 10px' }}>
        <span className="t-over">Cho Luni nói</span>
        <span className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)' }}>ws · tts_play</span>
      </div>
      <div className="card" style={{ padding: 12, opacity: off ? .5 : 1, pointerEvents: off ? 'none' : 'auto' }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <input value={tts} onChange={e => setTts(e.target.value)} onKeyDown={e => { if (e.key === 'Enter' && tts.trim()) { ping('Đã gửi để Luni đọc'); setTts(''); } }} placeholder="Nhập câu cho Luni đọc to…" style={{ flex: 1, height: 46, padding: '0 14px', background: 'var(--bg-2)', border: '1px solid var(--hairline)', borderRadius: 12, color: 'var(--tx)', fontSize: 14.5, outline: 'none' }} />
          <button className="press" disabled={!tts.trim()} onClick={() => { ping('Đã gửi để Luni đọc'); setTts(''); }} style={{ width: 48, height: 46, borderRadius: 12, background: tts.trim() ? 'var(--cyan)' : 'var(--bg-3)', display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="speaker" size={20} color={tts.trim() ? '#06222b' : 'var(--tx-faint)'} /></button>
        </div>
        <div style={{ display: 'flex', gap: 7, marginTop: 10, flexWrap: 'wrap' }}>
          {['Xin chào!', 'Đến giờ nghỉ rồi', 'Cố lên nhé 💪'].map(s => (
            <button key={s} className="press" onClick={() => { ping('Đã gửi để Luni đọc'); }} style={{ height: 30, padding: '0 12px', borderRadius: 99, background: 'var(--bg-2)', border: '1px solid var(--hairline)', fontSize: 12.5, fontWeight: 600, color: 'var(--tx-soft)' }}>{s}</button>
          ))}
        </div>
      </div>

      <Section>Âm lượng & độ sáng</Section>
      <div style={{ display: 'grid', gap: 10, opacity: off ? .5 : 1, pointerEvents: off ? 'none' : 'auto' }}>
        <Slider value={cfg.volume} onChange={v => update({ config: { ...cfg, volume: v } })} icon={<><Icon name="volume" size={19} /><span style={{ fontSize: 13.5, fontWeight: 600 }}>Âm lượng</span></>} />
        <Slider value={cfg.brightness} onChange={v => update({ config: { ...cfg, brightness: v } })} color="var(--warm)" icon={<><Icon name="sun" size={19} color="var(--warm)" /><span style={{ fontSize: 13.5, fontWeight: 600 }}>Độ sáng</span></>} />
      </div>

      <Section>Thao tác nhanh</Section>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
        <QuickAction icon="refresh" label="Khởi động lại" onClick={() => ping('Đã gửi lệnh khởi động lại')} />
        <QuickAction icon="power" label="Dừng âm thanh" onClick={() => ping('Đã dừng phát âm thanh')} />
        <QuickAction icon="volume" label="Tắt tiếng" onClick={() => { update({ config: { ...cfg, volume: 0 } }); ping('Đã tắt tiếng'); }} />
      </div>

      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, margin: '20px 4px 0', color: 'var(--tx-faint)', fontSize: 11.5, lineHeight: 1.5 }}>
        <Icon name="info" size={14} style={{ marginTop: 1, flex: 'none' }} />
        <span>Mọi lệnh gửi qua máy chủ tới robot bằng WebSocket (<span className="mono">set_volume · set_brightness · set_emotion · reboot · tts_play</span>).</span>
      </div>

      <Toast msg={flash} />
    </Scroll>

      <Sheet open={emoSheet} onClose={() => setEmoSheet(false)} title="Ghi đè cảm xúc">
        <p style={{ fontSize: 12.5, color: 'var(--tx-mute)', margin: '0 0 4px', lineHeight: 1.45 }}>Luni có <b style={{ color: 'var(--tx-soft)' }}>47 biểu cảm</b>; máy chủ tự chọn khi đang trả lời. Bạn có thể ghi đè thủ công sang một trong các trạng thái firmware bên dưới — lệnh có hiệu lực tới khi Luni trả lời câu hỏi tiếp theo.</p>
        <div className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)', margin: '0 0 14px' }}>ws · set_emotion · 12 / 47 trạng thái</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
          {EMOTION_LIST.map(e => {
            const info = LUNI_EMOTIONS[e.id]; const on = d.emotion === e.id;
            return (
              <button key={e.id} className="press" onClick={() => { update({ emotion: e.id }); ping(`Cảm xúc → ${info.label}`); setEmoSheet(false); }} style={{
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, padding: '15px 6px 11px', borderRadius: 16,
                background: on ? hexA(info.color, .14) : 'var(--bg-1)', border: `1.5px solid ${on ? hexA(info.color, .5) : 'var(--hairline)'}`, transition: 'all .18s var(--ease)',
              }}>
                <span style={{ width: 40, height: 40, borderRadius: '50%', display: 'grid', placeItems: 'center', background: hexA(info.color, on ? .2 : .1), boxShadow: on ? `0 0 16px ${hexA(info.color, .4)}` : 'none' }}>
                  <Icon name={e.icon} size={19} color={info.color} strokeWidth={2} />
                </span>
                <span style={{ fontSize: 12, fontWeight: 700, color: on ? info.color : 'var(--tx-soft)' }}>{info.label}</span>
              </button>
            );
          })}
        </div>
      </Sheet>

      <Sheet open={sceneSheet} onClose={() => setSceneSheet(false)} title="Cảnh hiển thị">
        <p style={{ fontSize: 12.5, color: 'var(--tx-mute)', margin: '0 0 14px', lineHeight: 1.45 }}>Luni có <b style={{ color: 'var(--tx-soft)' }}>32 cảnh</b>. Cảnh tự hiện khi có dữ liệu để hiển thị (thời tiết, đồng hồ, mạng…) — không chọn tay được. Khi rảnh, robot tự chiếu hoạt ảnh ngẫu nhiên cho đỡ chán.</p>
        <div className="card" style={{ padding: 16, marginBottom: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
            <span className="dot" style={{ background: 'var(--cyan)', boxShadow: '0 0 8px var(--cyan)', flex: 'none' }} />
            <span style={{ fontSize: 13.5, fontWeight: 700 }}>Chế độ rảnh — chiếu ngẫu nhiên</span>
          </div>
          <p style={{ fontSize: 12, color: 'var(--tx-mute)', margin: '7px 0 0', lineHeight: 1.45 }}>Tự đổi hoạt ảnh mỗi 3–6 giây từ nhóm <span className="mono" style={{ color: 'var(--tx-soft)' }}>normal</span>.</p>
        </div>
        <div className="t-cap" style={{ marginBottom: 11 }}>KÍCH HOẠT THEO DỮ LIỆU</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {SCENE_LIST.map(s => {
            const on = d.scene === s.id;
            return (
              <span key={s.id} style={{
                display: 'inline-flex', alignItems: 'center', gap: 7, height: 34, padding: '0 13px', borderRadius: 99,
                background: on ? hexA('#5BE9FF', .12) : 'var(--bg-2)', border: `1px solid ${on ? hexA('#5BE9FF', .4) : 'var(--hairline)'}`,
              }}>
                <Icon name={s.icon} size={15} color={on ? 'var(--cyan)' : s.color} strokeWidth={1.9} />
                <span style={{ fontSize: 13, fontWeight: 600, color: on ? 'var(--cyan)' : 'var(--tx-soft)' }}>{SCENE_VI[s.id]}</span>
              </span>
            );
          })}
        </div>
        <div className="mono" style={{ fontSize: 10.5, color: 'var(--tx-faint)', marginTop: 16 }}>ws · set_scene · do máy chủ điều phối</div>
      </Sheet>
    </>
  );
}

function QuickAction({ icon, label, onClick }) {
  return (
    <button className="press" onClick={onClick} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, padding: '16px 4px', borderRadius: 16, background: 'var(--bg-1)', border: '1px solid var(--hairline)' }}>
      <Icon name={icon} size={22} color="var(--tx-soft)" strokeWidth={1.8} />
      <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--tx-soft)' }}>{label}</span>
    </button>
  );
}

function Toast({ msg }) {
  if (!msg) return null;
  return (
    <div className="glass pop" style={{ position: 'absolute', left: '50%', bottom: 22, transform: 'translateX(-50%)', display: 'flex', alignItems: 'center', gap: 9, padding: '12px 18px', borderRadius: 14, border: '1px solid var(--hairline-2)', zIndex: 40, whiteSpace: 'nowrap', boxShadow: 'var(--shadow-pop)' }}>
      <Icon name="check" size={17} color="var(--green)" strokeWidth={2.4} />
      <span style={{ fontSize: 13.5, fontWeight: 600 }}>{msg}</span>
    </div>
  );
}

Object.assign(window, { ControlTab, QuickAction, Toast, EMOTION_LIST, SCENE_LIST });
