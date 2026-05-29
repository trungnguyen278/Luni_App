import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_app_bar.dart';
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
      appBar: const LuniAppBar(title: 'Admin BLE'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.stage == AdminBleStage.idle)
            FilledButton.icon(
              onPressed: () => notifier.connect(deviceId),
              icon: const Icon(Icons.bluetooth_connected),
              label: const Text('Kết nối BLE'),
            )
          else if (state.stage == AdminBleStage.levelOne) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: LuniColors.orange,
              ),
              title: Text(_stageLabel(state.stage)),
              subtitle: Text(state.message ?? deviceId),
            ),
            const SizedBox(height: 12),
            _PinField(
              onSubmit: (pin) async {
                await notifier.unlockPin(pin);
                await notifier.authenticateAdmin(deviceId);
              },
            ),
          ]
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: LuniColors.orange,
              ),
              title: Text(_stageLabel(state.stage)),
              subtitle: Text(state.message ?? deviceId),
            ),
          if (state.diagInfo != null) ...[
            const SizedBox(height: 16),
            DiagInfoCard(data: state.diagInfo!),
            const SizedBox(height: 16),
            AdminCommandTile(
              icon: Icons.restore_outlined,
              title: 'Factory Reset',
              description: 'Xóa WiFi và token, giữ firmware hiện tại.',
              onConfirm: notifier.factoryReset,
              danger: true,
            ),
            AdminCommandTile(
              icon: Icons.delete_forever_outlined,
              title: 'Full Wipe',
              description: 'Xóa toàn bộ NVS và đưa robot về trạng thái sạch.',
              onConfirm: notifier.fullWipe,
              danger: true,
            ),
            AdminCommandTile(
              icon: Icons.history_outlined,
              title: 'Rollback Firmware',
              description: 'Khởi động lại bằng firmware trước đó nếu có.',
              onConfirm: notifier.rollbackFirmware,
            ),
            AdminCommandTile(
              icon: Icons.bug_report_outlined,
              title: 'Bật debug',
              description: 'Bật log debug tạm thời cho phiên chẩn đoán.',
              onConfirm: notifier.enableDebug,
            ),
            AdminCommandTile(
              icon: Icons.bug_report,
              title: 'Tắt debug',
              description: 'Đưa log level về cấu hình bình thường.',
              onConfirm: notifier.disableDebug,
            ),
          ],
        ],
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
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'PIN trên màn hình robot',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => widget.onSubmit(_controller.text.trim()),
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Xác thực Admin'),
        ),
      ],
    );
  }
}
