import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/ws_client.dart';
import '../../../shared/models/log_entry.dart';

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
      return const Center(child: CircularProgressIndicator());
    }

    final logs = _filteredLogs;
    final formatter = DateFormat.Hms();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'ALL',
                selected: _filterLevel == null,
                onTap: () => setState(() => _filterLevel = null),
              ),
              for (final level in LogLevel.values) ...[
                const SizedBox(width: 6),
                _FilterChip(
                  label: level.label,
                  selected: _filterLevel == level,
                  onTap: () => setState(() => _filterLevel = level),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? const Center(child: Text('Không có log nào.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _LogBadge(level: log.level),
                      title: Text(log.message),
                      subtitle: Text(
                        '${log.tag} · ${formatter.format(log.createdAt)}',
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const Divider(height: 20),
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
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: selected
            ? LuniColors.cyan.withValues(alpha: 0.18)
            : null,
        side: selected
            ? const BorderSide(color: LuniColors.cyan)
            : null,
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
