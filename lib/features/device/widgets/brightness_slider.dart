import 'package:flutter/material.dart';

class BrightnessSlider extends StatelessWidget {
  const BrightnessSlider({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.light_mode_outlined),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '$value',
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        SizedBox(width: 44, child: Text('$value', textAlign: TextAlign.end)),
      ],
    );
  }
}
