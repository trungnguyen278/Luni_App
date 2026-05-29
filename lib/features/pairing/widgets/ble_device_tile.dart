import 'package:flutter/material.dart';

import '../../../core/bluetooth/ble_scanner.dart';
import '../../../core/config/theme.dart';

class BleDeviceTile extends StatelessWidget {
  const BleDeviceTile({required this.device, required this.onTap, super.key});

  final BleScanDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bluetooth, color: LuniColors.cyan),
      title: Text(device.name),
      subtitle: Text('${device.id} · ${device.model}'),
      trailing: Text('${device.rssi} dBm'),
      onTap: onTap,
    );
  }
}
