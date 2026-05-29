import 'package:flutter/material.dart';

class AdminCommandTile extends StatelessWidget {
  const AdminCommandTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onConfirm,
    this.danger = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onConfirm;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: danger ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        );

        if (accepted ?? false) {
          onConfirm();
        }
      },
    );
  }
}
