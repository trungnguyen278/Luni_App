import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../../../shared/widgets/luni_toast.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final name = user?.name ?? 'Guest';
    final email = user?.email ?? '';
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
                        child: Press(
                          onTap: () => _showAvatarSheet(context),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: LuniColors.bg2,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: LuniColors.bgBase, width: 2),
                            ),
                            child: const Center(
                                child: LuniIcon('edit',
                                    size: 15, color: LuniColors.cyan)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: LuniTextStyles.h2),
                  const SizedBox(height: 2),
                  Text(email, style: LuniTextStyles.sub),
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
                  SettingRow(
                      icon: 'user',
                      label: 'Chỉnh sửa hồ sơ',
                      onTap: () => _showEditProfile(context, name, email)),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(
                      icon: 'lock',
                      label: 'Đổi mật khẩu',
                      onTap: () => _showPasswordSheet(context)),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(
                      icon: 'shield',
                      label: 'Bảo mật & quyền riêng tư',
                      onTap: () => _showSecuritySheet(context)),
                ],
              ),
            ),
            if (user != null) ...[
              const SectionLabel('Vai trò'),
              LuniCard(
                child: Row(
                  children: [
                    const LuniIcon('shield', size: 20, color: LuniColors.purple),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Vai trò')),
                    LuniPill(label: user.role.label, color: LuniColors.purple),
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

// ---------------------------------------------------------------------------
// Sheets. Backend wiring is pending — these collect input and confirm via a
// toast; persistence is a TODO(backend).
// ---------------------------------------------------------------------------

void _showAvatarSheet(BuildContext context) {
  showLuniSheet<void>(
    context: context,
    title: 'Ảnh đại diện',
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingRow(
          icon: 'camera',
          label: 'Chụp ảnh mới',
          onTap: () {
            Navigator.pop(ctx);
            luniToast(context, 'Sắp ra mắt', icon: 'info', color: LuniColors.cyan);
          },
        ),
        SettingRow(
          icon: 'image',
          label: 'Chọn từ thư viện',
          onTap: () {
            Navigator.pop(ctx);
            luniToast(context, 'Sắp ra mắt', icon: 'info', color: LuniColors.cyan);
          },
        ),
        SettingRow(
          icon: 'trash',
          label: 'Xoá ảnh hiện tại',
          danger: true,
          onTap: () {
            Navigator.pop(ctx);
            luniToast(context, 'Đã xoá ảnh đại diện',
                icon: 'trash', color: LuniColors.red);
          },
        ),
      ],
    ),
  );
}

Future<void> _showEditProfile(
    BuildContext context, String name, String email) async {
  final msg = await showLuniSheet<String>(
    context: context,
    title: 'Chỉnh sửa hồ sơ',
    builder: (_) => _EditProfileSheet(name: name, email: email),
  );
  if (msg != null && context.mounted) luniToast(context, msg);
}

Future<void> _showPasswordSheet(BuildContext context) async {
  final msg = await showLuniSheet<String>(
    context: context,
    title: 'Đổi mật khẩu',
    builder: (_) => const _PasswordSheet(),
  );
  if (msg != null && context.mounted) luniToast(context, msg);
}

void _showSecuritySheet(BuildContext context) {
  showLuniSheet<void>(
    context: context,
    title: 'Bảo mật & quyền riêng tư',
    builder: (_) => _SecuritySheet(rootContext: context),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.name, required this.email});
  final String name;
  final String email;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.name);
  late final _email = TextEditingController(text: widget.email);
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Tên hiển thị'),
        LuniField(controller: _name, icon: 'user'),
        const SizedBox(height: 14),
        const FieldLabel('Email'),
        LuniField(
            controller: _email,
            icon: 'mail',
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        const FieldLabel('Số điện thoại'),
        LuniField(
            controller: _phone,
            icon: 'chat',
            hint: '09xx xxx xxx',
            keyboardType: TextInputType.phone),
        const SizedBox(height: 20),
        SheetActions(
          onCancel: () => Navigator.pop(context),
          // TODO(backend): persist profile changes via the user API.
          onSave: () => Navigator.pop(context, 'Đã lưu hồ sơ'),
        ),
      ],
    );
  }
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mismatch = _confirm.text.isNotEmpty && _confirm.text != _next.text;
    final valid = _current.text.isNotEmpty &&
        _next.text.length >= 6 &&
        _next.text == _confirm.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Mật khẩu hiện tại'),
        LuniField(
            controller: _current,
            icon: 'lock',
            hint: '••••••••',
            obscure: true,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        const FieldLabel('Mật khẩu mới'),
        LuniField(
            controller: _next,
            icon: 'lock',
            hint: 'Tối thiểu 6 ký tự',
            obscure: true,
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        const FieldLabel('Xác nhận mật khẩu mới'),
        LuniField(
            controller: _confirm,
            icon: 'lock',
            hint: '••••••••',
            obscure: true,
            onChanged: (_) => setState(() {})),
        if (mismatch) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const LuniIcon('alert', size: 15, color: LuniColors.red),
              const SizedBox(width: 7),
              Text('Mật khẩu xác nhận không khớp',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: LuniColors.red,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
        const SizedBox(height: 20),
        SheetActions(
          saveLabel: 'Cập nhật',
          onCancel: () => Navigator.pop(context),
          // TODO(backend): change password via the auth API.
          onSave: valid ? () => Navigator.pop(context, 'Đã đổi mật khẩu') : null,
        ),
      ],
    );
  }
}

class _SecuritySheet extends StatefulWidget {
  const _SecuritySheet({required this.rootContext});
  final BuildContext rootContext;

  @override
  State<_SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends State<_SecuritySheet> {
  bool _twoFa = false;
  bool _biometric = true;
  bool _diag = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuniCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingRow(
                icon: 'shield',
                label: 'Xác thực 2 bước (2FA)',
                sub: 'Mã OTP khi đăng nhập thiết bị mới',
                trailing: LuniToggle(
                    value: _twoFa, onChanged: (v) => setState(() => _twoFa = v)),
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                icon: 'key',
                label: 'Đăng nhập sinh trắc học',
                sub: 'Face ID / vân tay',
                trailing: LuniToggle(
                    value: _biometric,
                    onChanged: (v) => setState(() => _biometric = v)),
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                icon: 'chart',
                label: 'Chia sẻ dữ liệu chẩn đoán',
                trailing: LuniToggle(
                    value: _diag, onChanged: (v) => setState(() => _diag = v)),
              ),
            ],
          ),
        ),
        const SectionLabel('Quyền riêng tư'),
        LuniCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingRow(
                icon: 'download',
                iconColor: LuniColors.cyan,
                label: 'Tải dữ liệu của tôi',
                onTap: () {
                  Navigator.pop(context);
                  // TODO(backend): trigger a data export job.
                  luniToast(widget.rootContext, 'Đang chuẩn bị bản xuất…',
                      icon: 'download', color: LuniColors.cyan);
                },
              ),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                icon: 'trash',
                label: 'Xoá tài khoản',
                danger: true,
                onTap: () {
                  Navigator.pop(context);
                  // TODO(backend): account deletion flow.
                  luniToast(widget.rootContext, 'Yêu cầu xoá tài khoản đã gửi',
                      icon: 'alert', color: LuniColors.red);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
