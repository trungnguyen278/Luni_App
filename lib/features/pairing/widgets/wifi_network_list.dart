import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_kit.dart';

class WifiNetworkList extends StatelessWidget {
  const WifiNetworkList({required this.onSelected, super.key});

  final ValueChanged<String> onSelected;

  static const _networks = ['LuniLab', 'Home-5G', 'Office-IoT'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final network in _networks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Press(
              onTap: () => onSelected(network),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: LuniColors.bg2,
                  borderRadius: BorderRadius.circular(LuniTokens.radius),
                  border: Border.all(color: LuniColors.hairline),
                ),
                child: Row(
                  children: [
                    const LuniIcon('wifi', size: 18, color: LuniColors.cyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(network,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                    ),
                    const LuniIcon('lock', size: 15, color: LuniColors.txFaint),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
