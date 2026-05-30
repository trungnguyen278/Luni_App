import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_kit.dart';

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
    final em = emotion == null ? null : luniEmotion(emotion);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isUser ? LuniColors.cyan : LuniColors.bg2,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 18),
            ),
            border: isUser ? null : Border.all(color: LuniColors.hairline),
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: isUser ? LuniColors.onCyan : LuniColors.tx,
                ),
              ),
              if (em != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoodDot(emotion: emotion!, size: 7),
                    const SizedBox(width: 6),
                    Text(em.label,
                        style: TextStyle(color: em.color, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
