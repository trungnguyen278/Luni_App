import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';

class EmotionPicker extends StatelessWidget {
  const EmotionPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _emotions = [
    ('happy', Icons.sentiment_very_satisfied, LuniColors.warm),
    ('curious', Icons.psychology_alt_outlined, LuniColors.orange),
    ('love', Icons.favorite_border, LuniColors.rose),
    ('sleepy', Icons.bedtime_outlined, LuniColors.purple),
    ('calm', Icons.water_drop_outlined, LuniColors.blue),
    ('alert', Icons.notification_important_outlined, LuniColors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final emotion in _emotions)
          ChoiceChip(
            selected: selected == emotion.$1,
            avatar: Icon(emotion.$2, color: emotion.$3, size: 18),
            label: Text(emotion.$1),
            onSelected: (_) => onChanged(emotion.$1),
          ),
      ],
    );
  }
}
