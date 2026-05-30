import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    this.label = 'Đang xử lý...',
    super.key,
  });

  final bool isLoading;
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: LuniColors.bgVoid.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: LuniColors.bg1,
                    borderRadius: BorderRadius.circular(LuniTokens.radius),
                    border: Border.all(color: LuniColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: LuniColors.cyan),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                          child: Text(label, style: LuniTextStyles.body)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
