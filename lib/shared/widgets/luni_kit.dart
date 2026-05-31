import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import 'luni_face.dart';
import 'luni_icon.dart';

export 'luni_face.dart';
export 'luni_icon.dart';

/// ============================================================
/// Luni UI kit — Flutter port of `ui_design/luni-ui.jsx` primitives.
/// ============================================================

/// Vietnamese scene labels (mirrors the design's SCENE_VI map).
const Map<String, String> kSceneVi = {
  'home': 'Trang chủ',
  'weather': 'Thời tiết',
  'clock': 'Đồng hồ',
  'calendar': 'Lịch',
  'sleep': 'Ngủ',
  'music': 'Nhạc',
};

String sceneLabel(String scene) => kSceneVi[scene] ?? scene;

/// Wraps a tappable child with the press feedback (scale 0.97).
class Press extends StatefulWidget {
  const Press({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: LuniTokens.durFast,
        curve: LuniTokens.ease,
        child: widget.child,
      ),
    );
  }
}

/// Surface card (bg-1 + hairline + radius 16).
class LuniCard extends StatelessWidget {
  const LuniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = LuniColors.bg1,
    this.radius = LuniTokens.radius,
    this.border,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Border? border;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: LuniColors.hairline),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Press(onTap: onTap, child: box);
  }
}

/// Elevated surface (bg-2).
class LuniCard2 extends StatelessWidget {
  const LuniCard2({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = LuniTokens.radius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      LuniCard(color: LuniColors.bg2, padding: padding, radius: radius, onTap: onTap, child: child);
}

/// Uppercase section label (`.t-over`).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text,
      {super.key, this.padding = const EdgeInsets.fromLTRB(4, 22, 4, 10)});
  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(text.toUpperCase(), style: LuniTextStyles.over),
      );
}

/// Primary call-to-action button (54h, cyan, glow).
class LuniCta extends StatelessWidget {
  const LuniCta({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.color = LuniColors.cyan,
    this.foreground = LuniColors.onCyan,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final bool loading;
  final Color color;
  final Color foreground;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = Container(
      height: 54,
      width: expand ? double.infinity : null,
      padding: expand ? null : const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(LuniTokens.radius),
        boxShadow: enabled ? LuniTokens.glow(color) : null,
      ),
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  LuniIcon(icon!, size: 20, color: foreground, strokeWidth: 2.2),
                  const SizedBox(width: 10),
                ],
                Text(label,
                    style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.16)),
              ],
            ),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Press(onTap: enabled ? onPressed : null, scale: 0.98, child: child),
    );
  }
}

/// Secondary outline button (54h, transparent).
class LuniGhostButton extends StatelessWidget {
  const LuniGhostButton(
      {super.key, required this.label, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onPressed,
      scale: 0.98,
      child: Container(
        height: 54,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LuniTokens.radius),
          border: Border.all(color: LuniColors.hairline2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              LuniIcon(icon!, size: 20, color: LuniColors.tx),
              const SizedBox(width: 10),
            ],
            Text(label,
                style: const TextStyle(
                    color: LuniColors.tx,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// 44x44 chrome icon button.
class LuniIconButton extends StatelessWidget {
  const LuniIconButton(
    this.icon, {
    super.key,
    this.onTap,
    this.size = 22,
    this.color = LuniColors.tx,
    this.tooltip,
  });

  final String icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = Press(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(child: LuniIcon(icon, size: size, color: color)),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// Generic colored pill (`.pill`).
class LuniPill extends StatelessWidget {
  const LuniPill({
    super.key,
    required this.label,
    required this.color,
    this.bg,
    this.showDot = false,
    this.glowDot = false,
    this.icon,
  });

  final String label;
  final Color color;
  final Color? bg;
  final bool showDot;
  final bool glowDot;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg ?? hexA(color, 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: glowDot
                    ? [BoxShadow(color: color, blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            LuniIcon(icon!, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12)),
        ],
      ),
    );
  }
}

/// Online/offline status pill.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final c = online ? LuniColors.green : LuniColors.txFaint;
    return LuniPill(
      label: online ? 'Trực tuyến' : 'Ngoại tuyến',
      color: c,
      showDot: true,
      glowDot: online,
    );
  }
}

/// Small chip with an icon + label (home device meta).
class MiniChip extends StatelessWidget {
  const MiniChip(
      {super.key, required this.icon, required this.color, required this.label});
  final String icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: LuniColors.bg2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LuniColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LuniIcon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: LuniColors.txSoft,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Custom 50x30 toggle switch.
class LuniToggle extends StatelessWidget {
  const LuniToggle({super.key, required this.value, this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: LuniTokens.ease,
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? LuniColors.cyan : LuniColors.bg3,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: LuniTokens.spring,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? LuniColors.onCyan : const Color(0xFF7A85A0),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A settings list row with an optional leading icon tile.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    this.icon,
    this.iconColor = LuniColors.txSoft,
    required this.label,
    this.sub,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String? icon;
  final Color iconColor;
  final String label;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final labelColor = danger ? LuniColors.red : LuniColors.tx;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: hexA(danger ? LuniColors.red : const Color(0xFF7D91B9), 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: LuniIcon(icon!,
                    size: 19, color: danger ? LuniColors.red : iconColor),
              ),
            ),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: labelColor)),
                if (sub != null) ...[
                  const SizedBox(height: 1),
                  Text(sub!,
                      style: const TextStyle(
                          fontSize: 12.5, color: LuniColors.txMute)),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            const LuniIcon('chevron', size: 18, color: LuniColors.txFaint),
        ],
      ),
    );
    if (onTap == null) return row;
    return Press(onTap: onTap, child: row);
  }
}

/// Battery indicator drawn to match the design's `Battery` component.
class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({
    super.key,
    required this.percent,
    this.charging = false,
    this.large = false,
  });

  final int percent;
  final bool charging;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final col = charging
        ? LuniColors.green
        : percent <= 15
            ? LuniColors.red
            : percent <= 35
                ? LuniColors.orange
                : LuniColors.txSoft;
    final w = large ? 44.0 : 30.0;
    final h = large ? 18.0 : 13.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: w + 4,
          height: h,
          child: CustomPaint(painter: _BatteryPainter(percent: percent, color: col)),
        ),
        const SizedBox(width: 6),
        Text('$percent%',
            style: TextStyle(
                color: col, fontWeight: FontWeight.w700, fontSize: large ? 15 : 13)),
        if (charging) ...[
          const SizedBox(width: 4),
          const LuniIcon('bolt', size: 13, color: LuniColors.green),
        ],
      ],
    );
  }
}

class _BatteryPainter extends CustomPainter {
  _BatteryPainter({required this.percent, required this.color});
  final int percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - 4;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(4));
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(body, stroke);
    // nub
    final nub = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w + 0.5, h * 0.275, 2.4, h * 0.45),
          const Radius.circular(2)),
      nub,
    );
    // fill
    final inset = 2.0;
    final fillW = ((w - inset * 2) * (percent / 100)).clamp(2.0, w - inset * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, fillW, h - inset * 2),
          const Radius.circular(2)),
      nub,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter old) =>
      old.percent != percent || old.color != color;
}

/// Circular progress ring with a glow (the design's `Ring`).
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.value, // 0..100
    this.size = 132,
    this.stroke = 9,
    this.color = LuniColors.cyan,
    this.track = LuniColors.bg2,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
                value: value.clamp(0, 100) / 100, stroke: stroke, color: color, track: track),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(
      {required this.value, required this.stroke, required this.color, required this.track});
  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, r, trackPaint);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final solid = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: r);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * value;
    canvas.drawArc(rect, start, sweep, false, arc);
    canvas.drawArc(rect, start, sweep, false, solid);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}

/// Glass bottom sheet matching the design's `Sheet`.
Future<T?> showLuniSheet<T>({
  required BuildContext context,
  String? title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xA8030508),
    builder: (ctx) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.82),
            decoration: BoxDecoration(
              color: const Color(0xB80E121C),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: const Border(
                top: BorderSide(color: LuniColors.hairline),
                left: BorderSide(color: LuniColors.hairline),
                right: BorderSide(color: LuniColors.hairline),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
                18, 10, 18, 22 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    margin: const EdgeInsets.only(top: 4, bottom: 14),
                    decoration: BoxDecoration(
                      color: LuniColors.hairline2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (title != null) ...[
                  Text(title, style: LuniTextStyles.h3),
                  const SizedBox(height: 14),
                ],
                Flexible(child: builder(ctx)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Screen-enter animation wrapper (`screen-anim`: fade + slide from right).
class ScreenIn extends StatefulWidget {
  const ScreenIn({super.key, required this.child});
  final Widget child;

  @override
  State<ScreenIn> createState() => _ScreenInState();
}

class _ScreenInState extends State<ScreenIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: LuniTokens.durScreen)
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: LuniTokens.ease);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.05, 0), end: Offset.zero)
            .animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// Styled text field (56h, bg-2 fill, cyan focus, optional leading icon).
class LuniField extends StatefulWidget {
  const LuniField({
    super.key,
    this.controller,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? hint;
  final String? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  State<LuniField> createState() => _LuniFieldState();
}

class _LuniFieldState extends State<LuniField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      style: const TextStyle(fontSize: 16, color: LuniColors.tx),
      cursorColor: LuniColors.cyan,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: LuniIcon(widget.icon!, size: 20, color: LuniColors.txMute),
              ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: widget.obscure
            ? Padding(
                padding: const EdgeInsets.only(right: 6),
                child: LuniIconButton(
                  _obscured ? 'eye' : 'eyeOff',
                  size: 20,
                  color: LuniColors.txMute,
                  onTap: () => setState(() => _obscured = !_obscured),
                ),
              )
            : null,
      ),
    );
  }
}

/// Draggable slider (52h, gradient fill) for volume/brightness.
class LuniSlider extends StatelessWidget {
  const LuniSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.icon,
    this.color = LuniColors.cyan,
    this.min = 0,
    this.max = 100,
    this.showPercent = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String? icon;
  final Color color;
  final int min;
  final int max;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        void setFromDx(double dx) {
          final p = (dx / c.maxWidth).clamp(0.0, 1.0);
          onChanged((min + p * (max - min)).round());
        }

        final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);
        return GestureDetector(
          onTapDown: (d) => setFromDx(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => setFromDx(d.localPosition.dx),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: LuniColors.bg2,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: pct,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [hexA(color, 0.22), hexA(color, 0.42)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (icon != null)
                        LuniIcon(icon!, size: 20, color: LuniColors.tx)
                      else
                        const SizedBox.shrink(),
                      Text(
                        showPercent ? '$value%' : '$value',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: LuniColors.tx),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A tab in a [LuniTabStrip].
class LuniTab {
  const LuniTab(this.id, this.icon, this.label);
  final String id;
  final String icon;
  final String label;
}

/// Horizontally-scrollable pill tab strip.
class LuniTabStrip extends StatelessWidget {
  const LuniTabStrip({
    super.key,
    required this.tabs,
    required this.active,
    required this.onSelect,
    this.accent = LuniColors.cyan,
  });

  final List<LuniTab> tabs;
  final String active;
  final ValueChanged<String> onSelect;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LuniColors.hairline)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            for (final t in tabs) ...[
              Press(
                onTap: () => onSelect(t.id),
                child: AnimatedContainer(
                  duration: LuniTokens.durBase,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: t.id == active ? accent : LuniColors.bg2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: t.id == active
                            ? Colors.transparent
                            : LuniColors.hairline),
                  ),
                  child: Row(
                    children: [
                      LuniIcon(t.icon,
                          size: 16,
                          strokeWidth: 2,
                          color: t.id == active
                              ? LuniColors.onCyan
                              : LuniColors.txMute),
                      const SizedBox(width: 7),
                      Text(t.label,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: t.id == active
                                  ? LuniColors.onCyan
                                  : LuniColors.txMute)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// A dashed-border rounded box (the home "add robot" tile).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    this.radius = 20,
    this.color = LuniColors.hairline2,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double radius;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(radius: radius, color: color),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.radius, required this.color});
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(
            metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// The "Luni" wordmark: face + name.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LuniFace(size: size * 1.5),
        const SizedBox(width: 10),
        Text('Luni',
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                letterSpacing: -size * 0.03,
                color: LuniColors.tx)),
      ],
    );
  }
}

/// A field with a small label above it (auth forms).
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.field});
  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LuniColors.txMute)),
        ),
        field,
      ],
    );
  }
}

/// Emotion chip (sparkle icon + Vietnamese label colored by emotion).
class MoodChip extends StatelessWidget {
  const MoodChip({super.key, required this.emotion});
  final String emotion;

  @override
  Widget build(BuildContext context) {
    final em = luniEmotion(emotion);
    return MiniChip(icon: 'sparkle', color: em.color, label: em.label);
  }
}

/// A small stat tile (icon + big number + label) used in profile/stats.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final String icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LuniCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          LuniIcon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: LuniColors.txMute)),
        ],
      ),
    );
  }
}

/// Outlined danger button (red, 52h).
class DangerButton extends StatelessWidget {
  const DangerButton(
      {super.key, required this.label, this.icon, this.onPressed});
  final String label;
  final String? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onPressed,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LuniTokens.radius),
          border: Border.all(color: hexA(LuniColors.red, 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              LuniIcon(icon!, size: 19, color: LuniColors.red),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: const TextStyle(
                    color: LuniColors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase label above a sheet input (`.t-cap`), mirrors `FieldLabel`.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text.toUpperCase(), style: LuniTextStyles.cap),
      );
}

/// Bottom action row for sheets — a ghost "Huỷ" + a primary/danger confirm.
/// Mirrors the design's `SheetActions`.
class SheetActions extends StatelessWidget {
  const SheetActions({
    super.key,
    this.onCancel,
    this.onSave,
    this.saveLabel = 'Lưu',
    this.cancelLabel = 'Huỷ',
    this.danger = false,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String saveLabel;
  final String cancelLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: LuniGhostButton(label: cancelLabel, onPressed: onCancel)),
        const SizedBox(width: 12),
        Expanded(
          child: LuniCta(
            label: saveLabel,
            color: danger ? LuniColors.red : LuniColors.cyan,
            foreground: danger ? LuniColors.tx : LuniColors.onCyan,
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}

/// An equal-width segmented selector (log level / language).
class LuniSegmented<T> extends StatelessWidget {
  const LuniSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 42,
    this.upper = false,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final bool upper;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(
            child: Press(
              onTap: () => onChanged(options[i].$1),
              child: Container(
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: options[i].$1 == value
                      ? LuniColors.cyan
                      : LuniColors.bg2,
                  borderRadius: BorderRadius.circular(upper ? 10 : 12),
                  border: Border.all(
                      color: options[i].$1 == value
                          ? Colors.transparent
                          : LuniColors.hairline),
                ),
                child: Text(
                  upper ? options[i].$2.toUpperCase() : options[i].$2,
                  style: TextStyle(
                    fontSize: upper ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: upper ? 0.3 : 0,
                    color: options[i].$1 == value
                        ? LuniColors.onCyan
                        : LuniColors.txMute,
                  ),
                ),
              ),
            ),
          ),
          if (i < options.length - 1) SizedBox(width: upper ? 6 : 8),
        ],
      ],
    );
  }
}
