import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/luni_kit.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  List<int> _bars = [];
  String _uptime = '--';
  String _audioMinutes = '--';
  String _warnings = '--';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, Object?>>(
        '/devices/${widget.deviceId}/stats',
        queryParameters: {'days': 7},
      );
      final data = response.data ?? {};

      final daily = data['daily_interactions'] as List<dynamic>? ?? [];
      _bars = daily.map((e) => (e as num).toInt()).toList();

      _uptime = data['uptime_today'] as String? ?? '--';
      _audioMinutes = data['audio_minutes'] as String? ?? '--';
      _warnings = '${data['warnings'] ?? 0}';
    } catch (_) {
      // fallback empty
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: LuniColors.cyan));
    }

    final total = _bars.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: 'chat',
                color: LuniColors.cyan,
                value: '$total',
                label: 'Tương tác (7 ngày)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                icon: 'clock',
                color: LuniColors.green,
                value: _uptime,
                label: 'Uptime hôm nay',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: 'wave',
                color: LuniColors.rose,
                value: _audioMinutes,
                label: 'Audio đã phát',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                icon: 'alert',
                color: LuniColors.orange,
                value: _warnings,
                label: 'Cảnh báo',
              ),
            ),
          ],
        ),
        const SectionLabel('Tương tác 7 ngày'),
        LuniCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: _bars.isEmpty
              ? const SizedBox(
                  height: 160,
                  child: Center(
                      child: Text('Chưa có dữ liệu.', style: LuniTextStyles.sub)),
                )
              : _BarChart(bars: _bars),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final String icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LuniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hexA(color, 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(child: LuniIcon(icon, size: 18, color: color)),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 4),
          Text(label, style: LuniTextStyles.sub),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars});
  final List<int> bars;

  @override
  Widget build(BuildContext context) {
    final max = bars.reduce((a, b) => a > b ? a : b).clamp(1, 99999);
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < bars.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${bars[i]}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: LuniColors.txMute,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 600 + i * 60),
                    curve: LuniTokens.spring,
                    tween: Tween(begin: 0, end: bars[i] / max),
                    builder: (context, t, _) => Container(
                      height: (110 * t).clamp(3, 110),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            i == bars.length - 1
                                ? LuniColors.cyan
                                : hexA(LuniColors.cyan, 0.4),
                            i == bars.length - 1
                                ? hexA(LuniColors.cyan, 0.7)
                                : hexA(LuniColors.cyan, 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(i < labels.length ? labels[i] : '',
                      style: const TextStyle(
                          fontSize: 11, color: LuniColors.txFaint)),
                ],
              ),
            ),
            if (i < bars.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
