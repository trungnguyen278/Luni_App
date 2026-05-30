import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';
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
          LuniIconButton('user',
              tooltip: 'Hồ sơ', onTap: () => context.go('/profile')),
          LuniIconButton('gear',
              tooltip: 'Cài đặt', onTap: () => context.go('/settings')),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: LuniColors.cyan,
        backgroundColor: LuniColors.bg1,
        onRefresh: () => ref.read(deviceListProvider.notifier).refreshDevices(),
        child: devices.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: LuniColors.cyan)),
          error: (error, _) => LuniErrorState(
            message: 'Không tải được danh sách thiết bị.',
            onRetry: () => ref.read(deviceListProvider.notifier).refreshDevices(),
          ),
          data: (items) => _HomeBody(
            userName: user?.name ?? 'bạn',
            devices: items,
            onOpen: (id) => context.go('/devices/$id'),
            onAdd: () => context.go('/pairing'),
          ),
        ),
      ),
      floatingActionButton: devices.maybeWhen(
        data: (items) => items.isEmpty
            ? null
            : _AddFab(onTap: () => context.go('/pairing')),
        orElse: () => null,
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.userName,
    required this.devices,
    required this.onOpen,
    required this.onAdd,
  });

  final String userName;
  final List devices;
  final void Function(String id) onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final online = devices.where((d) => d.isOnline).length;
    final empty = devices.isEmpty;

    return ScreenIn(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
        children: [
          Text('Nhà của $userName', style: LuniTextStyles.h1),
          const SizedBox(height: 4),
          if (empty)
            const Text('Chưa có robot nào — hãy ghép nối Luni đầu tiên.',
                style: LuniTextStyles.sub)
          else
            Text.rich(
              TextSpan(
                style: LuniTextStyles.sub,
                children: [
                  TextSpan(
                    text: '$online/${devices.length}',
                    style: TextStyle(
                        color: online > 0 ? LuniColors.green : LuniColors.txSoft,
                        fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' robot đang trực tuyến'),
                ],
              ),
            ),
          const SizedBox(height: 22),
          if (empty)
            _EmptyHome(onAdd: onAdd)
          else ...[
            for (final d in devices) ...[
              DeviceCard(device: d, onOpen: () => onOpen(d.id)),
              const SizedBox(height: 14),
            ],
            _AddRobotTile(onTap: onAdd),
          ],
        ],
      ),
    );
  }
}

class _AddRobotTile extends StatelessWidget {
  const _AddRobotTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: DottedBorderBox(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hexA(LuniColors.cyan, 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                  child: LuniIcon('plus',
                      size: 22, color: LuniColors.cyan, strokeWidth: 2.2)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Thêm robot mới',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: LuniColors.tx)),
                SizedBox(height: 2),
                Text('Ghép nối qua Bluetooth',
                    style: TextStyle(fontSize: 12.5, color: LuniColors.txMute)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
      child: Column(
        children: [
          const LuniFace(emotion: 'curious', size: 150),
          const SizedBox(height: 26),
          const Text('Xin chào! Mình là Luni.', style: LuniTextStyles.h2),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: const Text(
              'Bật nguồn robot và để gần điện thoại. Mình sẽ giúp bạn kết nối trong vài bước.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: LuniColors.txMute, height: 1.5, fontSize: 15),
            ),
          ),
          const SizedBox(height: 26),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: LuniCta(
                label: 'Ghép nối Luni', icon: 'bluetooth', onPressed: onAdd),
          ),
        ],
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.only(left: 18, right: 22),
        decoration: BoxDecoration(
          color: LuniColors.cyan,
          borderRadius: BorderRadius.circular(18),
          boxShadow: LuniTokens.glow(LuniColors.cyan, opacity: 0.6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LuniIcon('bluetooth',
                size: 20, color: LuniColors.onCyan, strokeWidth: 2.2),
            SizedBox(width: 10),
            Text('Thêm robot',
                style: TextStyle(
                    color: LuniColors.onCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
