import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../providers/pairing_notifier.dart';
import '../widgets/ble_device_tile.dart';
import '../widgets/pairing_progress.dart';
import '../widgets/wifi_network_list.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _pinController = TextEditingController();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController(
    text: AppConfig.defaultDeviceWsUrl,
  );
  final _nameController = TextEditingController(
    text: AppConfig.defaultRobotName,
  );

  @override
  void dispose() {
    _pinController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pairingProvider);

    return Scaffold(
      appBar: LuniAppBar(
        title: 'Ghép nối BLE',
        onBack: () => context.go('/home'),
        actions: [
          LuniIconButton('refresh',
              tooltip: 'Làm mới',
              onTap: () => ref.read(pairingProvider.notifier).reset()),
          const SizedBox(width: 4),
        ],
      ),
      body: ScreenIn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            PairingProgress(stage: state.stage),
            if (state.error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: hexA(LuniColors.red, 0.12),
                  borderRadius: BorderRadius.circular(LuniTokens.radius),
                  border: Border.all(color: hexA(LuniColors.red, 0.4)),
                ),
                child: Row(
                  children: [
                    const LuniIcon('alert', size: 18, color: LuniColors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(state.error!,
                          style: const TextStyle(
                              color: LuniColors.red, fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            _bodyForStage(state),
          ],
        ),
      ),
    );
  }

  Widget _bodyForStage(PairingState state) {
    switch (state.stage) {
      case PairingStage.scanning:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 22),
                child: LuniFace(
                    emotion: 'curious',
                    size: 120,
                    state: LuniFaceState.listening),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12, left: 4),
              child: Text('Robot ở gần', style: LuniTextStyles.over),
            ),
            for (final device in state.nearbyDevices)
              BleDeviceTile(
                device: device,
                onTap: () =>
                    ref.read(pairingProvider.notifier).selectDevice(device),
              ),
            if (state.nearbyDevices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Đang quét thiết bị gần đây…',
                      style: LuniTextStyles.sub),
                ),
              ),
          ],
        );
      case PairingStage.connecting:
      case PairingStage.readInfo:
      case PairingStage.writeWifi:
      case PairingStage.generateToken:
      case PairingStage.writeToken:
      case PairingStage.writeUrl:
      case PairingStage.commit:
      case PairingStage.restart:
      case PairingStage.verify:
        return _BusyPanel(label: state.stage.label);
      case PairingStage.pinAuth:
        return _PinForm(
          controller: _pinController,
          onSubmit: () => ref
              .read(pairingProvider.notifier)
              .submitPin(_pinController.text.trim()),
        );
      case PairingStage.wifiSetup:
        return _WifiForm(
          ssidController: _ssidController,
          passwordController: _passwordController,
          onSsidSelected: (ssid) => _ssidController.text = ssid,
          onSubmit: () => ref
              .read(pairingProvider.notifier)
              .submitWifi(
                ssid: _ssidController.text,
                password: _passwordController.text,
              ),
        );
      case PairingStage.serverSetup:
        return _ServerForm(
          controller: _serverController,
          onSubmit: () => ref
              .read(pairingProvider.notifier)
              .submitServerUrl(_serverController.text),
        );
      case PairingStage.naming:
        return _NameForm(
          controller: _nameController,
          onSubmit: () => ref
              .read(pairingProvider.notifier)
              .submitRobotName(_nameController.text),
        );
      case PairingStage.done:
        return _DonePanel(
          name: state.robotName,
          onOpenHome: () => context.go('/home'),
        );
      case PairingStage.error:
        return LuniGhostButton(
          label: 'Thử lại',
          icon: 'refresh',
          onPressed: () => ref.read(pairingProvider.notifier).reset(),
        );
    }
  }
}

class _BusyPanel extends StatelessWidget {
  const _BusyPanel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const LuniFace(
              emotion: 'thinking', size: 120, state: LuniFaceState.thinking),
          const SizedBox(height: 22),
          Text(label, style: LuniTextStyles.h3),
          const SizedBox(height: 8),
          const Text('Vui lòng giữ robot ở gần điện thoại…',
              textAlign: TextAlign.center, style: LuniTextStyles.sub),
        ],
      ),
    );
  }
}

class _PinForm extends StatelessWidget {
  const _PinForm({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: 'PIN trên màn hình robot',
          field: LuniField(
            controller: controller,
            icon: 'lock',
            hint: '6 chữ số',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 18),
        LuniCta(label: 'Mở khoá Level 1', icon: 'lock', onPressed: onSubmit),
      ],
    );
  }
}

class _WifiForm extends StatelessWidget {
  const _WifiForm({
    required this.ssidController,
    required this.passwordController,
    required this.onSsidSelected,
    required this.onSubmit,
  });

  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final ValueChanged<String> onSsidSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Mạng khả dụng',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 10)),
        WifiNetworkList(onSelected: onSsidSelected),
        const SizedBox(height: 14),
        LabeledField(
          label: 'SSID',
          field: LuniField(
              controller: ssidController, icon: 'wifi', hint: 'Tên mạng'),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Mật khẩu WiFi',
          field: LuniField(
              controller: passwordController,
              icon: 'lock',
              hint: '••••••••',
              obscure: true),
        ),
        const SizedBox(height: 18),
        LuniCta(label: 'Ghi WiFi', icon: 'check', onPressed: onSubmit),
      ],
    );
  }
}

class _ServerForm extends StatelessWidget {
  const _ServerForm({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: 'WebSocket URL',
          field: LuniField(
              controller: controller, icon: 'globe', hint: 'wss://…'),
        ),
        const SizedBox(height: 18),
        LuniCta(label: 'Dùng URL này', icon: 'link', onPressed: onSubmit),
      ],
    );
  }
}

class _NameForm extends StatelessWidget {
  const _NameForm({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: 'Tên robot',
          field: LuniField(
              controller: controller, icon: 'edit', hint: 'Luni của tôi'),
        ),
        const SizedBox(height: 18),
        LuniCta(
            label: 'Hoàn tất ghép nối', icon: 'check', onPressed: onSubmit),
      ],
    );
  }
}

class _DonePanel extends StatelessWidget {
  const _DonePanel({required this.name, required this.onOpenHome});

  final String name;
  final VoidCallback onOpenHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          const LuniFace(emotion: 'happy', size: 150),
          const SizedBox(height: 24),
          Text('$name đã sẵn sàng!', style: LuniTextStyles.h2),
          const SizedBox(height: 6),
          const Text('Ghép nối thành công. Bắt đầu trò chuyện với Luni nhé.',
              textAlign: TextAlign.center, style: LuniTextStyles.sub),
          const SizedBox(height: 26),
          LuniCta(label: 'Về trang chủ', icon: 'home', onPressed: onOpenHome),
        ],
      ),
    );
  }
}
