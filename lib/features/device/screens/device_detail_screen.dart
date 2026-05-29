import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../core/network/ws_client.dart';
import '../../../shared/models/device.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../chat/screens/chat_screen.dart';
import '../../logs/screens/log_viewer_screen.dart';
import '../../ota/screens/ota_screen.dart';
import '../../stats/screens/stats_screen.dart';
import '../providers/device_detail_notifier.dart';
import '../providers/device_list_notifier.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/brightness_slider.dart';
import '../widgets/emotion_picker.dart';
import '../widgets/scene_picker.dart';
import '../widgets/volume_slider.dart';
import 'device_settings_screen.dart';

class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activeDeviceWsProvider(deviceId));
    final device = ref.watch(deviceDetailProvider(deviceId));

    if (device == null) {
      return const Scaffold(
        appBar: LuniAppBar(title: 'Thiết bị'),
        body: LuniErrorState(message: 'Không tìm thấy thiết bị.'),
      );
    }

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: LuniAppBar(
          title: device.name,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Tổng quan'),
              Tab(icon: Icon(Icons.tune), text: 'Điều khiển'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
              Tab(icon: Icon(Icons.article_outlined), text: 'Logs'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
              Tab(icon: Icon(Icons.system_update_alt), text: 'OTA'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'Cài đặt'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(device: device),
            _ControlTab(device: device),
            ChatScreen(deviceId: device.id),
            LogViewerScreen(deviceId: device.id),
            StatsScreen(deviceId: device.id),
            OtaScreen(deviceId: device.id, currentVersion: device.fwVersion),
            DeviceSettingsScreen(deviceId: device.id, embedded: true),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      device.isOnline
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      color: device.isOnline
                          ? LuniColors.green
                          : LuniColors.orange,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      device.isOnline ? 'Đang online' : 'Đang offline',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BatteryIndicator(
                  percent: device.batteryPercent,
                  isCharging: device.isCharging,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.memory_outlined,
          label: 'Model',
          value: device.model,
        ),
        _InfoRow(
          icon: Icons.developer_board_outlined,
          label: 'Firmware',
          value: device.fwVersion,
        ),
        _InfoRow(icon: Icons.wifi, label: 'RSSI', value: '${device.rssi} dBm'),
        _InfoRow(
          icon: Icons.sentiment_satisfied_alt,
          label: 'Emotion',
          value: device.emotion,
        ),
        _InfoRow(
          icon: Icons.dashboard_customize_outlined,
          label: 'Scene',
          value: device.scene,
        ),
      ],
    );
  }
}

class _ControlTab extends ConsumerWidget {
  const _ControlTab({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(deviceListProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Emotion', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        EmotionPicker(
          selected: device.emotion,
          onChanged: (emotion) => notifier.sendCommand(
            device.id,
            DeviceCommand.setEmotion,
            value: emotion,
          ),
        ),
        const SizedBox(height: 24),
        Text('Scene', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ScenePicker(
          selected: device.scene,
          onChanged: (scene) => notifier.sendCommand(
            device.id,
            DeviceCommand.setScene,
            value: scene,
          ),
        ),
        const SizedBox(height: 24),
        Text('Âm lượng', style: Theme.of(context).textTheme.titleMedium),
        VolumeSlider(
          value: device.config.volume,
          onChanged: (value) => notifier.sendCommand(
            device.id,
            DeviceCommand.setVolume,
            value: value,
          ),
        ),
        const SizedBox(height: 12),
        Text('Độ sáng', style: Theme.of(context).textTheme.titleMedium),
        BrightnessSlider(
          value: device.config.brightness,
          onChanged: (value) => notifier.sendCommand(
            device.id,
            DeviceCommand.setBrightness,
            value: value,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => notifier.sendCommand(
                  device.id,
                  DeviceCommand.ttsPlay,
                  value: 'Xin chào từ Luni app',
                ),
                icon: const Icon(Icons.record_voice_over_outlined),
                label: const Text('TTS'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    notifier.sendCommand(device.id, DeviceCommand.reboot),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reboot'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: LuniColors.cyan),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
