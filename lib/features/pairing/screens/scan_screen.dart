import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/luni_app_bar.dart';
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
        actions: [
          IconButton(
            onPressed: () => ref.read(pairingProvider.notifier).reset(),
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PairingProgress(stage: state.stage),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          _bodyForStage(state),
        ],
      ),
    );
  }

  Widget _bodyForStage(PairingState state) {
    switch (state.stage) {
      case PairingStage.scanning:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final device in state.nearbyDevices)
              BleDeviceTile(
                device: device,
                onTap: () =>
                    ref.read(pairingProvider.notifier).selectDevice(device),
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
        return const Center(child: CircularProgressIndicator());
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
        return OutlinedButton.icon(
          onPressed: () => ref.read(pairingProvider.notifier).reset(),
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        );
    }
  }
}

class _PinForm extends StatelessWidget {
  const _PinForm({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'PIN trên màn hình robot',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Mở khóa Level 1'),
        ),
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
        WifiNetworkList(onSelected: onSsidSelected),
        const SizedBox(height: 14),
        TextField(
          controller: ssidController,
          decoration: const InputDecoration(
            labelText: 'SSID',
            prefixIcon: Icon(Icons.wifi),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu WiFi',
            prefixIcon: Icon(Icons.password_outlined),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Ghi WiFi'),
        ),
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
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'WebSocket URL',
            prefixIcon: Icon(Icons.public_outlined),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.link_outlined),
          label: const Text('Dùng URL này'),
        ),
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
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tên robot',
            prefixIcon: Icon(Icons.drive_file_rename_outline),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Hoàn tất provisioning'),
        ),
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
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 48),
        const SizedBox(height: 12),
        Text(
          '$name đã sẵn sàng',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onOpenHome,
          icon: const Icon(Icons.home_outlined),
          label: const Text('Về Home'),
        ),
      ],
    );
  }
}
