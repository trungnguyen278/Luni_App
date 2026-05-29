import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.text,
    required this.isUser,
    this.emotion,
    super.key,
  });

  final String text;
  final bool isUser;
  final String? emotion;

  @override
  Widget build(BuildContext context) {
    final color = isUser ? LuniColors.cyan : LuniColors.bgElevated;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? color.withValues(alpha: 0.18) : color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(text),
                if (emotion != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    emotion!,
                    style: const TextStyle(
                      color: LuniColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
