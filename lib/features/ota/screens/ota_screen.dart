import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/ws_client.dart';
import '../../../shared/models/firmware.dart';

class OtaScreen extends ConsumerStatefulWidget {
  const OtaScreen({
    required this.deviceId,
    required this.currentVersion,
    super.key,
  });

  final String deviceId;
  final String currentVersion;

  @override
  ConsumerState<OtaScreen> createState() => _OtaScreenState();
}

class _OtaScreenState extends ConsumerState<OtaScreen> {
  Firmware? _firmware;
  bool _loading = true;
  bool _updating = false;
  String? _error;
  double _progress = 0;
  String _phase = '';
  StreamSubscription<DeviceWsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<Map<String, Object?>>(
        '/ota/check',
        queryParameters: {
          'device_id': widget.deviceId,
          'current_version': widget.currentVersion,
        },
      );

      final data = response.data ?? {};
      final available = data['available'] as bool? ?? false;

      if (available) {
        _firmware = Firmware(
          id: data['firmware_id'] as String? ?? '',
          version: data['version'] as String? ?? '',
          model: data['model'] as String? ?? '',
          sha256: data['sha256'] as String? ?? '',
          size: data['size'] as int? ?? 0,
          changelog: data['changelog'] as String? ?? '',
          channel: data['channel'] as String? ?? 'stable',
          createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }
    } catch (e) {
      _error = 'Không kiểm tra được OTA: $e';
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startOta() async {
    if (_firmware == null) return;

    setState(() {
      _updating = true;
      _progress = 0;
      _phase = 'Đang gửi lệnh OTA...';
    });

    _wsSub = ref.read(wsClientProvider).events
        .where((e) => e.type == DeviceWsEventType.otaProgress)
        .listen((event) {
      if (!mounted) return;
      setState(() {
        _progress = (event.payload['percent'] as num?)?.toDouble() ?? _progress;
        _phase = event.payload['phase'] as String? ?? _phase;
      });

      if (_progress >= 100) {
        setState(() {
          _updating = false;
          _phase = 'Hoàn tất! Robot đang khởi động lại.';
        });
        _wsSub?.cancel();
      }
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, Object?>>(
        '/devices/${widget.deviceId}/ota',
        data: {'firmware_id': _firmware!.id},
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _updating = false;
          _error = 'Lỗi OTA: $e';
        });
      }
      _wsSub?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAvailable = _firmware != null && _firmware!.version != widget.currentVersion;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.memory_outlined, color: LuniColors.cyan),
          title: const Text('Firmware hiện tại'),
          subtitle: Text(widget.currentVersion),
        ),
        const Divider(),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
        ],
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isAvailable ? Icons.system_update_alt : Icons.verified_outlined,
            color: isAvailable ? LuniColors.warm : LuniColors.green,
          ),
          title: Text(isAvailable ? 'Có bản cập nhật' : 'Đã mới nhất'),
          subtitle: Text(
            isAvailable
                ? '${_firmware!.version} · ${_firmware!.channel}'
                : 'Không có firmware mới cho model này.',
          ),
        ),
        if (isAvailable) ...[
          const SizedBox(height: 12),
          Text(
            _firmware!.changelog,
            style: const TextStyle(color: LuniColors.textMuted),
          ),
          const SizedBox(height: 20),
          if (_updating) ...[
            LinearProgressIndicator(value: _progress / 100),
            const SizedBox(height: 8),
            Text('$_phase — ${_progress.toInt()}%'),
          ] else
            FilledButton.icon(
              onPressed: _startOta,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Triển khai OTA'),
            ),
        ],
      ],
    );
  }
}
