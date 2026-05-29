import 'package:flutter/material.dart';

import '../../../shared/widgets/luni_app_bar.dart';
import '../widgets/wifi_network_list.dart';

class WifiSetupScreen extends StatelessWidget {
  const WifiSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuniAppBar(title: 'WiFi'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WifiNetworkList(onSelected: (_) {}),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'SSID',
              prefixIcon: Icon(Icons.wifi),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: Icon(Icons.password_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
