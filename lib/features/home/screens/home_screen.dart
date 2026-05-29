import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../device/providers/device_list_notifier.dart';
import '../widgets/device_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceListProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: LuniAppBar(
        title: 'Luni',
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            tooltip: 'Hồ sơ',
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            onPressed: () => context.go('/settings'),
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/pairing'),
        icon: const Icon(Icons.bluetooth_searching),
        label: const Text('Thêm robot'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(deviceListProvider.notifier).refreshDevices(),
        child: devices.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => LuniErrorState(
            message: 'Không tải được danh sách thiết bị.',
            onRetry: () =>
                ref.read(deviceListProvider.notifier).refreshDevices(),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(
                'Nhà của ${user?.name ?? 'bạn'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${items.where((device) => device.isOnline).length}/${items.length} robot đang online',
                style: const TextStyle(color: LuniColors.textMuted),
              ),
              const SizedBox(height: 16),
              for (final device in items) ...[
                DeviceCard(
                  device: device,
                  onOpen: () => context.go('/devices/${device.id}'),
                  onChat: () => context.go('/devices/${device.id}'),
                  onMute: () => ref
                      .read(deviceListProvider.notifier)
                      .sendCommand(device.id, DeviceCommand.mute),
                  onReboot: () => ref
                      .read(deviceListProvider.notifier)
                      .sendCommand(device.id, DeviceCommand.reboot),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
