import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../../../shared/widgets/luni_toast.dart';

String _hh(int n) => '${n.toString().padLeft(2, '0')}:00';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  // TODO(backend): persist these preferences (local store / API) — currently
  // they only live for the session.
  bool _dark = true;
  bool _notifications = true;
  String _lang = 'vi';
  bool _quietOn = true;
  int _quietStart = 22;
  int _quietEnd = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LuniAppBar(
          title: 'Cài đặt ứng dụng', onBack: () => context.go('/home')),
      body: ScreenIn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            const SectionLabel('Giao diện',
                padding: EdgeInsets.fromLTRB(4, 8, 4, 10)),
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
                      sub: _quietOn
                          ? '${_hh(_quietStart)} – ${_hh(_quietEnd)}'
                          : 'Đang tắt',
                      onTap: _openQuietHours),
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
                      onTap: () => _showAbout(context)),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(
                      icon: 'shield',
                      label: 'Điều khoản & quyền riêng tư',
                      onTap: () => _showTerms(context)),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  SettingRow(
                      icon: 'chat',
                      label: 'Hỗ trợ',
                      onTap: () => _showSupport(context)),
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

  Future<void> _openQuietHours() async {
    final result = await showLuniSheet<(bool, int, int)>(
      context: context,
      title: 'Giờ yên tĩnh',
      builder: (_) => _QuietHoursSheet(
        on: _quietOn,
        start: _quietStart,
        end: _quietEnd,
      ),
    );
    if (result != null) {
      setState(() {
        _quietOn = result.$1;
        _quietStart = result.$2;
        _quietEnd = result.$3;
      });
      if (mounted) luniToast(context, 'Đã lưu giờ yên tĩnh');
    }
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

// ---------------------------------------------------------------------------
// Sheets
// ---------------------------------------------------------------------------

class _QuietHoursSheet extends StatefulWidget {
  const _QuietHoursSheet(
      {required this.on, required this.start, required this.end});
  final bool on;
  final int start;
  final int end;

  @override
  State<_QuietHoursSheet> createState() => _QuietHoursSheetState();
}

class _QuietHoursSheetState extends State<_QuietHoursSheet> {
  late bool _on = widget.on;
  late int _start = widget.start;
  late int _end = widget.end;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Trong khung giờ này Luni sẽ giảm đèn, tắt âm báo và không gửi thông báo đẩy.',
          style: TextStyle(
              fontSize: 12.5, color: LuniColors.txMute, height: 1.45),
        ),
        const SizedBox(height: 16),
        LuniCard(
          child: Row(
            children: [
              const Expanded(
                  child: Text('Bật giờ yên tĩnh',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600))),
              LuniToggle(value: _on, onChanged: (v) => setState(() => _on = v)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: _on ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !_on,
            child: Row(
              children: [
                Expanded(
                  child: _TimeStepper(
                    label: 'Bắt đầu',
                    value: _start,
                    onChanged: (v) => setState(() => _start = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeStepper(
                    label: 'Kết thúc',
                    value: _end,
                    onChanged: (v) => setState(() => _end = v),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        LuniCta(
          label: 'Lưu',
          onPressed: () => Navigator.pop(context, (_on, _start, _end)),
        ),
      ],
    );
  }
}

/// An hour stepper (00:00–23:00) — mirrors the design's `TimeStepper`.
class _TimeStepper extends StatelessWidget {
  const _TimeStepper(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget stepBtn(String icon, VoidCallback onTap) => Press(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LuniColors.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LuniColors.hairline),
            ),
            child: Center(
                child: LuniIcon(icon, size: 17, color: LuniColors.txSoft)),
          ),
        );

    return LuniCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              stepBtn('back', () => onChanged((value + 23) % 24)),
              Text(_hh(value),
                  style: LuniTextStyles.mono.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: LuniColors.cyan)),
              stepBtn('chevron', () => onChanged((value + 1) % 24)),
            ],
          ),
        ],
      ),
    );
  }
}

void _showAbout(BuildContext context) {
  showLuniSheet<void>(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: LuniFace(emotion: 'happy', size: 92, noPhase: true)),
        const SizedBox(height: 14),
        const Center(child: Text('Luni', style: LuniTextStyles.h1)),
        const SizedBox(height: 2),
        const Center(
          child: Text('Người bạn robot cảm xúc',
              style: TextStyle(color: LuniColors.txMute)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('Ứng dụng v1.0.0 · build 124',
              style: LuniTextStyles.mono.copyWith(
                  fontSize: 12, color: LuniColors.txFaint)),
        ),
        const SizedBox(height: 18),
        LuniCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const SettingRow(
                  icon: 'cpu',
                  label: 'Firmware tương thích',
                  trailing: Text('≥ 2.0.0',
                      style: TextStyle(
                          fontSize: 13, color: LuniColors.txSoft))),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                  icon: 'globe',
                  label: 'Trang chủ',
                  sub: 'luni.vn',
                  onTap: () {
                    Navigator.pop(ctx);
                    luniToast(context, 'Mở luni.vn',
                        icon: 'link', color: LuniColors.cyan);
                  }),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                  icon: 'sparkle',
                  label: 'Có gì mới',
                  sub: 'Nhật ký phiên bản',
                  onTap: () {
                    Navigator.pop(ctx);
                    luniToast(context, 'Nhật ký phiên bản',
                        icon: 'info', color: LuniColors.cyan);
                  }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text('© 2026 Luni Robotics. Made with ♥ in Việt Nam.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: LuniColors.txFaint)),
        ),
        const SizedBox(height: 4),
      ],
    ),
  );
}

const _terms = [
  (
    'Thu thập dữ liệu',
    'Luni chỉ thu thập dữ liệu cần thiết để vận hành robot: trạng thái thiết bị, nhật ký tương tác và cấu hình. Dữ liệu âm thanh được xử lý để phản hồi và không lưu trữ lâu dài nếu bạn không bật sao lưu.'
  ),
  (
    'Quyền riêng tư trẻ em',
    'Luni được thiết kế thân thiện với gia đình. Chúng tôi không cố ý thu thập thông tin định danh của trẻ em. Phụ huynh có thể xoá toàn bộ dữ liệu tương tác bất kỳ lúc nào.'
  ),
  (
    'Kết nối thiết bị',
    'Việc ghép nối qua Bluetooth và Wi‑Fi diễn ra cục bộ giữa điện thoại và robot. Thông tin Wi‑Fi được mã hoá khi truyền và không chia sẻ với bên thứ ba.'
  ),
  (
    'Chia sẻ & quyền',
    'Bạn có thể mời người khác điều khiển robot với các mức quyền khác nhau. Chủ sở hữu có thể thu hồi quyền truy cập bất cứ lúc nào trong phần Chia sẻ.'
  ),
];

void _showTerms(BuildContext context) {
  showLuniSheet<void>(
    context: context,
    title: 'Điều khoản & quyền riêng tư',
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (h, b) in _terms) ...[
                  Text(h, style: LuniTextStyles.h3),
                  const SizedBox(height: 6),
                  Text(b,
                      style: const TextStyle(
                          fontSize: 13.5,
                          color: LuniColors.txSoft,
                          height: 1.5)),
                  const SizedBox(height: 18),
                ],
                Text('Cập nhật lần cuối: 01/03/2026',
                    style: LuniTextStyles.mono.copyWith(
                        fontSize: 11.5, color: LuniColors.txFaint)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        LuniCta(label: 'Tôi đã đọc', onPressed: () => Navigator.pop(ctx)),
      ],
    ),
  );
}

void _showSupport(BuildContext context) {
  showLuniSheet<void>(
    context: context,
    title: 'Hỗ trợ',
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuniCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingRow(
                  icon: 'chat',
                  iconColor: LuniColors.cyan,
                  label: 'Trò chuyện với hỗ trợ',
                  sub: 'Phản hồi trong ~5 phút',
                  onTap: () {
                    Navigator.pop(ctx);
                    luniToast(context, 'Đang kết nối hỗ trợ…',
                        icon: 'chat', color: LuniColors.cyan);
                  }),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                  icon: 'info',
                  iconColor: LuniColors.cyan,
                  label: 'Câu hỏi thường gặp',
                  sub: 'Ghép nối, Wi‑Fi, pin, OTA',
                  onTap: () {
                    Navigator.pop(ctx);
                    luniToast(context, 'Mở câu hỏi thường gặp',
                        icon: 'info', color: LuniColors.cyan);
                  }),
              const Divider(indent: 16, endIndent: 16, height: 1),
              SettingRow(
                  icon: 'flag',
                  iconColor: LuniColors.orange,
                  label: 'Báo lỗi',
                  sub: 'Gửi nhật ký chẩn đoán',
                  onTap: () {
                    Navigator.pop(ctx);
                    luniToast(context, 'Đã gửi nhật ký chẩn đoán',
                        color: LuniColors.green);
                  }),
            ],
          ),
        ),
        const SectionLabel('Liên hệ'),
        const LuniCard(
          child: Column(
            children: [
              Row(
                children: [
                  LuniIcon('chat', size: 18, color: LuniColors.txMute),
                  SizedBox(width: 12),
                  Text('hotro@luni.vn', style: TextStyle(fontSize: 14)),
                ],
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  LuniIcon('speaker', size: 18, color: LuniColors.txMute),
                  SizedBox(width: 12),
                  Text('1900 1234 (8:00–22:00)',
                      style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
