import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../providers/pairing_notifier.dart';

class PairingProgress extends StatelessWidget {
  const PairingProgress({required this.stage, super.key});

  final PairingStage stage;

  @override
  Widget build(BuildContext context) {
    final index = PairingStage.values.indexOf(stage).clamp(0, 12);
    const total = 13;
    final value = (index + 1) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(stage.label, style: LuniTextStyles.h3)),
            Text('${index + 1}/$total',
                style: LuniTextStyles.mono
                    .copyWith(fontSize: 12.5, color: LuniColors.txMute)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            duration: LuniTokens.durScreen,
            curve: LuniTokens.ease,
            tween: Tween(begin: 0, end: value),
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: LuniColors.bg3,
              valueColor: const AlwaysStoppedAnimation(LuniColors.cyan),
            ),
          ),
        ),
      ],
    );
  }
}
