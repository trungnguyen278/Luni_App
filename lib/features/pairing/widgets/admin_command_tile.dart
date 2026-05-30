import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_kit.dart';

class AdminCommandTile extends StatelessWidget {
  const AdminCommandTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onConfirm,
    this.danger = false,
    super.key,
  });

  final String icon;
  final String title;
  final String description;
  final VoidCallback onConfirm;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LuniCard(
        padding: EdgeInsets.zero,
        child: SettingRow(
          icon: icon,
          danger: danger,
          iconColor: LuniColors.purple,
          label: title,
          sub: description,
          onTap: () => _confirm(context),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3030508),
      builder: (ctx) => Dialog(
        backgroundColor: LuniColors.bg1,
        insetPadding: const EdgeInsets.all(26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuniTokens.radius),
          side: const BorderSide(color: LuniColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: LuniTextStyles.h3),
              const SizedBox(height: 6),
              Text(description,
                  style: const TextStyle(
                      color: LuniColors.txMute, height: 1.5, fontSize: 15)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: LuniGhostButton(
                          label: 'Huỷ',
                          onPressed: () => Navigator.pop(ctx, false)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Press(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: danger ? LuniColors.red : LuniColors.cyan,
                          borderRadius: BorderRadius.circular(LuniTokens.radius),
                        ),
                        child: Text('Xác nhận',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color:
                                    danger ? Colors.white : LuniColors.onCyan)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (accepted ?? false) onConfirm();
  }
}
