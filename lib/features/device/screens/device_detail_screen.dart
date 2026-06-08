import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../../../core/lunar/lunar_calendar.dart';
import '../../../core/network/ws_client.dart';
import '../../../shared/models/device.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/luni_app_bar.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../../../shared/widgets/luni_toast.dart';
import '../../../shared/widgets/moon_glyph.dart';
import '../../chat/screens/chat_screen.dart';
import '../../logs/screens/log_viewer_screen.dart';
import '../../motion/screens/motion_screen.dart';
import '../../ota/screens/ota_screen.dart';
import '../../stats/screens/stats_screen.dart';
import '../providers/device_detail_notifier.dart';
import '../providers/device_list_notifier.dart';
import 'device_settings_screen.dart';

const _hubTabs = [
  LuniTab('overview', 'grid', 'Tổng quan'),
  LuniTab('control', 'sliders', 'Điều khiển'),
  LuniTab('motion', 'walk', 'Vận động'),
  LuniTab('history', 'chat', 'Trò chuyện'),
  LuniTab('stats', 'chart', 'Thống kê'),
  LuniTab('ota', 'download', 'Cập nhật'),
  LuniTab('logs', 'logs', 'Nhật ký'),
  LuniTab('settings', 'gear', 'Cài đặt'),
];

// Firmware-mappable emotions (WS set_emotion) with picker icons.
const _emotionList = [
  ('neutral', 'eye'),
  ('happy', 'sun'),
  ('excited', 'sparkle'),
  ('curious', 'search'),
  ('confused', 'info'),
  ('calm', 'wave'),
  ('cool', 'shield'),
  ('thinking', 'cpu'),
  ('sad', 'heart'),
  ('angry', 'bolt'),
  ('annoyed', 'alert'),
  ('disgusted', 'close'),
];

const _sceneList = [
  ('home', 'home', LuniColors.cyan),
  ('weather', 'wifi', LuniColors.blue),
  ('clock', 'clock', LuniColors.warm),
  ('calendar', 'logs', LuniColors.green),
  ('sleep', 'moon', LuniColors.purple),
  ('music', 'wave', LuniColors.rose),
];

class DeviceDetailScreen extends ConsumerStatefulWidget {
  const DeviceDetailScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  String _tab = 'overview';

  @override
  Widget build(BuildContext context) {
    ref.watch(activeDeviceWsProvider(widget.deviceId));
    final device = ref.watch(deviceDetailProvider(widget.deviceId));

    if (device == null) {
      return Scaffold(
        appBar: LuniAppBar(title: 'Thiết bị', onBack: () => context.go('/home')),
        body: const LuniErrorState(message: 'Không tìm thấy thiết bị.'),
      );
    }

    final em = luniEmotion(device.emotion);

    return Scaffold(
      appBar: LuniAppBar(
        title: device.name,
        subtitle: device.isOnline ? em.label : 'Ngoại tuyến',
        onBack: () => context.go('/home'),
        actions: [
          LuniIconButton('gear',
              tooltip: 'Cài đặt',
              onTap: () => setState(() => _tab = 'settings')),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: LuniTabStrip(
            tabs: _hubTabs,
            active: _tab,
            onSelect: (t) => setState(() => _tab = t),
          ),
        ),
      ),
      body: KeyedSubtree(
        key: ValueKey(_tab),
        child: ScreenIn(child: _content(device)),
      ),
    );
  }

  Widget _content(Device device) {
    switch (_tab) {
      case 'control':
        return _ControlTab(device: device);
      case 'motion':
        return MotionScreen(device: device);
      case 'history':
        return ChatScreen(deviceId: device.id);
      case 'stats':
        return StatsScreen(deviceId: device.id);
      case 'ota':
        return OtaScreen(deviceId: device.id, currentVersion: device.fwVersion);
      case 'logs':
        return LogViewerScreen(deviceId: device.id);
      case 'settings':
        return DeviceSettingsScreen(deviceId: device.id, embedded: true);
      case 'overview':
      default:
        return _OverviewTab(
          device: device,
          onTab: (t) => setState(() => _tab = t),
        );
    }
  }
}

/// ---------------- Overview ----------------
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.device, required this.onTab});

  final Device device;
  final void Function(String) onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = device;
    // On Rằm / Mùng Một an online Luni auto-shifts to the night's mood.
    final sp = specialDay(ref.watch(lunarTodayProvider));
    final heroEmotion = (sp != null && d.isOnline) ? sp.emotion : d.emotion;
    final em = luniEmotion(heroEmotion);
    void setEmotion(String e) => ref
        .read(deviceListProvider.notifier)
        .sendCommand(d.id, DeviceCommand.setEmotion, value: e);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        // hero
        Container(
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.1),
              radius: 1.1,
              colors: [
                hexA(em.color, d.isOnline ? 0.16 : 0.04),
                LuniColors.bg1,
              ],
              stops: const [0.0, 0.6],
            ),
            borderRadius: BorderRadius.circular(LuniTokens.radius),
            border: Border.all(
                color: d.isOnline ? hexA(em.color, 0.22) : LuniColors.hairline),
          ),
          child: Column(
            children: [
              LuniFace(emotion: heroEmotion, size: 150, dim: !d.isOnline),
              const SizedBox(height: 14),
              Text(
                d.isOnline
                    ? 'Luni đang cảm thấy'
                    : 'Lần cuối trực tuyến 18 phút trước',
                style: const TextStyle(fontSize: 14, color: LuniColors.txMute),
              ),
              if (d.isOnline)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(em.label,
                      style: LuniTextStyles.h2.copyWith(color: em.color)),
                ),
              if (sp != null && d.isOnline)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: hexA(sp.color, 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: hexA(sp.color, 0.32)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MoonGlyph(p: ref.watch(lunarTodayProvider).p,
                            size: 15, color: sp.color, glow: false, ring: false),
                        const SizedBox(width: 6),
                        Text('Tự đổi vì ${sp.vi}',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: sp.color)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HeroBtn(
                      icon: 'sliders',
                      label: 'Điều khiển',
                      primary: true,
                      onTap: () => onTab('control')),
                  const SizedBox(width: 10),
                  _HeroBtn(
                      icon: 'sun',
                      label: 'Đánh thức',
                      onTap: () => setEmotion('happy')),
                  const SizedBox(width: 10),
                  _HeroBtn(
                      icon: 'wave',
                      label: 'Thư giãn',
                      onTap: () => setEmotion('calm')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // moon phase — Luni follows the lunar cycle
        MoonCard(accent: em.color),
        const SizedBox(height: 14),
        // stat grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _batteryStat(d)),
            const SizedBox(width: 12),
            Expanded(child: _wifiStat(d)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _firmwareStat(d, () => onTab('ota'))),
            const SizedBox(width: 12),
            Expanded(child: _locationStat(d)),
          ],
        ),
        const SectionLabel('Hoạt động gần đây'),
        _RecentActivity(onHistory: () => onTab('history')),
      ],
    );
  }

  Widget _batteryStat(Device d) {
    final color = d.isCharging
        ? LuniColors.green
        : d.batteryPercent <= 15
            ? LuniColors.red
            : LuniColors.cyan;
    return _StatCard(
      label: 'Pin',
      labelIcon: 'battery',
      child: RingProgress(
        value: d.batteryPercent.toDouble(),
        size: 96,
        stroke: 8,
        color: color,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                text: '${d.batteryPercent}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, height: 1),
                children: const [
                  TextSpan(text: '%', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (d.isCharging)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LuniIcon('bolt', size: 11, color: LuniColors.green),
                    SizedBox(width: 2),
                    Text('Sạc',
                        style: TextStyle(
                            fontSize: 10,
                            color: LuniColors.green,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wifiStat(Device d) {
    return _StatCard(
      label: d.isOnline ? 'Nha_Cua_Tui_5G' : 'Mất kết nối',
      labelIcon: 'signal',
      child: SizedBox(
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LuniIcon('wifi',
                size: 40,
                strokeWidth: 1.6,
                color: d.isOnline ? LuniColors.cyan : LuniColors.txFaint),
            const SizedBox(height: 6),
            Text('${d.rssi} dBm',
                style: LuniTextStyles.mono.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w700, color: LuniColors.tx)),
          ],
        ),
      ),
    );
  }

  Widget _firmwareStat(Device d, VoidCallback onTap) {
    return _StatCard(
      label: 'Firmware',
      labelIcon: 'download',
      onTap: onTap,
      child: SizedBox(
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LuniIcon('cpu', size: 38, strokeWidth: 1.5, color: LuniColors.purple),
            const SizedBox(height: 8),
            Text('v${d.fwVersion}',
                style: LuniTextStyles.mono.copyWith(
                    fontSize: 15, fontWeight: FontWeight.w700, color: LuniColors.tx)),
            const SizedBox(height: 6),
            const LuniPill(label: 'Có bản 2.2.0', color: LuniColors.warm),
          ],
        ),
      ),
    );
  }

  Widget _locationStat(Device d) {
    return _StatCard(
      label: 'Vị trí',
      labelIcon: 'globe',
      child: SizedBox(
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LuniIcon('location', size: 38, strokeWidth: 1.5, color: LuniColors.rose),
            const SizedBox(height: 8),
            Text(d.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${d.city} · GMT+7',
                style: const TextStyle(fontSize: 12, color: LuniColors.txMute)),
          ],
        ),
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  const _HeroBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.primary = false});

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: primary ? LuniColors.cyan : LuniColors.bg2,
                borderRadius: BorderRadius.circular(16),
                border: primary ? null : Border.all(color: LuniColors.hairline),
                boxShadow: primary ? LuniTokens.glow(LuniColors.cyan) : null,
              ),
              child: Center(
                child: LuniIcon(icon,
                    size: 22,
                    strokeWidth: primary ? 2.2 : 1.8,
                    color: primary ? LuniColors.onCyan : LuniColors.tx),
              ),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LuniColors.txSoft)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.child,
    required this.label,
    required this.labelIcon,
    this.onTap,
  });

  final Widget child;
  final String label;
  final String labelIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      decoration: BoxDecoration(
        color: LuniColors.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LuniColors.hairline),
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LuniIcon(labelIcon, size: 14, color: LuniColors.txFaint),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: LuniColors.txMute)),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return Press(onTap: onTap, child: body);
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.onHistory});
  final VoidCallback onHistory;

  static const _items = [
    ('happy', 'Phát nhạc theo lịch buổi sáng', '34p'),
    ('calm', 'Chuyển sang chế độ thư giãn', '1g'),
    ('curious', 'Wi-Fi yếu — tự động roaming', '1g'),
    ('idle', 'Đồng bộ với máy chủ', '2g'),
  ];

  @override
  Widget build(BuildContext context) {
    return LuniCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i < _items.length - 1
                    ? const Border(
                        bottom: BorderSide(color: LuniColors.hairline))
                    : null,
              ),
              child: Row(
                children: [
                  MoodDot(emotion: _items[i].$1, size: 9),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_items[i].$2,
                        style: const TextStyle(fontSize: 13.5)),
                  ),
                  Text(_items[i].$3,
                      style: LuniTextStyles.mono.copyWith(
                          fontSize: 11.5, color: LuniColors.txFaint)),
                ],
              ),
            ),
          Press(
            onTap: onHistory,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(0, 12, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Xem lịch sử trò chuyện',
                      style: TextStyle(
                          color: LuniColors.cyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                  SizedBox(width: 6),
                  LuniIcon('chevron', size: 16, color: LuniColors.cyan),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- Control ----------------
class _ControlTab extends ConsumerStatefulWidget {
  const _ControlTab({required this.device});
  final Device device;

  @override
  ConsumerState<_ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends ConsumerState<_ControlTab> {
  final _ttsController = TextEditingController();

  @override
  void dispose() {
    _ttsController.dispose();
    super.dispose();
  }

  DeviceListNotifier get _notifier => ref.read(deviceListProvider.notifier);

  void _ping(String msg) => luniToast(context, msg);

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final em = luniEmotion(d.emotion);
    final off = !d.isOnline;
    final sceneIcon = _sceneList
            .where((s) => s.$1 == d.scene)
            .map((s) => s.$2)
            .firstOrNull ??
        'grid';
    final emoIcon = _emotionList
            .where((e) => e.$1 == d.emotion)
            .map((e) => e.$2)
            .firstOrNull ??
        'eye';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      children: [
        // live preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [hexA(em.color, 0.1), LuniColors.bg1],
            ),
            borderRadius: BorderRadius.circular(LuniTokens.radius),
            border: Border.all(color: hexA(em.color, 0.2)),
          ),
          child: Row(
            children: [
              LuniFace(emotion: d.emotion, size: 68, dim: off),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TRẠNG THÁI TRỰC TIẾP', style: LuniTextStyles.cap),
                    const SizedBox(height: 2),
                    Text(off ? 'Ngoại tuyến' : em.label,
                        style: LuniTextStyles.h3.copyWith(
                            color: off ? LuniColors.txMute : em.color)),
                    const SizedBox(height: 2),
                    Text('Cảnh: ${sceneLabel(d.scene)}',
                        style: const TextStyle(
                            fontSize: 12.5, color: LuniColors.txMute)),
                  ],
                ),
              ),
              if (off)
                const LuniPill(label: 'Offline', color: LuniColors.orange),
            ],
          ),
        ),

        const SectionLabel('Biểu hiện trên màn hình'),
        LuniCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _PickRow(
                iconBg: hexA(em.color, 0.16),
                icon: emoIcon,
                iconColor: em.color,
                glow: !off,
                title: 'Cảm xúc',
                badge: ('Đang xem xét', LuniColors.orange),
                subtitle: 'Hiện tại: ${em.label} · 47 biểu cảm',
                enabled: !off,
                onTap: () => _openEmotionSheet(d),
              ),
              const Divider(indent: 14, endIndent: 14, height: 1),
              _PickRow(
                iconBg: hexA(
                    d.scene == 'sleep' ? LuniColors.purple : LuniColors.cyan,
                    0.14),
                icon: sceneIcon,
                iconColor: LuniColors.cyan,
                leading: d.scene == 'sleep'
                    ? MoonGlyph(
                        p: ref.watch(lunarTodayProvider).p,
                        size: 21,
                        color: LuniColors.purple)
                    : null,
                title: 'Cảnh hiển thị',
                badge: ('Tự động', LuniColors.cyan),
                subtitle: '${sceneLabel(d.scene)} · 32 cảnh',
                enabled: !off,
                onTap: () => _openSceneSheet(d),
              ),
            ],
          ),
        ),

        // TTS
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('CHO LUNI NÓI', style: LuniTextStyles.over),
              Text('ws · tts_play',
                  style: LuniTextStyles.mono
                      .copyWith(fontSize: 10.5, color: LuniColors.txFaint)),
            ],
          ),
        ),
        IgnorePointer(
          ignoring: off,
          child: Opacity(
            opacity: off ? 0.5 : 1,
            child: LuniCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: TextField(
                            controller: _ttsController,
                            style: const TextStyle(fontSize: 14.5),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (v) => _sendTts(v),
                            decoration: const InputDecoration(
                              hintText: 'Nhập câu cho Luni đọc to…',
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Press(
                        onTap: _ttsController.text.trim().isEmpty
                            ? null
                            : () => _sendTts(_ttsController.text),
                        child: Container(
                          width: 48,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _ttsController.text.trim().isEmpty
                                ? LuniColors.bg3
                                : LuniColors.cyan,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: LuniIcon('speaker',
                                size: 20,
                                color: _ttsController.text.trim().isEmpty
                                    ? LuniColors.txFaint
                                    : LuniColors.onCyan),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final s in const [
                        'Xin chào!',
                        'Đến giờ nghỉ rồi',
                        'Cố lên nhé 💪'
                      ])
                        Press(
                          onTap: () => _sendTts(s),
                          child: Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: LuniColors.bg2,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: LuniColors.hairline),
                            ),
                            child: Text(s,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: LuniColors.txSoft)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SectionLabel('Âm lượng & độ sáng'),
        IgnorePointer(
          ignoring: off,
          child: Opacity(
            opacity: off ? 0.5 : 1,
            child: Column(
              children: [
                LuniSlider(
                  value: d.config.volume,
                  icon: 'volume',
                  onChanged: (v) => _notifier.sendCommand(
                      d.id, DeviceCommand.setVolume, value: v),
                ),
                const SizedBox(height: 10),
                LuniSlider(
                  value: d.config.brightness,
                  icon: 'sun',
                  color: LuniColors.warm,
                  onChanged: (v) => _notifier.sendCommand(
                      d.id, DeviceCommand.setBrightness, value: v),
                ),
              ],
            ),
          ),
        ),

        const SectionLabel('Thao tác nhanh'),
        Row(
          children: [
            Expanded(
                child: _QuickAction(
                    icon: 'refresh',
                    label: 'Khởi động lại',
                    onTap: () {
                      _notifier.sendCommand(d.id, DeviceCommand.reboot);
                      _ping('Đã gửi lệnh khởi động lại');
                    })),
            const SizedBox(width: 10),
            Expanded(
                child: _QuickAction(
                    icon: 'power',
                    label: 'Dừng âm thanh',
                    onTap: () => _ping('Đã dừng phát âm thanh'))),
            const SizedBox(width: 10),
            Expanded(
                child: _QuickAction(
                    icon: 'volume',
                    label: 'Tắt tiếng',
                    onTap: () {
                      _notifier.sendCommand(d.id, DeviceCommand.mute);
                      _ping('Đã tắt tiếng');
                    })),
          ],
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: LuniIcon('info', size: 14, color: LuniColors.txFaint),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mọi lệnh gửi qua máy chủ tới robot bằng WebSocket (set_volume · set_brightness · set_emotion · reboot · tts_play).',
                  style: TextStyle(
                      fontSize: 11.5, color: LuniColors.txFaint, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendTts(String text) {
    if (text.trim().isEmpty) return;
    _notifier.sendCommand(widget.device.id, DeviceCommand.ttsPlay, value: text);
    _ttsController.clear();
    setState(() {});
    _ping('Đã gửi để Luni đọc');
  }

  void _openEmotionSheet(Device d) {
    showLuniSheet(
      context: context,
      title: 'Ghi đè cảm xúc',
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Luni có 47 biểu cảm; máy chủ tự chọn khi đang trả lời. Bạn có thể ghi đè thủ công sang một trong các trạng thái firmware bên dưới.',
              style: TextStyle(
                  fontSize: 12.5, color: LuniColors.txMute, height: 1.45),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
              children: [
                for (final (id, icon) in _emotionList)
                  _EmotionTile(
                    id: id,
                    icon: icon,
                    selected: d.emotion == id,
                    onTap: () {
                      _notifier.sendCommand(d.id, DeviceCommand.setEmotion,
                          value: id);
                      Navigator.pop(ctx);
                      _ping('Cảm xúc → ${luniEmotion(id).label}');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSceneSheet(Device d) {
    showLuniSheet(
      context: context,
      title: 'Cảnh hiển thị',
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Luni có 32 cảnh. Cảnh tự hiện khi có dữ liệu để hiển thị (thời tiết, đồng hồ, mạng…) — không chọn tay được.',
              style: TextStyle(
                  fontSize: 12.5, color: LuniColors.txMute, height: 1.45),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Kích hoạt theo dữ liệu',
                padding: EdgeInsets.only(bottom: 11)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, icon, color) in _sceneList)
                  Builder(builder: (_) {
                    final on = d.scene == id;
                    return Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: on ? hexA(LuniColors.cyan, 0.12) : LuniColors.bg2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: on
                                ? hexA(LuniColors.cyan, 0.4)
                                : LuniColors.hairline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (id == 'sleep')
                            MoonGlyph(
                                p: LuniMoon.today().p,
                                size: 16,
                                color: on ? LuniColors.cyan : color,
                                glow: false)
                          else
                            LuniIcon(icon,
                                size: 15,
                                strokeWidth: 1.9,
                                color: on ? LuniColors.cyan : color),
                          const SizedBox(width: 7),
                          Text(sceneLabel(id),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      on ? LuniColors.cyan : LuniColors.txSoft)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.glow = false,
    this.leading,
  });

  final Color iconBg;
  final String icon;
  final Color iconColor;
  final String title;
  final (String, Color) badge;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final bool glow;

  /// Overrides the leading [icon] (e.g. a phase-aware MoonGlyph for "sleep").
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Press(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  boxShadow: glow
                      ? [BoxShadow(color: hexA(iconColor, 0.28), blurRadius: 14)]
                      : null,
                ),
                child: Center(
                    child: leading ??
                        LuniIcon(icon,
                            size: 20, strokeWidth: 2, color: iconColor)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: hexA(badge.$2, 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(badge.$1,
                              style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: badge.$2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: LuniColors.txMute)),
                  ],
                ),
              ),
              const LuniIcon('chevron', size: 18, color: LuniColors.txFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmotionTile extends StatelessWidget {
  const _EmotionTile(
      {required this.id,
      required this.icon,
      required this.selected,
      required this.onTap});

  final String id;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = luniEmotion(id);
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 15, 6, 11),
        decoration: BoxDecoration(
          color: selected ? hexA(info.color, 0.14) : LuniColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? hexA(info.color, 0.5) : LuniColors.hairline,
              width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hexA(info.color, selected ? 0.2 : 0.1),
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [BoxShadow(color: hexA(info.color, 0.4), blurRadius: 16)]
                    : null,
              ),
              child: Center(
                  child: LuniIcon(icon,
                      size: 19, strokeWidth: 2, color: info.color)),
            ),
            const SizedBox(height: 8),
            Text(info.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? info.color : LuniColors.txSoft)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: LuniColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LuniColors.hairline),
        ),
        child: Column(
          children: [
            LuniIcon(icon, size: 22, strokeWidth: 1.8, color: LuniColors.txSoft),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LuniColors.txSoft)),
          ],
        ),
      ),
    );
  }
}
