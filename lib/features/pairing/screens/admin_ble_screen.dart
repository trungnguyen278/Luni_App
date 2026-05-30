import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../providers/admin_ble_notifier.dart';
import '../widgets/admin_command_tile.dart';
import '../widgets/diag_info_card.dart';

class AdminBleScreen extends ConsumerWidget {
  const AdminBleScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminBleProvider);
    final notifier = ref.read(adminBleProvider.notifier);

    return Scaffold(
      appBar: LuniAppBar(
          title: 'Admin BLE',
          subtitle: 'Cấp 2 · Chẩn đoán',
          onBack: () => context.go('/devices/$deviceId')),
      body: ScreenIn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            // status header
            LuniCard(
              gradient: LinearGradient(
                colors: [hexA(LuniColors.purple, 0.1), LuniColors.bg1],
              ),
              border: Border.all(color: hexA(LuniColors.purple, 0.25)),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hexA(LuniColors.purple, 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                        child: LuniIcon('shield',
                            size: 22, color: LuniColors.purple)),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_stageLabel(state.stage),
                            style: LuniTextStyles.h3),
                        const SizedBox(height: 2),
                        Text(state.message ?? deviceId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuniTextStyles.mono.copyWith(
                                fontSize: 11.5, color: LuniColors.txMute)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.stage == AdminBleStage.idle)
              LuniCta(
                label: 'Kết nối BLE',
                icon: 'bluetooth',
                color: LuniColors.purple,
                foreground: const Color(0xFF1A0D33),
                onPressed: () => notifier.connect(deviceId),
              )
            else if (state.stage == AdminBleStage.levelOne)
              _PinField(
                onSubmit: (pin) async {
                  await notifier.unlockPin(pin);
                  await notifier.authenticateAdmin(deviceId);
                },
              ),
            if (state.diagInfo != null) ...[
              const SizedBox(height: 16),
              DiagInfoCard(data: state.diagInfo!),
              const SectionLabel('Vùng nguy hiểm'),
              AdminCommandTile(
                icon: 'refresh',
                title: 'Factory Reset',
                description: 'Xóa WiFi và token, giữ firmware hiện tại.',
                onConfirm: notifier.factoryReset,
                danger: true,
              ),
              AdminCommandTile(
                icon: 'trash',
                title: 'Full Wipe',
                description: 'Xóa toàn bộ NVS và đưa robot về trạng thái sạch.',
                onConfirm: notifier.fullWipe,
                danger: true,
              ),
              AdminCommandTile(
                icon: 'download',
                title: 'Rollback Firmware',
                description: 'Khởi động lại bằng firmware trước đó nếu có.',
                onConfirm: notifier.rollbackFirmware,
              ),
              AdminCommandTile(
                icon: 'logs',
                title: 'Bật debug',
                description: 'Bật log debug tạm thời cho phiên chẩn đoán.',
                onConfirm: notifier.enableDebug,
              ),
              AdminCommandTile(
                icon: 'logs',
                title: 'Tắt debug',
                description: 'Đưa log level về cấu hình bình thường.',
                onConfirm: notifier.disableDebug,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stageLabel(AdminBleStage stage) {
    switch (stage) {
      case AdminBleStage.idle:
        return 'Chưa kết nối';
      case AdminBleStage.scanning:
        return 'Đang quét BLE';
      case AdminBleStage.connected:
        return 'Đã kết nối';
      case AdminBleStage.levelOne:
        return 'Level 1';
      case AdminBleStage.levelTwo:
        return 'Level 2';
      case AdminBleStage.commandSent:
        return 'Đã gửi command';
      case AdminBleStage.error:
        return 'Lỗi';
    }
  }
}

class _PinField extends StatefulWidget {
  const _PinField({required this.onSubmit});

  final Future<void> Function(String pin) onSubmit;

  @override
  State<_PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<_PinField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: 'PIN trên màn hình robot',
          field: LuniField(
            controller: _controller,
            icon: 'lock',
            hint: '6 chữ số',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 18),
        LuniCta(
          label: 'Xác thực Admin',
          icon: 'shield',
          color: LuniColors.purple,
          foreground: const Color(0xFF1A0D33),
          onPressed: () => widget.onSubmit(_controller.text.trim()),
        ),
      ],
    );
  }
}
