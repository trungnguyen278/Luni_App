import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/network/api_client.dart';

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
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tương tác 7 ngày',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (_bars.isNotEmpty)
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in _bars) ...[
                  Expanded(
                    child: _UsageBar(
                      value: value,
                      max: _bars.reduce((a, b) => a > b ? a : b).clamp(1, 9999),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          )
        else
          const SizedBox(
            height: 180,
            child: Center(child: Text('Chưa có dữ liệu.')),
          ),
        const SizedBox(height: 24),
        _StatTile(
          icon: Icons.timer_outlined,
          label: 'Uptime hôm nay',
          value: _uptime,
          color: LuniColors.green,
        ),
        _StatTile(
          icon: Icons.graphic_eq,
          label: 'Audio đã phát',
          value: _audioMinutes,
          color: LuniColors.rose,
        ),
        _StatTile(
          icon: Icons.warning_amber_outlined,
          label: 'Cảnh báo',
          value: _warnings,
          color: LuniColors.orange,
        ),
      ],
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.value, required this.max});

  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$value'),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value / max,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LuniColors.cyan,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const SizedBox(width: double.infinity),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
