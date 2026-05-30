import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/luni_kit.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return LoadingOverlay(
      isLoading: auth.isLoading,
      label: 'Đang gửi...',
      child: Scaffold(
        body: SafeArea(
          child: ScreenIn(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child:
                      LuniIconButton('back', onTap: () => context.go('/login')),
                ),
                const SizedBox(height: 18),
                Text('Quên mật khẩu',
                    style: LuniTextStyles.h1.copyWith(fontSize: 30)),
                const SizedBox(height: 8),
                const Text('Nhập email, chúng tôi sẽ gửi liên kết đặt lại.',
                    style: TextStyle(color: LuniColors.txMute, height: 1.5)),
                const SizedBox(height: 26),
                if (!_sent) ...[
                  LabeledField(
                    label: 'Email',
                    field: LuniField(
                      controller: _emailController,
                      icon: 'mail',
                      hint: 'ban@vidu.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  LuniCta(label: 'Gửi liên kết', icon: 'send', onPressed: _send),
                ] else
                  _SentCard(email: _emailController.text),
                const SizedBox(height: 22),
                Center(
                  child: Press(
                    onTap: () => context.go('/login'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LuniIcon('back', size: 16, color: LuniColors.txMute),
                        SizedBox(width: 6),
                        Text('Quay lại đăng nhập',
                            style: TextStyle(
                                color: LuniColors.txMute, fontSize: 14)),
                      ],
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

  Future<void> _send() async {
    await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(email: _emailController.text);
    if (!mounted) return;
    setState(() => _sent = true);
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return LuniCard2(
      padding: const EdgeInsets.all(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hexA(LuniColors.green, 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: LuniIcon('check',
                  size: 22, color: LuniColors.green, strokeWidth: 2.4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Đã gửi!', style: LuniTextStyles.h3),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'Kiểm tra ',
                    style: LuniTextStyles.sub,
                    children: [
                      TextSpan(
                          text: email,
                          style: const TextStyle(
                              color: LuniColors.txSoft,
                              fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' và làm theo hướng dẫn.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
