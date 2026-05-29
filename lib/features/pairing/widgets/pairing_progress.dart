import 'package:flutter/material.dart';

import '../providers/pairing_notifier.dart';

class PairingProgress extends StatelessWidget {
  const PairingProgress({required this.stage, super.key});

  final PairingStage stage;

  @override
  Widget build(BuildContext context) {
    final index = PairingStage.values.indexOf(stage).clamp(0, 12);
    const total = 13;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(stage.label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('${index + 1}/$total'),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: (index + 1) / total),
      ],
    );
  }
}
