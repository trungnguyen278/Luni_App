/* ============================================================
   Auth — login / register / forgot password
   ============================================================ */
const { useState: useS } = React;

function Wordmark({ size = 26 }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <LuniFace emotion="idle" size={size * 1.5} />
      <span style={{ fontSize: size, fontWeight: 800, letterSpacing: '-.03em' }}>Luni</span>
    </div>
  );
}

function TextField({ icon, label, value, onChange, type = 'text', placeholder, right }) {
  return (
    <label style={{ display: 'block' }}>
      <span style={{ display: 'block', fontSize: 13, fontWeight: 600, color: 'var(--tx-mute)', margin: '0 4px 7px' }}>{label}</span>
      <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
        {icon && <span style={{ position: 'absolute', left: 16, display: 'grid', placeItems: 'center', pointerEvents: 'none' }}><Icon name={icon} size={19} color="var(--tx-faint)" /></span>}
        <input
          className="field" type={type} value={value} placeholder={placeholder}
          onChange={e => onChange(e.target.value)}
          style={{ paddingLeft: icon ? 46 : 16, paddingRight: right ? 48 : 16 }}
        />
        {right && <span style={{ position: 'absolute', right: 6 }}>{right}</span>}
      </div>
    </label>
  );
}

function AuthFlow({ onAuthed }) {
  const [mode, setMode] = useS('login');
  const [email, setEmail] = useS('test@example.com');
  const [pw, setPw] = useS('luni2026');
  const [name, setName] = useS('');
  const [showPw, setShowPw] = useS(false);
  const [busy, setBusy] = useS(false);
  const [sent, setSent] = useS(false);

  const roleFor = (mail) => /admin|service|ky?thuat|@luni\./i.test(mail) ? 'admin' : 'user';
  const role = roleFor(email);

  const submit = () => {
    setBusy(true);
    setTimeout(() => { setBusy(false); onAuthed(roleFor(email), email); }, 900);
  };

  return (
    <Scroll style={{ padding: '8px 24px 28px' }}>
      <div className="screen-anim" key={mode}>
        <div style={{ marginTop: 14 }}><Wordmark /></div>

        {mode === 'login' && (<>
          <h1 className="t-h1" style={{ margin: '40px 0 8px', fontSize: 32 }}>Chào mừng<br/>trở lại</h1>
          <p className="t-body" style={{ color: 'var(--tx-mute)', margin: '0 0 30px' }}>Đăng nhập để quản lý robot, ghép nối BLE và theo dõi realtime.</p>
          <div style={{ display: 'grid', gap: 16 }}>
            <TextField icon="mail" label="Email" value={email} onChange={setEmail} type="email" placeholder="ban@vidu.com" />
            <TextField icon="lock" label="Mật khẩu" value={pw} onChange={setPw} type={showPw ? 'text' : 'password'} placeholder="••••••••"
              right={<button className="press" onClick={() => setShowPw(!showPw)} style={iconBtn}><Icon name={showPw ? 'eyeOff' : 'eye'} size={19} color="var(--tx-mute)" /></button>} />
          </div>

          {/* demo accounts — role decided by email */}
          <div style={{ marginTop: 18 }}>
            <div className="t-cap" style={{ margin: '0 4px 8px' }}>TÀI KHOẢN DEMO</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              {[
                { r: 'user',  mail: 'test@example.com', pw: 'luni2026', icon: 'user',   c: '#5BE9FF', label: 'Người dùng', sub: 'App quản lý robot' },
                { r: 'admin', mail: 'admin@luni.vn',    pw: 'luni2026', icon: 'shield', c: '#B48CFF', label: 'Admin',        sub: 'Bảng dịch vụ kỹ thuật' },
              ].map(a => {
                const on = role === a.r;
                return (
                  <button key={a.r} type="button" className="press" onClick={() => { setEmail(a.mail); setPw(a.pw); }} style={{
                    display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 4, padding: '12px 13px', borderRadius: 14, textAlign: 'left',
                    background: on ? hexA(a.c, .12) : 'var(--bg-2)', border: `1.5px solid ${on ? hexA(a.c, .5) : 'var(--hairline)'}`, transition: 'all .18s var(--ease)',
                  }}>
                    <span style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                      <Icon name={a.icon} size={16} color={a.c} strokeWidth={2.1} />
                      <span style={{ fontSize: 13.5, fontWeight: 700, color: on ? a.c : 'var(--tx-soft)' }}>{a.label}</span>
                    </span>
                    <span style={{ fontSize: 11, color: 'var(--tx-mute)' }}>{a.sub}</span>
                  </button>
                );
              })}
            </div>
          </div>
          <button className="cta" disabled={busy} onClick={submit} style={{ marginTop: 22, background: role === 'admin' ? 'var(--purple)' : 'var(--cyan)', color: role === 'admin' ? '#1a0d33' : '#04222b', boxShadow: role === 'admin' ? '0 10px 30px -8px rgba(180,140,255,.5)' : '0 10px 30px -8px rgba(91,233,255,.5)' }}>
            {busy ? <Spinner color={role === 'admin' ? '#1a0d33' : '#04222b'} /> : <><Icon name={role === 'admin' ? 'shield' : 'power'} size={20} color={role === 'admin' ? '#1a0d33' : '#04222b'} strokeWidth={2.2} /> {role === 'admin' ? 'Đăng nhập Admin' : 'Đăng nhập'}</>}
          </button>
          <button className="cta-ghost" onClick={() => setMode('register')} style={{ marginTop: 12 }}>
            <Icon name="user" size={19} /> Tạo tài khoản
          </button>
          <button className="press" onClick={() => { setMode('forgot'); setSent(false); }} style={{ display: 'block', margin: '22px auto 0', color: 'var(--cyan)', fontWeight: 700, fontSize: 14 }}>Quên mật khẩu?</button>
        </>)}

        {mode === 'register' && (<>
          <h1 className="t-h1" style={{ margin: '34px 0 8px', fontSize: 30 }}>Tạo tài khoản</h1>
          <p className="t-body" style={{ color: 'var(--tx-mute)', margin: '0 0 26px' }}>Một tài khoản cho mọi chú Luni của bạn.</p>
          <div style={{ display: 'grid', gap: 16 }}>
            <TextField icon="user" label="Tên hiển thị" value={name} onChange={setName} placeholder="Tên của bạn" />
            <TextField icon="mail" label="Email" value={email} onChange={setEmail} type="email" placeholder="ban@vidu.com" />
            <TextField icon="lock" label="Mật khẩu" value={pw} onChange={setPw} type={showPw ? 'text' : 'password'} placeholder="Tối thiểu 8 ký tự"
              right={<button className="press" onClick={() => setShowPw(!showPw)} style={iconBtn}><Icon name={showPw ? 'eyeOff' : 'eye'} size={19} color="var(--tx-mute)" /></button>} />
          </div>
          <div style={{ display: 'flex', gap: 6, alignItems: 'flex-start', margin: '16px 4px 0', color: 'var(--tx-mute)', fontSize: 12.5 }}>
            <Icon name="shield" size={15} color="var(--green)" style={{ marginTop: 1 }} />
            <span>Mật khẩu được mã hoá. Chúng tôi không bao giờ chia sẻ dữ liệu robot.</span>
          </div>
          <button className="cta" disabled={busy} onClick={submit} style={{ marginTop: 22 }}>
            {busy ? <Spinner /> : <>Tạo tài khoản <Icon name="chevron" size={20} color="#04222b" strokeWidth={2.4} /></>}
          </button>
          <button className="press" onClick={() => setMode('login')} style={{ display: 'block', margin: '20px auto 0', color: 'var(--tx-mute)', fontSize: 14 }}>Đã có tài khoản? <span style={{ color: 'var(--cyan)', fontWeight: 700 }}>Đăng nhập</span></button>
        </>)}

        {mode === 'forgot' && (<>
          <h1 className="t-h1" style={{ margin: '34px 0 8px', fontSize: 30 }}>Quên mật khẩu</h1>
          <p className="t-body" style={{ color: 'var(--tx-mute)', margin: '0 0 26px' }}>Nhập email, chúng tôi sẽ gửi liên kết đặt lại.</p>
          {!sent ? (<>
            <TextField icon="mail" label="Email" value={email} onChange={setEmail} type="email" placeholder="ban@vidu.com" />
            <button className="cta" onClick={() => setSent(true)} style={{ marginTop: 22 }}><Icon name="send" size={19} color="#04222b" /> Gửi liên kết</button>
          </>) : (
            <div className="card-2 pop" style={{ padding: 22, display: 'flex', gap: 14, alignItems: 'flex-start' }}>
              <span style={{ width: 44, height: 44, borderRadius: 12, background: hexA('#7BE88E', .14), display: 'grid', placeItems: 'center', flex: 'none' }}><Icon name="check" size={22} color="var(--green)" strokeWidth={2.4} /></span>
              <div>
                <div className="t-h3">Đã gửi!</div>
                <p className="t-sub" style={{ margin: '4px 0 0' }}>Kiểm tra <b style={{ color: 'var(--tx-soft)' }}>{email}</b> và làm theo hướng dẫn.</p>
              </div>
            </div>
          )}
          <button className="press" onClick={() => setMode('login')} style={{ display: 'flex', alignItems: 'center', gap: 6, margin: '22px auto 0', color: 'var(--tx-mute)', fontSize: 14 }}><Icon name="back" size={16} /> Quay lại đăng nhập</button>
        </>)}
      </div>
    </Scroll>
  );
}

function Spinner({ size = 20, color = '#04222b' }) {
  return <span style={{ width: size, height: size, borderRadius: '50%', border: `2.5px solid ${hexA('#000000', 0)}`, borderTopColor: color, borderRightColor: color, display: 'inline-block', animation: 'spin .7s linear infinite', boxSizing: 'border-box', borderLeftColor: hexA('#ffffff', .25), borderBottomColor: hexA('#ffffff', .25) }} />;
}

Object.assign(window, { AuthFlow, Wordmark, TextField, Spinner });
