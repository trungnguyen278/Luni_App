import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/lunar/lunar_calendar.dart';
import '../../../shared/models/device.dart';
import '../../../shared/widgets/luni_kit.dart';

/// Home device card — LuniFace + status + battery + meta chips.
/// Port of `DeviceCard` in `ui_design/screens-home.jsx`.
class DeviceCard extends ConsumerWidget {
  const DeviceCard({required this.device, required this.onOpen, super.key});

  final Device device;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = device.isOnline;
    // On Rằm / Mùng Một an online Luni auto-shifts to the night's mood.
    final sp = specialDay(ref.watch(lunarTodayProvider));
    final shownEmotion = (sp != null && online) ? sp.emotion : device.emotion;
    final em = luniEmotion(shownEmotion);

    return Press(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: online
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [hexA(em.color, 0.08), LuniColors.bg1],
                  stops: const [0.0, 0.55],
                )
              : null,
          color: online ? null : LuniColors.bg1,
          borderRadius: BorderRadius.circular(LuniTokens.radiusL),
          border: Border.all(
              color: online ? hexA(em.color, 0.2) : LuniColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LuniFace(emotion: shownEmotion, size: 66, dim: !online),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(device.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.17)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const LuniIcon('location',
                              size: 14, color: LuniColors.txFaint),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${device.location} · ${device.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: LuniColors.txMute, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          StatusPill(online: online),
                          const SizedBox(width: 10),
                          BatteryIndicator(
                            percent: device.batteryPercent,
                            charging: device.isCharging,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const LuniIcon('chevron', size: 20, color: LuniColors.txFaint),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MiniChip(icon: 'sparkle', color: em.color, label: em.label),
                MiniChip(
                    icon: 'grid',
                    color: LuniColors.txSoft,
                    label: sceneLabel(device.scene)),
                MiniChip(
                    icon: 'signal',
                    color: online ? LuniColors.txSoft : LuniColors.txFaint,
                    label: '${device.rssi} dBm'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
