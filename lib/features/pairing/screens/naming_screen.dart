import 'package:flutter/material.dart';

import '../../../shared/widgets/luni_app_bar.dart';

class NamingScreen extends StatelessWidget {
  const NamingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: LuniAppBar(title: 'Đặt tên robot'),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Tên robot',
            prefixIcon: Icon(Icons.drive_file_rename_outline),
          ),
        ),
      ),
    );
  }
}
