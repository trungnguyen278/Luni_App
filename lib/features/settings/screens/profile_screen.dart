import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final name = user?.name ?? 'Guest';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';

    return Scaffold(
      appBar: LuniAppBar(title: 'Hồ sơ', onBack: () => context.go('/home')),
      body: ScreenIn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [LuniColors.cyan, LuniColors.blue],
                          ),
                        ),
                        child: Center(
                          child: Text(initial,
                              style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: LuniColors.onCyan)),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: LuniColors.bg2,
                            shape: BoxShape.circle,
                            border: Border.all(color: LuniColors.bgBase, width: 2),
                          ),
                          child: const Center(
                              child: LuniIcon('edit',
                                  size: 15, color: LuniColors.cyan)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: LuniTextStyles.h2),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: LuniTextStyles.sub),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                    child: StatTile(
                        icon: 'cpu',
                        color: LuniColors.cyan,
                        value: '2',
                        label: 'Robot')),
                SizedBox(width: 10),
                Expanded(
                    child: StatTile(
                        icon: 'chat',
                        color: LuniColors.rose,
                        value: '129',
                        label: 'Tương tác')),
                SizedBox(width: 10),
                Expanded(
                    child: StatTile(
                        icon: 'clock',
                        color: LuniColors.green,
                        value: '42',
                        label: 'Ngày')),
              ],
            ),
            const SectionLabel('Tài khoản'),
            LuniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(icon: 'user', label: 'Chỉnh sửa hồ sơ', onTap: () {}),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(icon: 'lock', label: 'Đổi mật khẩu', onTap: () {}),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(
                      icon: 'shield',
                      label: 'Bảo mật & quyền riêng tư',
                      onTap: () {}),
                ],
              ),
            ),
            if (user?.role.label != null) ...[
              const SectionLabel('Vai trò'),
              LuniCard(
                child: Row(
                  children: [
                    const LuniIcon('shield', size: 20, color: LuniColors.purple),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Vai trò')),
                    LuniPill(
                        label: user!.role.label, color: LuniColors.purple),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            DangerButton(
              label: 'Đăng xuất',
              icon: 'power',
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
