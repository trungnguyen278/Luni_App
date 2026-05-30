import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_kit.dart';

/// A row of quick-action tiles (chat / mute / reboot) used on the hub overview.
class QuickActionBar extends StatelessWidget {
  const QuickActionBar({
    required this.onChat,
    required this.onReboot,
    required this.onMute,
    super.key,
  });

  final VoidCallback onChat;
  final VoidCallback onReboot;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _QuickAction(
                icon: 'chat',
                label: 'Trò chuyện',
                color: LuniColors.cyan,
                onTap: onChat)),
        const SizedBox(width: 10),
        Expanded(
            child: _QuickAction(
                icon: 'volume',
                label: 'Tắt tiếng',
                color: LuniColors.orange,
                onTap: onMute)),
        const SizedBox(width: 10),
        Expanded(
            child: _QuickAction(
                icon: 'refresh',
                label: 'Khởi động lại',
                color: LuniColors.warm,
                onTap: onReboot)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: LuniColors.bg2,
          borderRadius: BorderRadius.circular(LuniTokens.radius),
          border: Border.all(color: LuniColors.hairline),
        ),
        child: Column(
          children: [
            LuniIcon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: LuniColors.txSoft)),
          ],
        ),
      ),
    );
  }
}
