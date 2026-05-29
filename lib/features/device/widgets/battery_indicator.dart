import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';

class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({
    required this.percent,
    required this.isCharging,
    super.key,
  });

  final int percent;
  final bool isCharging;

  @override
  Widget build(BuildContext context) {
    final color = percent <= 15
        ? LuniColors.red
        : isCharging
        ? LuniColors.green
        : LuniColors.cyan;

    return Row(
      children: [
        Icon(
          isCharging ? Icons.battery_charging_full : Icons.battery_5_bar,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 100) / 100,
              minHeight: 8,
              color: color,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            '$percent%',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
