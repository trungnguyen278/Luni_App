import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import 'luni_icon.dart';

/// Global feedback toast — Flutter port of the design's `luniToast()` bus.
/// A glass pill at the bottom-center that auto-hides after ~1.9s. Replaces
/// Material `SnackBar` so feedback matches the Luni look everywhere.
///
/// Usage: `luniToast(context, 'Đã lưu')` or
/// `luniToast(context, 'Đã xoá', icon: 'trash', color: LuniColors.red)`.
void luniToast(
  BuildContext context,
  String message, {
  String icon = 'check',
  Color color = LuniColors.green,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  // Replace any toast currently showing.
  _activeEntry?.remove();
  _activeEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _LuniToast(
      message: message,
      icon: icon,
      color: color,
      onDismissed: () {
        if (_activeEntry == entry) {
          entry.remove();
          _activeEntry = null;
        }
      },
    ),
  );
  _activeEntry = entry;
  overlay.insert(entry);
}

OverlayEntry? _activeEntry;

class _LuniToast extends StatefulWidget {
  const _LuniToast({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismissed,
  });

  final String message;
  final String icon;
  final Color color;
  final VoidCallback onDismissed;

  @override
  State<_LuniToast> createState() => _LuniToastState();
}

class _LuniToastState extends State<_LuniToast> {
  bool _shown = false;
  Timer? _hideTimer;

  static const _inDur = Duration(milliseconds: 300);
  static const _outDur = Duration(milliseconds: 200);
  static const _hold = Duration(milliseconds: 1900);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _shown = true);
      _hideTimer = Timer(_hold + _inDur, _hide);
    });
  }

  void _hide() {
    if (!mounted) return;
    setState(() => _shown = false);
    Timer(_outDur, widget.onDismissed);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
              child: AnimatedScale(
                scale: _shown ? 1 : 0.92,
                duration: _shown ? _inDur : _outDur,
                curve: _shown ? LuniTokens.spring : LuniTokens.ease,
                child: AnimatedOpacity(
                  opacity: _shown ? 1 : 0,
                  duration: _shown ? _inDur : _outDur,
                  curve: LuniTokens.ease,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0E121C),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: LuniColors.hairline2),
                          boxShadow: LuniTokens.shadowPop,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LuniIcon(widget.icon,
                                size: 17, color: widget.color, strokeWidth: 2.4),
                            const SizedBox(width: 9),
                            Flexible(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: LuniColors.tx,
                                    height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
