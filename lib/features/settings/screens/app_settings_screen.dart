import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _dark = true;
  bool _notifications = true;
  String _lang = 'vi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LuniAppBar(
          title: 'Cài đặt ứng dụng', onBack: () => context.go('/home')),
      body: ScreenIn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            const SectionLabel('Giao diện', padding: EdgeInsets.fromLTRB(4, 8, 4, 10)),
            LuniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(
                    icon: 'moon',
                    label: 'Chế độ tối',
                    trailing: LuniToggle(
                        value: _dark,
                        onChanged: (v) => setState(() => _dark = v)),
                  ),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            _IconTile(icon: 'globe'),
                            SizedBox(width: 13),
                            Text('Ngôn ngữ',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LuniSegmented<String>(
                          value: _lang,
                          options: const [
                            ('vi', 'Tiếng Việt'),
                            ('en', 'English'),
                          ],
                          onChanged: (v) => setState(() => _lang = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionLabel('Thông báo'),
            LuniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(
                    icon: 'alert',
                    label: 'Thông báo đẩy',
                    sub: 'Offline, pin yếu, OTA, lỗi',
                    trailing: LuniToggle(
                        value: _notifications,
                        onChanged: (v) => setState(() => _notifications = v)),
                  ),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(
                      icon: 'moon',
                      label: 'Giờ yên tĩnh',
                      sub: '22:00 – 07:00',
                      onTap: () {}),
                ],
              ),
            ),
            const SectionLabel('Khác'),
            LuniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(
                      icon: 'info',
                      label: 'Về Luni',
                      sub: 'Ứng dụng v1.0.0 · build 124',
                      onTap: () {}),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(
                      icon: 'shield',
                      label: 'Điều khoản & quyền riêng tư',
                      onTap: () {}),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(icon: 'chat', label: 'Hỗ trợ', onTap: () {}),
                ],
              ),
            ),
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

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: hexA(const Color(0xFF7D91B9), 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(child: LuniIcon(icon, size: 19, color: LuniColors.txSoft)),
    );
  }
}
