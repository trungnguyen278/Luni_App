import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../providers/device_detail_notifier.dart';

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

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: const LuniAppBar(title: 'Cài đặt robot'),
      body: content,
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent({required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceDetailProvider(deviceId));
    final user = ref.watch(authControllerProvider).user;

    if (device == null) {
      return const LuniErrorState(message: 'Không tìm thấy thiết bị.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.drive_file_rename_outline),
          title: const Text('Tên robot'),
          subtitle: Text(device.name),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Vị trí'),
          subtitle: Text('${device.location} · ${device.city}'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.public_outlined),
          title: const Text('Timezone'),
          subtitle: Text(device.timezone),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: device.config.autoOta,
          onChanged: (_) {},
          secondary: const Icon(Icons.system_update_alt),
          title: const Text('Tự động OTA'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.article_outlined),
          title: const Text('Log level'),
          subtitle: Text(device.config.logLevel),
          trailing: const Icon(Icons.chevron_right),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.group_outlined),
          title: const Text('Chia sẻ thiết bị'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/devices/$deviceId/sharing'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bluetooth_connected),
          title: const Text('Re-pair qua BLE'),
          subtitle: const Text('Cập nhật WiFi, token hoặc server URL'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/pairing'),
        ),
        if (user?.role.isAdmin ?? false)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.admin_panel_settings_outlined,
              color: LuniColors.orange,
            ),
            title: const Text('Quản lý nâng cao'),
            subtitle: const Text('Admin BLE Level 2'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/devices/$deviceId/admin-ble'),
          ),
      ],
    );
  }
}
