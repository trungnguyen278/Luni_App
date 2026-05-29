import 'package:flutter/material.dart';

import '../../../shared/widgets/luni_app_bar.dart';

class DeviceSharingScreen extends StatelessWidget {
  const DeviceSharingScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LuniAppBar(title: 'Chia sẻ thiết bị'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline),
            title: Text('demo@luni.local'),
            subtitle: Text('Owner'),
          ),
          const Divider(),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email người dùng',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            onSubmitted: (_) {},
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Mời chia sẻ'),
          ),
        ],
      ),
    );
  }
}
