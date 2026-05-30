import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import 'luni_icon.dart';

/// Top bar matching the design's `TopBar` (56h, 17/700 title, optional sub).
class LuniAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LuniAppBar({
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
    this.leading,
    this.onBack,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final VoidCallback? onBack;

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 56,
      titleSpacing: leading == null && onBack == null ? 12 : 0,
      leading: leading ??
          (onBack != null
              ? IconButton(
                  onPressed: onBack,
                  icon: const LuniIcon('back', size: 22),
                )
              : null),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: LuniTextStyles.h3, overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(fontSize: 12, color: LuniColors.txMute)),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
