import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';

class ScenePicker extends StatelessWidget {
  const ScenePicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _scenes = [
    ('home', Icons.home_outlined, LuniColors.cyan),
    ('weather', Icons.cloud_outlined, LuniColors.blue),
    ('clock', Icons.schedule, LuniColors.warm),
    ('calendar', Icons.event_outlined, LuniColors.green),
    ('sleep', Icons.nightlight_outlined, LuniColors.purple),
    ('music', Icons.graphic_eq, LuniColors.rose),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final scene in _scenes)
          ChoiceChip(
            selected: selected == scene.$1,
            avatar: Icon(scene.$2, color: scene.$3, size: 18),
            label: Text(scene.$1),
            onSelected: (_) => onChanged(scene.$1),
          ),
      ],
    );
  }
}
