import 'package:flutter/material.dart';

import '../../../core/bluetooth/ble_scanner.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_kit.dart';

class BleDeviceTile extends StatelessWidget {
  const BleDeviceTile({required this.device, required this.onTap, super.key});

  final BleScanDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LuniCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hexA(LuniColors.cyan, 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                  child: LuniIcon('bluetooth', size: 22, color: LuniColors.cyan)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(device.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${device.id} · ${device.model}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuniTextStyles.mono.copyWith(
                          fontSize: 11.5, color: LuniColors.txMute)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LuniIcon('signal', size: 14, color: LuniColors.txFaint),
                const SizedBox(width: 4),
                Text('${device.rssi}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: LuniColors.txSoft)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
