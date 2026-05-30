import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/luni_kit.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return LoadingOverlay(
      isLoading: auth.isLoading,
      label: 'Đang tạo tài khoản...',
      child: Scaffold(
        body: SafeArea(
          child: ScreenIn(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: LuniIconButton('back',
                      onTap: () => context.go('/login')),
                ),
                const SizedBox(height: 18),
                Text('Tạo tài khoản',
                    style: LuniTextStyles.h1.copyWith(fontSize: 30)),
                const SizedBox(height: 8),
                const Text('Một tài khoản cho mọi chú Luni của bạn.',
                    style: TextStyle(color: LuniColors.txMute, height: 1.5)),
                const SizedBox(height: 26),
                LabeledField(
                  label: 'Tên hiển thị',
                  field: LuniField(
                    controller: _nameController,
                    icon: 'user',
                    hint: 'Tên của bạn',
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Email',
                  field: LuniField(
                    controller: _emailController,
                    icon: 'mail',
                    hint: 'ban@vidu.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Mật khẩu',
                  field: LuniField(
                    controller: _passwordController,
                    icon: 'lock',
                    hint: 'Tối thiểu 8 ký tự',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _register(),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 1),
                        child:
                            LuniIcon('shield', size: 15, color: LuniColors.green),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Mật khẩu được mã hoá. Chúng tôi không bao giờ chia sẻ dữ liệu robot.',
                          style: TextStyle(
                              fontSize: 12.5, color: LuniColors.txMute),
                        ),
                      ),
                    ],
                  ),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 14),
                  Text(auth.error!,
                      style: const TextStyle(color: LuniColors.red)),
                ],
                const SizedBox(height: 22),
                LuniCta(label: 'Tạo tài khoản', icon: 'chevron', onPressed: _register),
                const SizedBox(height: 20),
                Center(
                  child: Press(
                    onTap: () => context.go('/login'),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Đã có tài khoản? ',
                        style: TextStyle(color: LuniColors.txMute, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Đăng nhập',
                            style: TextStyle(
                                color: LuniColors.cyan,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (ref.read(authControllerProvider).isAuthenticated) context.go('/home');
  }
}
