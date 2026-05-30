import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

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
    this.onTap,
  });

  final String emotion;
  final double size;
  final LuniFaceState state;
  final bool dim;
  final VoidCallback? onTap;

  @override
  State<LuniFace> createState() => _LuniFaceState();
}

class _LuniFaceState extends State<LuniFace> with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _blink; // 1 = open, 0 = closed
  late final AnimationController _radar;
  late final AnimationController _wave;
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
    Future.delayed(Duration(milliseconds: next), () async {
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
              // outer glow
              Positioned(
                left: -s * 0.22,
                top: -s * 0.22,
                right: -s * 0.22,
                bottom: -s * 0.22,
                child: Transform.scale(
                  scale: glowScale,
                  child: Opacity(
                    opacity: widget.dim ? 1 : 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            hexA(color, widget.dim ? 0.12 : 0.42 * glowOpacity / 0.9),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.62],
                        ),
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
                        color: hexA(color, widget.dim ? 0.0 : 0.12),
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
                        // eyes
                        CustomPaint(
                          painter: _EyesPainter(
                            eyes: eyes,
                            color: color,
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
                    color: color,
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

    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    switch (eyes) {
      case LuniEyes.arc:
        final p = Path()
          ..moveTo(24, 47)
          ..quadraticBezierTo(34, 60, 44, 47)
          ..moveTo(56, 47)
          ..quadraticBezierTo(66, 60, 76, 47);
        drawWithGlow(p, stroke(7));
        break;
      case LuniEyes.sad:
        final p = Path()
          ..moveTo(24, 56)
          ..quadraticBezierTo(34, 45, 44, 56)
          ..moveTo(56, 56)
          ..quadraticBezierTo(66, 45, 76, 56);
        drawWithGlow(p, stroke(7));
        break;
      case LuniEyes.angry:
        final eyesP = Path()
          ..addRRect(rr(28, 42, 13, 22, 6))
          ..addRRect(rr(59, 42, 13, 22, 6));
        canvas.drawPath(eyesP, glow);
        canvas.drawPath(eyesP, fill);
        final brows = Path()
          ..moveTo(26, 34)
          ..lineTo(44, 40)
          ..moveTo(74, 34)
          ..lineTo(56, 40);
        drawWithGlow(brows, stroke(6));
        break;
      case LuniEyes.sleepy:
        final p = Path()
          ..moveTo(24, 51)
          ..quadraticBezierTo(34, 56, 44, 51)
          ..moveTo(56, 51)
          ..quadraticBezierTo(66, 56, 76, 51);
        drawWithGlow(p, stroke(6.5));
        break;
      case LuniEyes.curious:
        final p = Path()
          ..addRRect(rr(27, 36, 13, 28, 6.5))
          ..addOval(Rect.fromCircle(center: const Offset(66, 49), radius: 11));
        canvas.drawPath(p, glow);
        canvas.drawPath(p, fill);
        break;
      case LuniEyes.wide:
        final p = Path()
          ..addOval(Rect.fromCircle(center: const Offset(34, 49), radius: 12.5))
          ..addOval(Rect.fromCircle(center: const Offset(66, 49), radius: 12.5));
        canvas.drawPath(p, glow);
        canvas.drawPath(p, fill);
        final pupil = Paint()..color = const Color(0xFF0A0C14);
        canvas.drawCircle(const Offset(34, 49), 4.5, pupil);
        canvas.drawCircle(const Offset(66, 49), 4.5, pupil);
        break;
      case LuniEyes.oval:
        final p = Path()
          ..addRRect(rr(27, 42, 14, 16, 7))
          ..addRRect(rr(59, 42, 14, 16, 7));
        canvas.drawPath(p, glow);
        canvas.drawPath(p, fill);
        break;
      case LuniEyes.idle:
        final p = Path()
          ..addRRect(rr(28, 36, 13, 28, 6.5))
          ..addRRect(rr(59, 36, 13, 28, 6.5));
        canvas.drawPath(p, glow);
        canvas.drawPath(p, fill);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EyesPainter old) =>
      old.eyes != eyes || old.color != color || old.blink != blink;
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
