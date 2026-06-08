import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../shared/models/device.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../../../shared/widgets/luni_toast.dart';

/// Motion ("Vận động") controls for the legged + camera robot variant
/// (luni_v3_walk_cam): a still photo camera, 4 leg motors (2 per leg) and
/// 2 arm motors. Flutter port of `ui_design/screens-motion.jsx`.
///
/// Lives alongside the chat view inside a single hub tab — the two are NOT
/// split into separate tab-screens.

/// Leg motor pose targets per drive direction (4 motors, degrees).
/// order: [chân trái·hông, chân trái·gối, chân phải·hông, chân phải·gối]
const Map<String, List<int>> _legPose = {
  'stop': [90, 90, 90, 90],
  'up': [64, 116, 116, 64], // tiến
  'down': [116, 64, 64, 116], // lùi
  'left': [58, 120, 98, 82], // quay trái
  'right': [98, 82, 58, 120], // quay phải
};

const Map<String, String> _dirVi = {
  'stop': 'Đứng yên',
  'up': 'Tiến tới',
  'down': 'Lùi lại',
  'left': 'Quay trái',
  'right': 'Quay phải',
};

class _MotorMeta {
  const _MotorMeta(this.id, this.part, this.name, this.joint, {this.leg = 0, this.armKey});
  final String id;
  final String part; // 'leg' | 'arm'
  final String name;
  final String joint;
  final int leg; // index into leg-angle list
  final String? armKey; // 'armL' | 'armR'
}

const List<_MotorMeta> _motorMeta = [
  _MotorMeta('M1', 'leg', 'Chân trái', 'Hông', leg: 0),
  _MotorMeta('M2', 'leg', 'Chân trái', 'Gối', leg: 1),
  _MotorMeta('M3', 'leg', 'Chân phải', 'Hông', leg: 2),
  _MotorMeta('M4', 'leg', 'Chân phải', 'Gối', leg: 3),
  _MotorMeta('M5', 'arm', 'Tay trái', 'Vai', armKey: 'armL'),
  _MotorMeta('M6', 'arm', 'Tay phải', 'Vai', armKey: 'armR'),
];

const List<int> _motorTemp = [38, 36, 39, 37, 34, 35]; // °C seed per motor

class _Shot {
  const _Shot(this.id, this.time, this.tone);
  final int id;
  final String time;
  final Color tone;
}

class MotionScreen extends StatefulWidget {
  const MotionScreen({required this.device, super.key});

  final Device device;

  @override
  State<MotionScreen> createState() => _MotionScreenState();
}

class _MotionScreenState extends State<MotionScreen> {
  String _dir = 'stop';
  bool _flash = false;
  String _flashMode = 'auto'; // off | auto | on
  int _timer = 0; // 0 | 3 | 10 (s)
  int _moveSpeed = 55;
  int _armL = 18;
  int _armR = 18;
  int _counter = 4;
  Timer? _flashTimer;
  Timer? _captureTimer;

  List<_Shot> _shots = const [
    _Shot(3, '12:02', LuniColors.warm),
    _Shot(2, '11:47', LuniColors.blue),
    _Shot(1, '09:30', LuniColors.green),
  ];

  bool get _off => !widget.device.isOnline;
  bool get _moving => _dir != 'stop';
  List<int> get _legAngles => _legPose[_dir] ?? _legPose['stop']!;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _captureTimer?.cancel();
    super.dispose();
  }

  void _drive(String nd) {
    if (_off) return;
    setState(() => _dir = nd);
    if (nd == 'stop') {
      luniToast(context, 'Đã dừng', icon: 'stop', color: LuniColors.orange);
    } else {
      luniToast(context, _dirVi[nd]!, icon: 'walk', color: LuniColors.cyan);
    }
  }

  void _capture() {
    if (_off) return;
    if (_flashMode != 'off') {
      setState(() => _flash = true);
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 320),
          () => mounted ? setState(() => _flash = false) : null);
    }
    void fire() {
      if (!mounted) return;
      final id = _counter++;
      const tones = [
        LuniColors.cyan,
        LuniColors.rose,
        LuniColors.warm,
        LuniColors.green,
        LuniColors.purple,
        LuniColors.orange,
      ];
      setState(() {
        _shots = [_Shot(id, 'vừa xong', tones[id % tones.length]), ..._shots]
            .take(12)
            .toList();
      });
      luniToast(context, 'Đã chụp 1 ảnh', icon: 'camera', color: LuniColors.cyan);
    }

    if (_timer != 0) {
      _captureTimer?.cancel();
      _captureTimer = Timer(Duration(milliseconds: _timer * 90), fire);
    } else {
      fire();
    }
  }

  void _gesture(String label, int l, int r, String icon) {
    if (_off) return;
    setState(() {
      _armL = l;
      _armR = r;
    });
    luniToast(context, label, icon: icon, color: LuniColors.cyan);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final off = _off;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      children: [
        _postureStrip(d),
        const _MotionHeader('Camera', meta: 'ws · camera_capture'),
        _cameraCard(),
        _infoNote(
            'Camera của Luni chỉ chụp ảnh tĩnh — không quay video, không có luồng xem trực tiếp.'),
        const SizedBox(height: 18),
        _galleryHeader(),
        const SizedBox(height: 10),
        _gallery(),
        const _MotionHeader('Di chuyển · 2 chân', meta: 'ws · move · 4 động cơ'),
        _locomotionCard(),
        const SectionLabel('Tốc độ di chuyển'),
        IgnorePointer(
          ignoring: off,
          child: Opacity(
            opacity: off ? 0.55 : 1,
            child: LuniSlider(
              value: _moveSpeed,
              icon: 'gauge',
              onChanged: (v) => setState(() => _moveSpeed = v),
            ),
          ),
        ),
        const SectionLabel('Tư thế'),
        _poses(off),
        const _MotionHeader('Cánh tay · 2 tay', meta: 'ws · arm_set · 2 động cơ'),
        _armGestures(off),
        const SizedBox(height: 12),
        _armDials(off),
        const _MotionHeader('Trạng thái động cơ', meta: 'chr · diag · servo'),
        _motorDiagnostics(off),
        _infoNote(
            'Lệnh vận động & chụp ảnh gửi qua máy chủ tới robot bằng WebSocket '
            '(move · set_pose · arm_set · camera_capture).'),
      ],
    );
  }

  // ---------------- live posture strip ----------------
  Widget _postureStrip(Device d) {
    final active = _moving && !_off;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hexA(LuniColors.cyan, active ? 0.12 : 0.05), LuniColors.bg1],
        ),
        borderRadius: BorderRadius.circular(LuniTokens.radius),
        border: Border.all(
            color: active ? hexA(LuniColors.cyan, 0.26) : LuniColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: hexA(LuniColors.cyan, 0.14),
              borderRadius: BorderRadius.circular(14),
              boxShadow: active
                  ? [BoxShadow(color: hexA(LuniColors.cyan, 0.3), blurRadius: 16)]
                  : null,
            ),
            child: Center(
              child: LuniIcon('walk',
                  size: 23,
                  strokeWidth: 1.9,
                  color: _off ? LuniColors.txFaint : LuniColors.cyan),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CƠ THỂ ROBOT', style: LuniTextStyles.cap),
                const SizedBox(height: 1),
                Text(
                  _off ? 'Ngoại tuyến' : _dirVi[_dir]!,
                  style: LuniTextStyles.h3.copyWith(
                    color: _off
                        ? LuniColors.txMute
                        : (_moving ? LuniColors.cyan : LuniColors.tx),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('6 động cơ',
                  style: LuniTextStyles.mono
                      .copyWith(fontSize: 11, color: LuniColors.txFaint)),
              const SizedBox(height: 2),
              Text(d.model,
                  style: LuniTextStyles.mono
                      .copyWith(fontSize: 11, color: LuniColors.txFaint)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- camera (still only) ----------------
  Widget _cameraCard() {
    final off = _off;
    final topShot = _shots.isNotEmpty ? _shots.first : null;
    return IgnorePointer(
      ignoring: off,
      child: Opacity(
        opacity: off ? 0.55 : 1,
        child: LuniCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // viewfinder = the last still (no live video feed exists)
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PhotoFrame(
                        tone: topShot?.tone ?? LuniColors.cyan,
                        big: true,
                        viewfinder: true,
                        label: 'ẢNH GẦN NHẤT',
                      ),
                      ..._cornerBrackets(),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _glassPill(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              LuniIcon('image', size: 12, color: LuniColors.cyan),
                              SizedBox(width: 5),
                              Text('Ảnh tĩnh',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: LuniColors.txSoft)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0x9E05070D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(topShot?.time ?? '—',
                              style: LuniTextStyles.mono.copyWith(
                                  fontSize: 10, color: LuniColors.txSoft)),
                        ),
                      ),
                      if (_flash)
                        const ColoredBox(color: Color(0xEBF0F4FF)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // capture controls
              Row(
                children: [
                  _CamChip(
                    icon: 'flash',
                    label: _flashMode == 'off'
                        ? 'Tắt đèn'
                        : _flashMode == 'auto'
                            ? 'Đèn tự động'
                            : 'Bật đèn',
                    active: _flashMode != 'off',
                    onTap: () => setState(() => _flashMode = _flashMode == 'off'
                        ? 'auto'
                        : _flashMode == 'auto'
                            ? 'on'
                            : 'off'),
                  ),
                  const SizedBox(width: 10),
                  _CamChip(
                    icon: 'clock',
                    label: _timer != 0 ? 'Hẹn ${_timer}s' : 'Không hẹn',
                    active: _timer != 0,
                    onTap: () => setState(() => _timer = _timer == 0
                        ? 3
                        : _timer == 3
                            ? 10
                            : 0),
                  ),
                  const Spacer(),
                  Press(
                    onTap: _capture,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: LuniColors.cyan,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF06222B), width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: hexA(LuniColors.cyan, 0.6),
                              blurRadius: 22,
                              spreadRadius: -6,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Center(
                        child: LuniIcon('camera',
                            size: 26,
                            strokeWidth: 2,
                            color: LuniColors.onCyan),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerBrackets() {
    const len = 16.0;
    const m = 8.0;
    const col = Color(0x73EAF0FF);
    Widget bracket({double? top, double? left, double? bottom, double? right}) {
      return Positioned(
        top: top,
        left: left,
        bottom: bottom,
        right: right,
        child: Container(
          width: len,
          height: len,
          decoration: BoxDecoration(
            border: Border(
              top: top != null ? const BorderSide(color: col, width: 2) : BorderSide.none,
              left: left != null ? const BorderSide(color: col, width: 2) : BorderSide.none,
              bottom: bottom != null ? const BorderSide(color: col, width: 2) : BorderSide.none,
              right: right != null ? const BorderSide(color: col, width: 2) : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      bracket(top: m, left: m),
      bracket(top: m, right: m),
      bracket(bottom: m, left: m),
      bracket(bottom: m, right: m),
    ];
  }

  Widget _glassPill({required Widget child}) => Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x9E05070D),
          borderRadius: BorderRadius.circular(999),
        ),
        child: child,
      );

  // ---------------- gallery ----------------
  Widget _galleryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('ẢNH ĐÃ CHỤP', style: LuniTextStyles.cap),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text('${_shots.length} ảnh',
              style: LuniTextStyles.mono
                  .copyWith(fontSize: 10.5, color: LuniColors.txFaint)),
        ),
      ],
    );
  }

  Widget _gallery() {
    if (_shots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text('Chưa có ảnh nào.', style: LuniTextStyles.sub),
      );
    }
    return Opacity(
      opacity: _off ? 0.55 : 1,
      child: SizedBox(
        height: 95,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _shots.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final p = _shots[i];
            return Press(
              onTap: () => _openPhoto(p),
              child: SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: SizedBox(
                        width: 96,
                        height: 72,
                        child: _PhotoFrame(tone: p.tone),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(p.time,
                        style: LuniTextStyles.mono
                            .copyWith(fontSize: 10, color: LuniColors.txFaint)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPhoto(_Shot p) {
    showLuniSheet(
      context: context,
      title: 'Ảnh đã chụp',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _PhotoFrame(tone: p.tone, big: true, label: 'ẢNH ROBOT'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 12, 2, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1600×1200 · JPEG',
                    style: LuniTextStyles.mono
                        .copyWith(fontSize: 11, color: LuniColors.txFaint)),
                Text(p.time,
                    style: LuniTextStyles.mono
                        .copyWith(fontSize: 11, color: LuniColors.txFaint)),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: LuniGhostButton(
                  label: 'Lưu',
                  icon: 'download',
                  onPressed: () {
                    Navigator.pop(ctx);
                    luniToast(context, 'Đã lưu vào máy');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DangerButton(
                  label: 'Xoá',
                  icon: 'trash',
                  onPressed: () {
                    setState(() =>
                        _shots = _shots.where((s) => s.id != p.id).toList());
                    Navigator.pop(ctx);
                    luniToast(context, 'Đã xoá ảnh',
                        icon: 'trash', color: LuniColors.red);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- locomotion (4 leg motors) ----------------
  Widget _locomotionCard() {
    final off = _off;
    return IgnorePointer(
      ignoring: off,
      child: Opacity(
        opacity: off ? 0.55 : 1,
        child: LuniCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _DPad(dir: _dir, onDrive: _drive),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (var i = 0; i < _legAngles.length; i++) ...[
                    Expanded(child: _legBar(_legAngles[i], _motorMeta[i].id)),
                    if (i < _legAngles.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legBar(int angle, String id) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: LuniColors.bg2)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 500),
                    curve: LuniTokens.ease,
                    widthFactor: 1,
                    heightFactor: (angle / 180).clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _moving
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [LuniColors.cyan, Color(0xFF2AA9C4)],
                              )
                            : null,
                        color: _moving ? null : LuniColors.bg3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text('$angle°',
            style: LuniTextStyles.mono.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _moving ? LuniColors.cyan : LuniColors.txMute)),
        Text(id,
            style: LuniTextStyles.mono
                .copyWith(fontSize: 9, color: LuniColors.txFaint)),
      ],
    );
  }

  // ---------------- poses ----------------
  Widget _poses(bool off) {
    return IgnorePointer(
      ignoring: off,
      child: Opacity(
        opacity: off ? 0.55 : 1,
        child: Row(
          children: [
            Expanded(
              child: _PoseAction(
                icon: 'arrowUp',
                label: 'Đứng',
                onTap: () {
                  setState(() => _dir = 'stop');
                  luniToast(context, 'Tư thế đứng',
                      icon: 'walk', color: LuniColors.cyan);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PoseAction(
                icon: 'arrowDown',
                label: 'Ngồi',
                onTap: () {
                  setState(() => _dir = 'stop');
                  luniToast(context, 'Tư thế ngồi',
                      icon: 'walk', color: LuniColors.cyan);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PoseAction(
                icon: 'hand',
                label: 'Cúi chào',
                onTap: () => _gesture('Luni cúi chào', 30, 30, 'hand'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- arms (2 motors) ----------------
  Widget _armGestures(bool off) {
    const gestures = [
      ('Vẫy tay 👋', 18, 165, 'hand'),
      ('Giơ hai tay', 168, 168, 'arrowUp'),
      ('Chỉ tay', 12, 150, 'arrowRight'),
      ('Hạ tay', 10, 10, 'arrowDown'),
    ];
    return IgnorePointer(
      ignoring: off,
      child: Opacity(
        opacity: off ? 0.55 : 1,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, l, r, icon) in gestures)
              Press(
                onTap: () => _gesture(label, l, r, icon),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: LuniColors.bg2,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: LuniColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LuniIcon(icon,
                          size: 15, strokeWidth: 2, color: LuniColors.cyan),
                      const SizedBox(width: 8),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: LuniColors.txSoft)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _armDials(bool off) {
    return IgnorePointer(
      ignoring: off,
      child: Opacity(
        opacity: off ? 0.55 : 1,
        child: LuniCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _ArmDial(
                label: 'Tay trái',
                id: 'M5',
                value: _armL,
                onChanged: (v) => setState(() => _armL = v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _ArmDial(
                label: 'Tay phải',
                id: 'M6',
                value: _armR,
                onChanged: (v) => setState(() => _armR = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- motor diagnostics (6 motors) ----------------
  Widget _motorDiagnostics(bool off) {
    return LuniCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < _motorMeta.length; i++)
            _motorRow(i, _motorMeta[i], last: i == _motorMeta.length - 1),
        ],
      ),
    );
  }

  Widget _motorRow(int i, _MotorMeta m, {required bool last}) {
    final off = _off;
    final angle = m.part == 'leg'
        ? _legAngles[m.leg]
        : (m.armKey == 'armL' ? _armL : _armR);
    final active = m.part == 'leg' && _moving;
    final limit = angle <= 8 || angle >= 172;

    final (String statusText, Color statusColor) = off
        ? ('Mất kết nối', LuniColors.txFaint)
        : limit
            ? ('Giới hạn', LuniColors.orange)
            : active
                ? ('Hoạt động', LuniColors.cyan)
                : ('Sẵn sàng', LuniColors.green);

    final isLeg = m.part == 'leg';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: LuniColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(m.id,
                style: LuniTextStyles.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LuniColors.txMute)),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: hexA(isLeg ? LuniColors.cyan : LuniColors.rose, 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: LuniIcon(isLeg ? 'walk' : 'hand',
                  size: 17,
                  strokeWidth: 1.8,
                  color: isLeg ? LuniColors.cyan : LuniColors.rose),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    text: m.name,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: ' · ${m.joint}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            color: LuniColors.txMute),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(off ? '—' : '$angle°',
                        style: LuniTextStyles.mono.copyWith(
                            fontSize: 10.5, color: LuniColors.txFaint)),
                    const SizedBox(width: 12),
                    const LuniIcon('temp', size: 11, color: LuniColors.txFaint),
                    const SizedBox(width: 3),
                    Text(off ? '—' : '${_motorTemp[i] + (active ? 3 : 0)}°C',
                        style: LuniTextStyles.mono.copyWith(
                            fontSize: 10.5, color: LuniColors.txFaint)),
                  ],
                ),
              ],
            ),
          ),
          LuniPill(
            label: statusText,
            color: statusColor,
            showDot: true,
            glowDot: !off,
          ),
        ],
      ),
    );
  }

  // ---------------- shared bits ----------------
  Widget _infoNote(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: LuniIcon('info', size: 14, color: LuniColors.txFaint),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11.5, color: LuniColors.txFaint, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

/// Section header: an overline label on the left + a mono ws-route hint right.
class _MotionHeader extends StatelessWidget {
  const _MotionHeader(this.title, {required this.meta});
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: LuniTextStyles.over),
          Text(meta,
              style: LuniTextStyles.mono
                  .copyWith(fontSize: 10.5, color: LuniColors.txFaint)),
        ],
      ),
    );
  }
}

/// Striped placeholder standing in for a still captured by the robot camera.
class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({
    required this.tone,
    this.big = false,
    this.viewfinder = false,
    this.label = 'ẢNH ROBOT',
  });

  final Color tone;
  final bool big;
  final bool viewfinder;
  final String label;

  static const String _res = '1600×1200';

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(tone),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // faint rule-of-thirds
          CustomPaint(
            painter: _ThirdsPainter(opacity: viewfinder ? 0.5 : 0.22),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LuniIcon('image',
                    size: big ? 30 : 17,
                    strokeWidth: 1.6,
                    color: hexA(tone, 0.8)),
                if (big) ...[
                  const SizedBox(height: 7),
                  Text('$label · $_res',
                      style: LuniTextStyles.mono.copyWith(
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                          color: LuniColors.txFaint)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.tone);
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = LuniColors.bg2);
    final strong = Paint()..color = hexA(tone, 0.17);
    final faint = Paint()..color = hexA(tone, 0.055);
    // diagonal stripes (~125deg), 11px bands alternating strong/faint
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    const band = 11.0;
    final diag = size.width + size.height;
    canvas.translate(0, 0);
    canvas.rotate(-0.61); // ~ -35deg so bands run ~125deg
    for (double x = -diag; x < diag * 2; x += band * 2) {
      canvas.drawRect(Rect.fromLTWH(x, -diag, band, diag * 3), strong);
      canvas.drawRect(Rect.fromLTWH(x + band, -diag, band, diag * 3), faint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) => old.tone != tone;
}

class _ThirdsPainter extends CustomPainter {
  _ThirdsPainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = hexA(const Color(0xFFEAF0FF), 0.18 * opacity)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height), p);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), p);
    canvas.drawLine(Offset(0, size.height / 3),
        Offset(size.width, size.height / 3), p);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), p);
  }

  @override
  bool shouldRepaint(covariant _ThirdsPainter old) => old.opacity != opacity;
}

/// Directional drive pad (3×3 with blanks at the corners).
class _DPad extends StatelessWidget {
  const _DPad({required this.dir, required this.onDrive});
  final String dir;
  final void Function(String) onDrive;

  @override
  Widget build(BuildContext context) {
    Widget cell(String nd, String icon) {
      final on = dir == nd;
      final isStop = nd == 'stop';
      return Press(
        onTap: () => onDrive(nd),
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: LuniTokens.ease,
            decoration: BoxDecoration(
              color: on
                  ? (isStop ? hexA(LuniColors.orange, 0.18) : LuniColors.cyan)
                  : LuniColors.bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: on
                    ? (isStop ? hexA(LuniColors.orange, 0.5) : Colors.transparent)
                    : LuniColors.hairline,
              ),
              boxShadow: on && !isStop
                  ? [
                      BoxShadow(
                          color: hexA(LuniColors.cyan, 0.55),
                          blurRadius: 18,
                          spreadRadius: -6,
                          offset: const Offset(0, 6))
                    ]
                  : null,
            ),
            child: Center(
              child: LuniIcon(icon,
                  size: isStop ? 22 : 26,
                  strokeWidth: 2.1,
                  color: on
                      ? (isStop ? LuniColors.orange : LuniColors.onCyan)
                      : LuniColors.txSoft),
            ),
          ),
        ),
      );
    }

    const blank = SizedBox.shrink();
    Widget row(List<Widget> cells) => Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(child: cells[i]),
              if (i < cells.length - 1) const SizedBox(width: 10),
            ],
          ],
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 232),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row([blank, cell('up', 'arrowUp'), blank]),
          const SizedBox(height: 10),
          row([cell('left', 'arrowLeft'), cell('stop', 'stop'), cell('right', 'arrowRight')]),
          const SizedBox(height: 10),
          row([blank, cell('down', 'arrowDown'), blank]),
        ],
      ),
    );
  }
}

class _PoseAction extends StatelessWidget {
  const _PoseAction({required this.icon, required this.label, required this.onTap});
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: LuniColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LuniColors.hairline),
        ),
        child: Column(
          children: [
            LuniIcon(icon, size: 21, strokeWidth: 1.9, color: LuniColors.txSoft),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LuniColors.txSoft)),
          ],
        ),
      ),
    );
  }
}

/// Arm angle dial — drives one shoulder motor (0–180°).
class _ArmDial extends StatelessWidget {
  const _ArmDial({
    required this.label,
    required this.id,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String id;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const LuniIcon('hand',
                      size: 17, strokeWidth: 1.8, color: LuniColors.rose),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text(id,
                      style: LuniTextStyles.mono
                          .copyWith(fontSize: 10, color: LuniColors.txFaint)),
                ],
              ),
              Text('$value°',
                  style: LuniTextStyles.mono.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LuniColors.rose)),
            ],
          ),
        ),
        LuniSlider(
          value: value,
          onChanged: onChanged,
          color: LuniColors.warm,
          min: 0,
          max: 180,
          showPercent: false,
        ),
      ],
    );
  }
}

class _CamChip extends StatelessWidget {
  const _CamChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: active ? hexA(LuniColors.cyan, 0.12) : LuniColors.bg2,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: active ? hexA(LuniColors.cyan, 0.4) : LuniColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LuniIcon(icon,
                size: 15,
                strokeWidth: 1.9,
                color: active ? LuniColors.cyan : LuniColors.txFaint),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? LuniColors.cyan : LuniColors.txMute)),
          ],
        ),
      ),
    );
  }
}
