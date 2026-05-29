import 'package:flutter/material.dart';

import '../../../shared/widgets/luni_app_bar.dart';

class PairingDoneScreen extends StatelessWidget {
  const PairingDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuniAppBar(title: 'Hoàn tất'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'Robot đã online',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
