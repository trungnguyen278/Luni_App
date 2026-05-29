import 'package:flutter/material.dart';

class WifiNetworkList extends StatelessWidget {
  const WifiNetworkList({required this.onSelected, super.key});

  final ValueChanged<String> onSelected;

  static const _networks = ['LuniLab', 'Home-5G', 'Office-IoT'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final network in _networks)
          ActionChip(
            avatar: const Icon(Icons.wifi, size: 16),
            label: Text(network),
            onPressed: () => onSelected(network),
          ),
      ],
    );
  }
}
