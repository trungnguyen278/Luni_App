import 'package:flutter/material.dart';

import '../../../shared/widgets/luni_app_bar.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notifications = true;
  bool _quietHours = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuniAppBar(title: 'Cài đặt ứng dụng'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Thông báo FCM'),
            subtitle: const Text('Offline, OTA, pin yếu và lỗi nghiêm trọng'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _quietHours,
            onChanged: (value) => setState(() => _quietHours = value),
            secondary: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('Quiet hours'),
            subtitle: const Text('Tắt thông báo không khẩn cấp ban đêm'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.storage_outlined),
            title: Text('Offline cache'),
            subtitle: Text(
              'Hive cache cho danh sách thiết bị và logs gần nhất',
            ),
          ),
        ],
      ),
    );
  }
}
