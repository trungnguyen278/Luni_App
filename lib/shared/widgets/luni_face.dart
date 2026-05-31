import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../../core/lunar/lunar_calendar.dart';

/// Eye-shape archetypes (the `face` field in the design's LUNI_EMOTIONS map).
enum LuniEyes { idle, arc, sad, angry, sleepy, curious, wide, oval }

/// Animated state of the face.
enum LuniFaceState { idle, listening, speaking, thinking }

class LuniEmotionData {
  const LuniEmotionData(this.color, this.eyes, this.label, {this.settable = false});
  final Color color;
  final LuniEyes eyes;
  final String label;

  /// Whether the firmware can be commanded into this emotion (SET_EMOTION).
  final bool settable;
}

/// The 16 emotions ported from `ui_design/luni-face.jsx` (LUNI_EMOTIONS).
const Map<String, LuniEmotionData> kLuniEmotions = {
  'neutral': LuniEmotionData(LuniColors.cyan, LuniEyes.idle, 'Bình thường', settable: true),
  'idle': LuniEmotionData(LuniColors.cyan, LuniEyes.idle, 'Bình thường'),
  'happy': LuniEmotionData(LuniColors.warm, LuniEyes.arc, 'Vui vẻ', settable: true),
  'excited': LuniEmotionData(LuniColors.warm, LuniEyes.wide, 'Phấn khích', settable: true),
  'curious': LuniEmotionData(LuniColors.orange, LuniEyes.curious, 'Tò mò', settable: true),
  'confused': LuniEmotionData(LuniColors.orange, LuniEyes.curious, 'Bối rối', settable: true),
  'annoyed': LuniEmotionData(LuniColors.orange, LuniEyes.angry, 'Khó chịu', settable: true),
  'nervous': LuniEmotionData(LuniColors.orange, LuniEyes.curious, 'Lo lắng', settable: true),
  'calm': LuniEmotionData(LuniColors.blue, LuniEyes.oval, 'Thư giãn', settable: true),
  'cool': LuniEmotionData(LuniColors.cyan, LuniEyes.oval, 'Ngầu', settable: true),
  'thinking': LuniEmotionData(LuniColors.cyan, LuniEyes.idle, 'Đang nghĩ', settable: true),
  'sad': LuniEmotionData(LuniColors.blue, LuniEyes.sad, 'Buồn', settable: true),
  'angry': LuniEmotionData(LuniColors.red, LuniEyes.angry, 'Giận', settable: true),
  'disgusted': LuniEmotionData(LuniColors.green, LuniEyes.sad, 'Ghê', settable: true),
  'love': LuniEmotionData(LuniColors.rose, LuniEyes.arc, 'Yêu thích'),
  'sleepy': LuniEmotionData(LuniColors.purple, LuniEyes.sleepy, 'Buồn ngủ'),
  'alert': LuniEmotionData(LuniColors.red, LuniEyes.wide, 'Cảnh báo'),
};

LuniEmotionData luniEmotion(String? key) =>
    kLuniEmotions[key] ?? kLuniEmotions['idle']!;

/// The signature animated robot face: a glowing "moon" disc with expressive
/// eyes that morph per emotion. Port of `ui_design/luni-face.jsx`.
class LuniFace extends StatefulWidget {
  const LuniFace({
    super.key,
    this.emotion = 'idle',
    this.size = 160,
    this.state = LuniFaceState.idle,
    this.dim = false,
    this.phase,
    this.noPhase = false,
    this.onTap,
  });

  final String emotion;
  final double size;
  final LuniFaceState state;
  final bool dim;

  /// Override lunar phase 0..1 (null = use tonight's real moon).
  final double? phase;

  /// Hide the lunar phase shadow on the orb.
  final bool noPhase;
  final VoidCallback? onTap;

  @override
  State<LuniFace> createState() => _LuniFaceState();
}

class _LuniFaceState extends State<LuniFace> with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _blink; // 1 = open, 0 = closed
  late final AnimationController _radar;
  late final AnimationController _wave;
  Timer? _blinkTimer;
  final _rng = math.Random();

  Duration get _breatheDur {
    switch (widget.emotion) {
      case 'sleepy':
      case 'calm':
        return const Duration(milliseconds: 5500);
      case 'alert':
        return const Duration(milliseconds: 1600);
      default:
        return const Duration(milliseconds: 3600);
    }
  }

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(vsync: this, duration: _breatheDur)
      ..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      value: 1,
    );
    _radar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _applyState();
    if (!widget.dim) _scheduleBlink();
  }

  void _applyState() {
    if (widget.state == LuniFaceState.listening && !widget.dim) {
      _radar.repeat();
    } else {
      _radar.stop();
    }
    if ((widget.state == LuniFaceState.speaking ||
            widget.state == LuniFaceState.thinking) &&
        !widget.dim) {
      _wave.repeat();
    } else {
      _wave.stop();
    }
  }

  void _scheduleBlink() {
    if (!mounted || widget.dim) return;
    final next = 2200 + _rng.nextInt(3600);
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(milliseconds: next), () async {
      if (!mounted || widget.dim) return;
      await _blink.reverse(); // close
      if (!mounted) return;
      await _blink.forward(); // open
      _scheduleBlink();
    });
  }

  @override
  void didUpdateWidget(covariant LuniFace old) {
    super.didUpdateWidget(old);
    if (old.emotion != widget.emotion) _breathe.duration = _breatheDur;
    if (old.state != widget.state || old.dim != widget.dim) _applyState();
    if (old.dim && !widget.dim) _scheduleBlink();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breathe.dispose();
    _blink.dispose();
    _radar.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final em = luniEmotion(widget.emotion);
    final color = widget.dim ? LuniColors.txFaint : em.color;
    final eyes = widget.dim ? LuniEyes.sleepy : em.eyes;
    final s = widget.size;

    // Robot rule: the eyes (and mouth wave) are ALWAYS cyan — only the glow,
    // orb tint and accessory glyphs carry the emotion tone. Keeps Luni's gaze
    // identical to the app icon.
    final eyeColor = widget.dim ? LuniColors.txFaint : LuniColors.cyan;

    // Luni IS the moon: the orb wears tonight's phase and its glow breathes
    // with the moon's brightness (rực rỡ ở Rằm, mờ dịu ở Mùng Một).
    final pVal = widget.phase ?? LuniMoon.today().p;
    final illum = widget.dim ? 0.0 : (1 - math.cos(2 * math.pi * pVal)) / 2;
    final showPhase = !widget.dim && !widget.noPhase;
    final moonF = widget.dim ? 1.0 : (0.45 + 0.55 * illum);
    final glowInset = widget.dim ? 0.22 : (15 + illum * 13) / 100;

    final face = AnimatedBuilder(
      animation: Listenable.merge([_breathe, _blink, _radar, _wave]),
      builder: (context, _) {
        final breatheT = Curves.easeInOut.transform(_breathe.value);
        final orbScale = widget.dim ? 1.0 : 1 + 0.035 * breatheT;
        final glowOpacity = widget.dim ? 0.0 : (0.55 + 0.35 * breatheT);
        final glowScale = widget.dim ? 1.0 : (1 + 0.08 * breatheT);

        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // outer glow — inset + opacity scale with the moon's brightness
              Positioned(
                left: -s * glowInset,
                top: -s * glowInset,
                right: -s * glowInset,
                bottom: -s * glowInset,
                child: Transform.scale(
                  scale: glowScale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          hexA(
                              color,
                              widget.dim
                                  ? 0.12
                                  : 0.42 * moonF * glowOpacity / 0.9),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.62],
                      ),
                    ),
                  ),
                ),
              ),

              // listening radar rings
              if (widget.state == LuniFaceState.listening && !widget.dim)
                ...List.generate(3, (i) {
                  final t = (_radar.value + i * 0.33) % 1.0;
                  final scale = 0.3 + t * (2.4 - 0.3);
                  final opacity = (0.7 * (1 - t)).clamp(0.0, 0.7);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: s,
                      height: s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hexA(color, 0.5 * opacity / 0.7),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),

              // the orb
              Transform.scale(
                scale: orbScale,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment(-0.5, -1),
                      end: Alignment(0.5, 1),
                      colors: [Color(0xFF161B29), Color(0xFF0C0F18)],
                    ),
                    border: Border.all(
                      color: hexA(color, widget.dim ? 0.14 : 0.34),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: hexA(
                            color, widget.dim ? 0.0 : (0.05 + 0.14 * illum)),
                        blurRadius: 30,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // top-left tint
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.36, -0.48),
                              radius: 0.9,
                              colors: [
                                hexA(color, widget.dim ? 0.08 : 0.20),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6],
                            ),
                          ),
                        ),
                        // bottom rim crescent
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(0.0, 1.0),
                              radius: 0.7,
                              colors: [hexA(color, 0.14), Colors.transparent],
                              stops: const [0.0, 0.55],
                            ),
                          ),
                        ),
                        // phase shadow — the orb shows tonight's lunar phase
                        if (showPhase)
                          CustomPaint(painter: _PhaseShadowPainter(pVal)),
                        // eyes (always cyan)
                        CustomPaint(
                          painter: _EyesPainter(
                            eyes: eyes,
                            color: eyeColor,
                            blink: _blink.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // speaking / thinking mouth-wave
              if ((widget.state == LuniFaceState.speaking ||
                      widget.state == LuniFaceState.thinking) &&
                  !widget.dim)
                Positioned(
                  bottom: s * 0.14,
                  child: _MouthWave(
                    color: eyeColor,
                    size: s,
                    speaking: widget.state == LuniFaceState.speaking,
                    t: _wave.value,
                  ),
                ),

              // accessory glyphs
              if (!widget.dim && _accessory(color, s) != null)
                _accessory(color, s)!,
            ],
          ),
        );
      },
    );

    if (widget.onTap == null) return face;
    return GestureDetector(onTap: widget.onTap, child: face);
  }

  Widget? _accessory(Color color, double s) {
    final floatT = math.sin(_breathe.value * math.pi) * 7;
    Widget wrap(Widget child) => Positioned(
          top: -s * 0.06 + floatT,
          right: s * 0.02,
          child: child,
        );
    switch (widget.emotion) {
      case 'love':
        return wrap(Icon(Icons.favorite, size: s * 0.16, color: color));
      case 'sleepy':
        return wrap(Text('z',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: s * 0.14)));
      case 'curious':
        return wrap(Text('?',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: s * 0.2)));
      default:
        return null;
    }
  }
}

class _MouthWave extends StatelessWidget {
  const _MouthWave({
    required this.color,
    required this.size,
    required this.speaking,
    required this.t,
  });
  final Color color;
  final double size;
  final bool speaking;
  final double t;

  @override
  Widget build(BuildContext context) {
    final h = size * 0.12;
    final barW = size * 0.028;
    return SizedBox(
      height: h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (i) {
          // thinkDot: bob up at 40% of cycle, staggered by 0.12.
          final phase = (t + 1 - i * 0.12) % 1.0;
          final up = (1 - (phase - 0.4).abs() / 0.4).clamp(0.0, 1.0);
          final base = speaking ? 1.0 : 0.4;
          final barH = h * base * (0.55 + 0.45 * up);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.0125),
            child: Container(
              width: barW,
              height: barH,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: hexA(color, 0.8), blurRadius: 6)],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Draws the eyes in a 100x100 viewBox, scaled to the orb. Mirrors the `Eyes`
/// component geometry in `luni-face.jsx`.
class _EyesPainter extends CustomPainter {
  _EyesPainter({required this.eyes, required this.color, required this.blink});

  final LuniEyes eyes;
  final Color color;
  final double blink; // 1 open .. 0.08 closed

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale);
    // blink: scaleY around center (50,50)
    final sy = (0.08 + 0.92 * blink).clamp(0.08, 1.0);
    canvas.translate(0, 50);
    canvas.scale(1, sy);
    canvas.translate(0, -50);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final glow = Paint()
      ..color = hexA(color, 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    Paint stroke(double w) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    void drawWithGlow(Path p, Paint paint) {
      canvas.drawPath(
        p,
        Paint()
          ..color = hexA(color, 0.6)
          ..style = paint.style
          ..strokeWidth = paint.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(p, paint);
    }

    // Chunky rounded-rect eye centered at (cx,cy) — matches the robot display
    // (EmotionCore). Mirrors `eyeRect()` in the updated luni-face.jsx.
    const eLx = 33.0, eRx = 67.0, eCy = 50.0; // left/right centers, vertical
    const eW = 23.0, eH = 27.0, eRX = 7.0; // base chunky eye
    RRect eyeRect(double cx, double cy, double w, double h, double rx) {
      final hh = math.max(h, 1.0);
      final r = math.min(rx, math.min(w / 2, hh / 2));
      return RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: w, height: hh),
          Radius.circular(r));
    }

    void fillWithGlow(Path p) {
      canvas.drawPath(p, glow);
      canvas.drawPath(p, fill);
    }

    switch (eyes) {
      case LuniEyes.arc: // happy — fat upward smile arcs ⌣ ⌣
        final p = Path()
          ..moveTo(eLx - 11, eCy - 2)
          ..quadraticBezierTo(eLx, eCy + 12, eLx + 11, eCy - 2)
          ..moveTo(eRx - 11, eCy - 2)
          ..quadraticBezierTo(eRx, eCy + 12, eRx + 11, eCy - 2);
        drawWithGlow(p, stroke(9));
        break;
      case LuniEyes.sad: // downturned arcs ⌢ ⌢
        final p = Path()
          ..moveTo(eLx - 11, eCy + 6)
          ..quadraticBezierTo(eLx, eCy - 7, eLx + 11, eCy + 6)
          ..moveTo(eRx - 11, eCy + 6)
          ..quadraticBezierTo(eRx, eCy - 7, eRx + 11, eCy + 6);
        drawWithGlow(p, stroke(9));
        break;
      case LuniEyes.angry: // chunky eyes under slanted brow lids
        fillWithGlow(Path()
          ..addRRect(eyeRect(eLx, eCy + 4, eW, 22, eRX))
          ..addRRect(eyeRect(eRx, eCy + 4, eW, 22, eRX)));
        final brows = Path()
          ..moveTo(eLx - 12, eCy - 16)
          ..lineTo(eLx + 12, eCy - 9)
          ..moveTo(eRx + 12, eCy - 16)
          ..lineTo(eRx - 12, eCy - 9);
        drawWithGlow(brows, stroke(7));
        break;
      case LuniEyes.sleepy: // soft closed eyes — shallow arcs
        final p = Path()
          ..moveTo(eLx - 12, eCy)
          ..quadraticBezierTo(eLx, eCy + 6, eLx + 12, eCy)
          ..moveTo(eRx - 12, eCy)
          ..quadraticBezierTo(eRx, eCy + 6, eRx + 12, eCy);
        drawWithGlow(p, stroke(8));
        break;
      case LuniEyes.curious: // asymmetric "huh?" — one tall, one squished
        fillWithGlow(Path()
          ..addRRect(eyeRect(eLx, eCy, eW, 30, eRX))
          ..addRRect(eyeRect(eRx, eCy + 2, eW + 2, 17, 8)));
        break;
      case LuniEyes.wide: // excited / surprised — big chunky eyes, no pupils
        fillWithGlow(Path()
          ..addRRect(eyeRect(eLx, eCy, eW + 3, eH + 4, 9))
          ..addRRect(eyeRect(eRx, eCy, eW + 3, eH + 4, 9)));
        break;
      case LuniEyes.oval: // calm / cool — relaxed half-lidded chunky rects
        fillWithGlow(Path()
          ..addRRect(eyeRect(eLx, eCy, eW, 16, 8))
          ..addRRect(eyeRect(eRx, eCy, eW, 16, 8)));
        break;
      case LuniEyes.idle: // signature chunky rounded-rect eyes
        fillWithGlow(Path()
          ..addRRect(eyeRect(eLx, eCy, eW, eH, eRX))
          ..addRRect(eyeRect(eRx, eCy, eW, eH, eRX)));
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EyesPainter old) =>
      old.eyes != eyes || old.color != color || old.blink != blink;
}

/// Paints tonight's lunar terminator as a soft dark shadow over the orb, so
/// Luni "wears" the moon's phase (đổi theo 30 ngày). Port of the SVG phase
/// mask in `luni-face.jsx`.
class _PhaseShadowPainter extends CustomPainter {
  _PhaseShadowPainter(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    const r = 48.0;
    const c = Offset(50, 50);
    final cos = math.cos(2 * math.pi * p);
    final illum = (1 - cos) / 2;
    final waxing = p < 0.5;
    final gibbous = illum > 0.5;
    final rx = r * cos.abs();

    final disc = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final semi = Path()
      ..moveTo(50, 50 - r)
      ..arcToPoint(const Offset(50, 50 + r),
          radius: const Radius.circular(r), clockwise: waxing)
      ..close();
    final ellipse = Path()
      ..addOval(Rect.fromCenter(center: c, width: rx * 2, height: r * 2));

    // lit region: gibbous bulges (union), crescent carves (difference)
    final lit = gibbous
        ? Path.combine(PathOperation.union, semi, ellipse)
        : Path.combine(PathOperation.difference, semi, ellipse);
    final dark = Path.combine(PathOperation.difference, disc, lit);

    canvas.drawPath(
      dark,
      Paint()
        ..color = const Color(0x9905060B) // #05060b @ .6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.3)
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PhaseShadowPainter old) => old.p != p;
}

/// A tiny mood dot used in lists/headers.
class MoodDot extends StatelessWidget {
  const MoodDot({super.key, this.emotion = 'idle', this.size = 10, this.dim = false});
  final String emotion;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = dim ? LuniColors.txFaint : luniEmotion(emotion).color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: dim ? null : [BoxShadow(color: hexA(c, 0.8), blurRadius: 8)],
      ),
    );
  }
}
