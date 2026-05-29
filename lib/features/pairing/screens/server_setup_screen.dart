import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/luni_app_bar.dart';

class ServerSetupScreen extends StatelessWidget {
  const ServerSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: LuniAppBar(title: 'Server URL'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: TextField(
          controller: null,
          decoration: InputDecoration(
            labelText: AppConfig.defaultDeviceWsUrl,
            prefixIcon: Icon(Icons.public_outlined),
          ),
        ),
      ),
    );
  }
}
