import 'package:flutter/material.dart';

class LuniAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LuniAppBar({
    required this.title,
    this.actions,
    this.bottom,
    this.leading,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  @override
  Size get preferredSize {
    return Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: Text(title),
      actions: actions,
      bottom: bottom,
    );
  }
}
