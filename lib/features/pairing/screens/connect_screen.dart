import 'package:flutter/material.dart';

import '../../../shared/widgets/luni_app_bar.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: LuniAppBar(title: 'Kết nối BLE'),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
