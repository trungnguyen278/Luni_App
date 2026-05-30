import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../providers/device_detail_notifier.dart';
import '../widgets/sharing_panel.dart';

class DeviceSharingScreen extends ConsumerWidget {
  const DeviceSharingScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceDetailProvider(deviceId));

    return Scaffold(
      appBar: LuniAppBar(
          title: 'Chia sẻ thiết bị',
          onBack: () => context.go('/devices/$deviceId')),
      body: device == null
          ? const LuniErrorState(message: 'Không tìm thấy thiết bị.')
          : Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: SharingPanel(device: device),
            ),
    );
  }
}
