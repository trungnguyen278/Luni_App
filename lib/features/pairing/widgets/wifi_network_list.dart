import 'package:flutter/material.dart';

import '../../../core/bluetooth/ble_connector.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_kit.dart';

class WifiNetworkList extends StatelessWidget {
  const WifiNetworkList({
    required this.networks,
    required this.onSelected,
    super.key,
  });

  final List<WifiNetwork> networks;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (networks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: LuniColors.bg2,
          borderRadius: BorderRadius.circular(LuniTokens.radius),
          border: Border.all(color: LuniColors.hairline),
        ),
        child: const Text(
          'Robot chưa thấy mạng nào. Nhập tên mạng (SSID) thủ công bên dưới.',
          style: LuniTextStyles.sub,
        ),
      );
    }

    return Column(
      children: [
        for (final network in networks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Press(
              onTap: () => onSelected(network.ssid),
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
                      child: Text(network.ssid,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                    ),
                    Text('${network.rssi} dBm',
                        style: LuniTextStyles.sub),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
