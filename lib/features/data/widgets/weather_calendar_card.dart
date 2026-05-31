import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../providers/sync_data_provider.dart';

/// Home card showing server-sourced weather + lunar date for a device.
///
/// Renders `GET /data/sync/{deviceId}`. Weather may be absent (no device
/// coordinates or no OpenWeather key) — in that case only the lunar row shows.
/// Stays silent on error so it never blocks the home screen.
class WeatherCalendarCard extends ConsumerWidget {
  const WeatherCalendarCard({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncDataProvider(deviceId));

    return sync.when(
      loading: () => const _CardShell(
        child: SizedBox(
          height: 64,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: LuniColors.cyan),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.weather == null && data.lunar == null) {
          return const SizedBox.shrink();
        }
        return _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.weather != null) _WeatherRow(data: data),
              if (data.weather != null && data.lunar != null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
              if (data.lunar != null) _LunarRow(lunar: data.lunar!),
            ],
          ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LuniCard(child: child),
    );
  }
}

class _WeatherRow extends StatelessWidget {
  const _WeatherRow({required this.data});
  final SyncData data;

  @override
  Widget build(BuildContext context) {
    final w = data.weather!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${w.temp.round()}°',
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 2),
            Text(w.conditionLabel, style: LuniTextStyles.sub),
            if (data.city != null && data.city!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(data.city!,
                  style: const TextStyle(
                      fontSize: 12, color: LuniColors.txMute)),
            ],
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Stat(label: 'Cảm giác', value: '${w.feelsLike.round()}°'),
            const SizedBox(height: 6),
            _Stat(label: 'Độ ẩm', value: '${w.humidity}%'),
            if (w.aqi != null) ...[
              const SizedBox(height: 6),
              _Stat(label: 'AQI', value: '${w.aqi}'),
            ],
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label  ',
            style: const TextStyle(fontSize: 12, color: LuniColors.txMute)),
        Text(value,
            style:
                const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _LunarRow extends StatelessWidget {
  const _LunarRow({required this.lunar});
  final SyncLunar lunar;

  @override
  Widget build(BuildContext context) {
    final leap = lunar.isLeapMonth ? ' (nhuận)' : '';
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: hexA(LuniColors.purple, 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
              child: LuniIcon('calendar', size: 17, color: LuniColors.purple)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Âm lịch ${lunar.day}/${lunar.month}$leap',
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w600)),
            if (lunar.year.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Năm ${lunar.year}',
                  style: const TextStyle(
                      fontSize: 12, color: LuniColors.txMute)),
            ],
          ],
        ),
      ],
    );
  }
}
