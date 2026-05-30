import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import 'luni_kit.dart';

class LuniErrorState extends StatelessWidget {
  const LuniErrorState({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: hexA(LuniColors.red, 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: LuniIcon('alert', size: 30, color: LuniColors.red),
              ),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: LuniTextStyles.body),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 200,
                child: LuniGhostButton(
                    label: 'Thử lại', icon: 'refresh', onPressed: onRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
