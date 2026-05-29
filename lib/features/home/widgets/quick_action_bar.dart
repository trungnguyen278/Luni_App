import 'package:flutter/material.dart';

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
        IconButton.filledTonal(
          onPressed: onChat,
          tooltip: 'Chat',
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onMute,
          tooltip: 'Tắt tiếng',
          icon: const Icon(Icons.volume_off_outlined),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onReboot,
          tooltip: 'Khởi động lại',
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    );
  }
}
