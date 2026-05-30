import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/ws_client.dart';
import '../../../shared/models/log_entry.dart';
import '../../../shared/widgets/luni_kit.dart';

class LogViewerScreen extends ConsumerStatefulWidget {
  const LogViewerScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends ConsumerState<LogViewerScreen> {
  final List<LogEntry> _logs = [];
  bool _loading = true;
  StreamSubscription<DeviceWsEvent>? _wsSub;
  LogLevel? _filterLevel;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<List<dynamic>>(
        '/devices/${widget.deviceId}/logs',
        queryParameters: {'limit': 100},
      );
      final data = response.data ?? [];
      _logs.addAll(
        data.whereType<Map<String, Object?>>().map(_logFromJson),
      );
    } catch (_) {
      // offline or API not available
    }

    if (mounted) setState(() => _loading = false);

    _wsSub = ref.read(wsClientProvider).events
        .where((e) => e.type == DeviceWsEventType.log)
        .listen((event) {
      if (!mounted) return;
      final p = event.payload;
      setState(() {
        _logs.insert(
          0,
          LogEntry(
            id: _logs.length + 1,
            deviceId: widget.deviceId,
            level: _levelFromString(p['level'] as String?),
            tag: p['tag'] as String? ?? '',
            message: p['message'] as String? ?? '',
            createdAt: DateTime.now(),
          ),
        );
      });
    });
  }

  List<LogEntry> get _filteredLogs {
    if (_filterLevel == null) return _logs;
    return _logs.where((l) => l.level == _filterLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: LuniColors.cyan));
    }

    final logs = _filteredLogs;
    final formatter = DateFormat.Hms();

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            children: [
              _FilterChip(
                label: 'ALL',
                selected: _filterLevel == null,
                onTap: () => setState(() => _filterLevel = null),
              ),
              for (final level in LogLevel.values) ...[
                const SizedBox(width: 8),
                _FilterChip(
                  label: level.label.toUpperCase(),
                  selected: _filterLevel == level,
                  onTap: () => setState(() => _filterLevel = level),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? const Center(
                  child: Text('Không có log nào.', style: LuniTextStyles.sub))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LogBadge(level: log.level),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.message,
                                  style: LuniTextStyles.mono.copyWith(
                                      fontSize: 12.5, color: LuniColors.tx)),
                              const SizedBox(height: 3),
                              Text(
                                '${log.tag} · ${formatter.format(log.createdAt)}',
                                style: const TextStyle(
                                    fontSize: 11.5, color: LuniColors.txFaint),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  itemCount: logs.length,
                ),
        ),
      ],
    );
  }

  LogEntry _logFromJson(Map<String, Object?> json) {
    return LogEntry(
      id: json['id'] as int? ?? 0,
      deviceId: json['device_id'] as String? ?? widget.deviceId,
      level: _levelFromString(json['level'] as String?),
      tag: json['tag'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      source: json['source'] as String? ?? 'device',
    );
  }

  LogLevel _levelFromString(String? value) {
    switch (value) {
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warn':
        return LogLevel.warn;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? LuniColors.cyan : LuniColors.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? Colors.transparent : LuniColors.hairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? LuniColors.onCyan : LuniColors.txMute,
          ),
        ),
      ),
    );
  }
}

class _LogBadge extends StatelessWidget {
  const _LogBadge({required this.level});

  final LogLevel level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      LogLevel.debug => LuniColors.purple,
      LogLevel.info => LuniColors.cyan,
      LogLevel.warn => LuniColors.orange,
      LogLevel.error => LuniColors.red,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 58,
        height: 34,
        child: Center(
          child: Text(
            level.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
