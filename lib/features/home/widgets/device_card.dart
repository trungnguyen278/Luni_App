import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../shared/models/device.dart';
import '../../device/widgets/battery_indicator.dart';
import 'quick_action_bar.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    required this.device,
    required this.onOpen,
    required this.onChat,
    required this.onMute,
    required this.onReboot,
    super.key,
  });

  final Device device;
  final VoidCallback onOpen;
  final VoidCallback onChat;
  final VoidCallback onMute;
  final VoidCallback onReboot;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.Hm();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.smart_toy_outlined, color: _statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${device.location} · ${device.fwVersion}',
                          style: const TextStyle(color: LuniColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(isOnline: device.isOnline),
                ],
              ),
              const SizedBox(height: 16),
              BatteryIndicator(
                percent: device.batteryPercent,
                isCharging: device.isCharging,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    icon: Icons.sentiment_satisfied_alt,
                    label: device.emotion,
                  ),
                  _MetricChip(
                    icon: Icons.dashboard_customize_outlined,
                    label: device.scene,
                  ),
                  _MetricChip(icon: Icons.wifi, label: '${device.rssi} dBm'),
                  _MetricChip(
                    icon: Icons.schedule,
                    label: device.isOnline
                        ? 'live'
                        : 'seen ${timeFormat.format(device.lastSeen)}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              QuickActionBar(
                onChat: onChat,
                onMute: onMute,
                onReboot: onReboot,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    if (device.isOnline) {
      return LuniColors.green;
    }
    return LuniColors.orange;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (isOnline ? LuniColors.green : LuniColors.orange).withValues(
          alpha: 0.16,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          isOnline ? 'ONLINE' : 'OFFLINE',
          style: TextStyle(
            color: isOnline ? LuniColors.green : LuniColors.orange,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
