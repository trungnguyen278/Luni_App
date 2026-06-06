import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/luni_kit.dart';

/// Heuristic role detection from the email (mirrors the design's `roleFor`).
bool _looksAdmin(String mail) =>
    RegExp(r'admin|service|ky?thuat|@luni\.', caseSensitive: false)
        .hasMatch(mail);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final admin = _looksAdmin(_emailController.text);
    final accent = admin ? LuniColors.purple : LuniColors.cyan;

    return LoadingOverlay(
      isLoading: auth.isLoading,
      label: 'Đang đăng nhập...',
      child: Scaffold(
        body: SafeArea(
          child: ScreenIn(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              children: [
                const Wordmark(),
                const SizedBox(height: 40),
                Text('Chào mừng\ntrở lại',
                    style: LuniTextStyles.h1.copyWith(fontSize: 32)),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để quản lý robot, ghép nối BLE và theo dõi realtime.',
                  style: TextStyle(color: LuniColors.txMute, height: 1.5),
                ),
                const SizedBox(height: 30),
                LabeledField(
                  label: 'Email',
                  field: LuniField(
                    controller: _emailController,
                    icon: 'mail',
                    hint: 'ban@vidu.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Mật khẩu',
                  field: LuniField(
                    controller: _passwordController,
                    icon: 'lock',
                    hint: '••••••••',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                  ),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(auth.error!),
                ],
                const SizedBox(height: 26),
                LuniCta(
                  label: admin ? 'Đăng nhập Admin' : 'Đăng nhập',
                  icon: admin ? 'shield' : 'power',
                  color: accent,
                  foreground: admin ? const Color(0xFF1A0D33) : LuniColors.onCyan,
                  onPressed: _signIn,
                ),
                const SizedBox(height: 12),
                LuniGhostButton(
                  label: 'Tạo tài khoản',
                  icon: 'user',
                  onPressed: () => context.go('/register'),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Press(
                    onTap: () => context.go('/forgot-password'),
                    child: const Text('Quên mật khẩu?',
                        style: TextStyle(
                            color: LuniColors.cyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (ref.read(authControllerProvider).isAuthenticated) context.go('/home');
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hexA(LuniColors.red, 0.12),
        borderRadius: BorderRadius.circular(LuniTokens.radius),
        border: Border.all(color: hexA(LuniColors.red, 0.4)),
      ),
      child: Row(
        children: [
          const LuniIcon('alert', size: 18, color: LuniColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: LuniColors.red, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

