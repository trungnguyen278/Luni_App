import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/theme.dart';
import '../../core/lunar/lunar_calendar.dart';
import 'luni_icon.dart';

/// The one canonical Luni moon glyph — a phase-aware moon icon that redraws
/// itself theo sự tròn khuyết. Port of `MoonGlyph` in `ui_design/luni-moon.jsx`.
class MoonGlyph extends StatelessWidget {
  const MoonGlyph({
    super.key,
    this.p = 0.5,
    this.size = 48,
    this.color = LuniColors.cyan,
    this.lit,
    this.dark = const Color(0xFF0B0F18),
    this.glow = true,
    this.ring = true,
    this.strokeOpacity = 0.4,
  });

  /// Synodic phase 0..1 (0 = new, .5 = full).
  final double p;
  final double size;
  final Color color;
  final Color? lit;
  final Color dark;
  final bool glow;
  final bool ring;
  final double strokeOpacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoonGlyphPainter(
          p: p,
          color: color,
          lit: lit ?? const Color(0xFFEAF2FF),
          dark: dark,
          glow: glow,
          ring: ring,
          strokeOpacity: strokeOpacity,
        ),
      ),
    );
  }
}

class _MoonGlyphPainter extends CustomPainter {
  _MoonGlyphPainter({
    required this.p,
    required this.color,
    required this.lit,
    required this.dark,
    required this.glow,
    required this.ring,
    required this.strokeOpacity,
  });

  final double p;
  final Color color;
  final Color lit;
  final Color dark;
  final bool glow;
  final bool ring;
  final double strokeOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    const r = 50.0, cx = 50.0, cy = 50.0;
    final cos = math.cos(2 * math.pi * p);
    final illum = (1 - cos) / 2;
    final waxing = p < 0.5;
    final rx = r * cos.abs();
    final gibbous = illum > 0.5;
    final acc = moonAccent(illum, color);
    final rimC = acc.kind == 'normal' ? color : acc.accent;
    final glowC = acc.kind == 'full'
        ? hexA(acc.accent, 0.6)
        : acc.kind == 'new'
            ? hexA(acc.accent, 0.42)
            : hexA(color, 0.55 * illum + 0.1);
    final glowR = acc.kind == 'full'
        ? 9.0
        : acc.kind == 'new'
            ? 3.5
            : 2 + illum * 6;

    // 1. dark disc
    canvas.drawCircle(
        const Offset(cx, cy), r, Paint()..color = dark..isAntiAlias = true);

    // 2. earthshine on the dark side (stronger at Sóc so the disc is felt)
    canvas.drawCircle(
      const Offset(cx, cy),
      r,
      Paint()
        ..color = hexA(acc.kind == 'new' ? acc.accent : color,
            acc.kind == 'new' ? 0.13 : 0.06)
        ..isAntiAlias = true,
    );

    // lit semicircle (right when waxing, left when waning)
    final semi = Path()..moveTo(cx, cy - r);
    semi.arcToPoint(const Offset(cx, cy + r),
        radius: const Radius.circular(r), clockwise: waxing);
    semi.close();
    final ellipseRect =
        Rect.fromCenter(center: const Offset(cx, cy), width: rx * 2, height: r * 2);

    final litShader = RadialGradient(
      center: const Alignment(-0.28, -0.36), // svg 36% 32%
      radius: 0.74,
      colors: acc.kind == 'full'
          ? const [Color(0xFFFFF6E0), Color(0xFFEAF2FF), Color(0xFFF2D58F)]
          : [lit, lit, const Color(0xFFB8CCEC)],
      stops: const [0.0, 0.74, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    final litPaint = Paint()
      ..shader = litShader
      ..isAntiAlias = true;

    // 3. glow halo behind the lit region
    if (glow && illum > 0.012) {
      final glowPaint = Paint()
        ..color = glowC
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowR)
        ..isAntiAlias = true;
      canvas.drawPath(semi, glowPaint);
      if (gibbous && rx > 0.4) canvas.drawOval(ellipseRect, glowPaint);
    }

    // 4. lit region: semicircle, then terminator ellipse (carves a crescent
    // when waning-thin, bulges to a gibbous when more than half lit)
    if (illum > 0.012) canvas.drawPath(semi, litPaint);
    if (rx > 0.4) {
      canvas.drawOval(
          ellipseRect, gibbous ? litPaint : (Paint()..color = dark..isAntiAlias = true));
    }

    // 5. craters hint on the lit area
    if (illum > 0.45) {
      final litLeft = waxing && !gibbous;
      final craterPaint = Paint()
        ..color = hexA(acc.kind == 'full' ? const Color(0xFFE9C97E) : const Color(0xFFC9DCF5),
            acc.kind == 'full' ? 0.42 : 0.5)
        ..isAntiAlias = true;
      canvas.drawCircle(Offset(litLeft ? 64 : 42, 37), 4, craterPaint);
      canvas.drawCircle(Offset(litLeft ? 58 : 56, 62), 6, craterPaint);
      canvas.drawCircle(Offset(litLeft ? 74 : 32, 56), 3, craterPaint);
    }

    // 6. rim ring — at the extremes it carries the special accent + weight
    if (ring) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = acc.kind == 'new' ? 2 : 1.4
        ..color = hexA(
            rimC,
            acc.kind == 'new'
                ? 0.85
                : acc.kind == 'full'
                    ? 0.6
                    : strokeOpacity)
        ..isAntiAlias = true;
      if (acc.kind == 'new' && glow) {
        ringPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(const Offset(cx, cy), r - 0.8, ringPaint);
        ringPaint.maskFilter = null;
      }
      canvas.drawCircle(const Offset(cx, cy), r - 0.8, ringPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoonGlyphPainter old) =>
      old.p != p ||
      old.color != color ||
      old.glow != glow ||
      old.ring != ring ||
      old.lit != lit ||
      old.strokeOpacity != strokeOpacity;
}

/// The Overview "Tuần trăng" card — Luni redraws icons theo âm lịch and shows
/// tonight's phase, lunar day, illumination, plus the special-day auto-mood
/// banner. Port of `MoonCard` in `ui_design/luni-moon.jsx`.
class MoonCard extends ConsumerWidget {
  const MoonCard({super.key, this.accent = LuniColors.cyan});
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(lunarTodayProvider);
    final sp = specialDay(info);
    final headColor = sp != null ? sp.color : accent;
    final pct = (info.illum * 100).round();
    final mono = LuniTextStyles.mono.copyWith(fontSize: 12, color: LuniColors.txSoft);

    return Container(
      decoration: BoxDecoration(
        color: LuniColors.bg1,
        borderRadius: BorderRadius.circular(LuniTokens.radius),
        border: Border.all(
            color: sp != null ? hexA(sp.color, 0.3) : hexA(accent, 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // hero strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.68, -1.1),
                radius: 1.1,
                colors: [hexA(headColor, 0.14), Colors.transparent],
                stops: const [0.0, 0.62],
              ),
            ),
            child: Row(
              children: [
                MoonGlyph(p: info.p, size: 70, color: headColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 7,
                        runSpacing: 4,
                        children: [
                          Text(info.phase.vi, style: LuniTextStyles.h3),
                          _tinyPill('Đêm nay', LuniColors.green),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(info.phase.sub,
                          style: const TextStyle(
                              fontSize: 12.5, color: LuniColors.txMute)),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Text.rich(
                            TextSpan(
                              style: mono,
                              children: [
                                const TextSpan(text: 'Âm lịch '),
                                TextSpan(
                                    text: '${info.lunarDay}',
                                    style: mono.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700)),
                                const TextSpan(text: '/30'),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: LuniColors.hairline2,
                          ),
                          Text('Sáng $pct%', style: mono),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // special-day banner — Luni auto-shifts mood
          if (sp != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                decoration: BoxDecoration(
                  color: hexA(sp.color, 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: hexA(sp.color, 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: hexA(sp.color, 0.16),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: LuniIcon(sp.kind == 'ram' ? 'sparkle' : 'moon',
                            size: 17, color: sp.color, strokeWidth: 2),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${sp.vi} · Luni tự đổi biểu cảm',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: sp.color)),
                          const SizedBox(height: 1),
                          Text(sp.desc,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: LuniColors.txMute,
                                  height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tinyPill(String label, Color color) => Container(
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hexA(color, 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      );
}
