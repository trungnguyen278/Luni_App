import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/models/device.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../providers/device_detail_notifier.dart';
import '../widgets/sharing_panel.dart';

class DeviceSettingsScreen extends ConsumerWidget {
  const DeviceSettingsScreen({
    required this.deviceId,
    this.embedded = false,
    super.key,
  });

  final String deviceId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = _SettingsContent(deviceId: deviceId);
    if (embedded) return content;
    return Scaffold(
      appBar: LuniAppBar(
          title: 'Cài đặt robot', onBack: () => context.go('/devices/$deviceId')),
      body: content,
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent({required this.deviceId});
  final String deviceId;

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  String? _logLevel;
  bool _autoOta = false;
  bool _push = true;
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(deviceDetailProvider(widget.deviceId));
    final user = ref.watch(authControllerProvider).user;

    if (device == null) {
      return const LuniErrorState(message: 'Không tìm thấy thiết bị.');
    }
    if (!_seeded) {
      _logLevel = device.config.logLevel;
      _autoOta = device.config.autoOta;
      _seeded = true;
    }
    final isAdmin = user?.role.isAdmin ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      children: [
        // header
        LuniCard(
          child: Row(
            children: [
              LuniFace(emotion: device.emotion, size: 56, dim: !device.isOnline),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(device.name, style: LuniTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(device.id,
                        style: LuniTextStyles.mono.copyWith(
                            fontSize: 11.5, color: LuniColors.txMute)),
                  ],
                ),
              ),
              StatusPill(online: device.isOnline),
            ],
          ),
        ),

        const SectionLabel('Thông tin'),
        LuniCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingRow(icon: 'edit', label: 'Tên robot', sub: device.name, onTap: () {}),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                  icon: 'location',
                  label: 'Vị trí',
                  sub: '${device.location} · ${device.city}',
                  onTap: () {}),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                  icon: 'globe',
                  label: 'Múi giờ',
                  sub: device.timezone,
                  onTap: () {}),
            ],
          ),
        ),

        const SectionLabel('Cấu hình'),
        LuniCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        _CfgIcon(icon: 'logs'),
                        SizedBox(width: 13),
                        Text('Mức nhật ký',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LuniSegmented<String>(
                      height: 36,
                      upper: true,
                      value: _logLevel ?? 'info',
                      options: const [
                        ('debug', 'debug'),
                        ('info', 'info'),
                        ('warn', 'warn'),
                        ('error', 'error'),
                      ],
                      onChanged: (v) => setState(() => _logLevel = v),
                    ),
                  ],
                ),
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                icon: 'download',
                label: 'Tự động cập nhật',
                sub: 'Cài firmware mới khi rảnh',
                trailing: LuniToggle(
                    value: _autoOta,
                    onChanged: (v) => setState(() => _autoOta = v)),
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                icon: 'alert',
                label: 'Thông báo đẩy',
                sub: 'Offline, pin yếu, lỗi',
                trailing: LuniToggle(
                    value: _push, onChanged: (v) => setState(() => _push = v)),
              ),
            ],
          ),
        ),

        const SectionLabel('Chia sẻ & quyền'),
        LuniCard(
          padding: EdgeInsets.zero,
          child: SettingRow(
            icon: 'users',
            label: 'Chia sẻ robot',
            sub: '2 người có quyền truy cập',
            onTap: () => _openSharing(device),
          ),
        ),

        const SectionLabel('Bảo trì'),
        LuniCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingRow(
                  icon: 'bluetooth',
                  label: 'Ghép nối lại (BLE)',
                  sub: 'Đổi Wi-Fi hoặc máy chủ',
                  onTap: () => context.go('/pairing')),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                  icon: 'refresh',
                  label: 'Khởi động lại robot',
                  onTap: () => _confirm(
                        title: 'Khởi động lại Luni?',
                        body: 'Robot sẽ ngoại tuyến khoảng 20 giây.',
                        cta: 'Khởi động lại',
                      )),
              if (isAdmin) ...[
                const Divider(indent: 16, endIndent: 16, height: 1),
                SettingRow(
                  icon: 'shield',
                  iconColor: LuniColors.purple,
                  label: 'Quản lý nâng cao',
                  sub: 'Công cụ chẩn đoán BLE (Admin)',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      LuniPill(label: 'Admin', color: LuniColors.purple),
                      SizedBox(width: 6),
                      LuniIcon('chevron', size: 18, color: LuniColors.txFaint),
                    ],
                  ),
                  onTap: () => context.go('/devices/${widget.deviceId}/admin-ble'),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 22),
        DangerButton(
          label: 'Xoá robot khỏi tài khoản',
          icon: 'trash',
          onPressed: () => _confirm(
            title: 'Xoá robot này?',
            body:
                'Luni sẽ bị gỡ khỏi tài khoản của bạn. Có thể ghép nối lại sau.',
            cta: 'Xoá robot',
            danger: true,
            onOk: () => context.go('/home'),
          ),
        ),
      ],
    );
  }

  void _openSharing(Device device) {
    showLuniSheet(
      context: context,
      title: 'Chia sẻ robot',
      builder: (_) => SharingPanel(device: device),
    );
  }

  void _confirm({
    required String title,
    required String body,
    required String cta,
    bool danger = false,
    VoidCallback? onOk,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xB3030508),
      builder: (ctx) => Dialog(
        backgroundColor: LuniColors.bg1,
        insetPadding: const EdgeInsets.all(26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuniTokens.radius),
          side: const BorderSide(color: LuniColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: LuniTextStyles.h3),
              const SizedBox(height: 6),
              Text(body,
                  style: const TextStyle(
                      color: LuniColors.txMute, height: 1.5, fontSize: 15)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: LuniGhostButton(
                          label: 'Huỷ', onPressed: () => Navigator.pop(ctx)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Press(
                      onTap: () {
                        Navigator.pop(ctx);
                        onOk?.call();
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: danger ? LuniColors.red : LuniColors.cyan,
                          borderRadius: BorderRadius.circular(LuniTokens.radius),
                        ),
                        child: Text(cta,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: danger ? Colors.white : LuniColors.onCyan)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CfgIcon extends StatelessWidget {
  const _CfgIcon({required this.icon});
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: hexA(const Color(0xFF7D91B9), 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(child: LuniIcon(icon, size: 19, color: LuniColors.txSoft)),
    );
  }
}
