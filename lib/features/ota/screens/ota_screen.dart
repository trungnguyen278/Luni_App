import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/ws_client.dart';
import '../../../shared/models/firmware.dart';
import '../../../shared/widgets/luni_kit.dart';

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
      return const Center(
          child: CircularProgressIndicator(color: LuniColors.cyan));
    }

    final isAvailable =
        _firmware != null && _firmware!.version != widget.currentVersion;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        // current firmware
        LuniCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hexA(LuniColors.purple, 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: LuniIcon('cpu', size: 22, color: LuniColors.purple)),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Firmware hiện tại',
                      style:
                          TextStyle(fontSize: 13, color: LuniColors.txMute)),
                  const SizedBox(height: 2),
                  Text('v${widget.currentVersion}',
                      style: LuniTextStyles.mono.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: LuniColors.tx)),
                ],
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: LuniColors.red)),
        ],
        const SizedBox(height: 12),
        // update status
        LuniCard(
          gradient: isAvailable
              ? LinearGradient(
                  colors: [hexA(LuniColors.warm, 0.1), LuniColors.bg1])
              : null,
          border: Border.all(
              color: isAvailable
                  ? hexA(LuniColors.warm, 0.25)
                  : LuniColors.hairline),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LuniIcon(isAvailable ? 'download' : 'check',
                      size: 22,
                      strokeWidth: 2.2,
                      color: isAvailable ? LuniColors.warm : LuniColors.green),
                  const SizedBox(width: 10),
                  Text(isAvailable ? 'Có bản cập nhật' : 'Đã mới nhất',
                      style: LuniTextStyles.h3),
                  const Spacer(),
                  if (isAvailable)
                    LuniPill(
                        label: _firmware!.channel, color: LuniColors.warm),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isAvailable
                    ? 'Phiên bản ${_firmware!.version}'
                    : 'Không có firmware mới cho model này.',
                style: const TextStyle(color: LuniColors.txMute, fontSize: 13.5),
              ),
              if (isAvailable && _firmware!.changelog.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LuniColors.bg2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_firmware!.changelog,
                      style: const TextStyle(
                          color: LuniColors.txSoft, fontSize: 13, height: 1.5)),
                ),
              ],
              if (isAvailable) ...[
                const SizedBox(height: 16),
                if (_updating)
                  _OtaProgress(progress: _progress, phase: _phase)
                else
                  LuniCta(
                      label: 'Triển khai OTA',
                      icon: 'download',
                      onPressed: _startOta),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: LuniIcon('info', size: 14, color: LuniColors.txFaint),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Robot sẽ tự khởi động lại sau khi cập nhật. Đảm bảo pin trên 40% hoặc đang sạc.',
                  style: TextStyle(
                      fontSize: 11.5, color: LuniColors.txFaint, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OtaProgress extends StatelessWidget {
  const _OtaProgress({required this.progress, required this.phase});
  final double progress;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 10,
            backgroundColor: LuniColors.bg3,
            valueColor: const AlwaysStoppedAnimation(LuniColors.cyan),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(phase,
                  style: const TextStyle(
                      fontSize: 13, color: LuniColors.txSoft)),
            ),
            Text('${progress.toInt()}%',
                style: LuniTextStyles.mono.copyWith(
                    fontWeight: FontWeight.w700, color: LuniColors.cyan)),
          ],
        ),
      ],
    );
  }
}
