import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/device.dart';
import '../../../shared/widgets/luni_kit.dart';
import '../../../shared/widgets/luni_toast.dart';

class _Person {
  _Person(this.name, this.email, this.role,
      {this.userId, this.owner = false});
  final String name;
  final String email;
  final String role;
  final String? userId; // null for the owner row (cannot be removed)
  final bool owner;
}

/// Shared-users panel: invite field, QR option, and the access list.
/// Wired to the server's device-share endpoints
/// (GET/POST /devices/{id}/shares, DELETE /devices/{id}/shares/{userId}).
class SharingPanel extends ConsumerStatefulWidget {
  const SharingPanel({required this.device, super.key});
  final Device device;

  @override
  ConsumerState<SharingPanel> createState() => _SharingPanelState();
}

class _SharingPanelState extends ConsumerState<SharingPanel> {
  final _emailController = TextEditingController();
  List<_Person> _shares = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadShares() async {
    setState(() => _loading = true);
    final people = <_Person>[];

    // Owner row from the current session (owns/admins this device).
    final me = ref.read(authControllerProvider).user;
    if (me != null) {
      people.add(_Person(me.name, me.email, 'Chủ sở hữu', owner: true));
    }

    try {
      final api = ref.read(apiClientProvider);
      final res = await api
          .get<List<dynamic>>('/devices/${widget.device.id}/shares');
      for (final raw in res.data ?? const []) {
        if (raw is! Map) continue;
        final m = raw.cast<String, Object?>();
        people.add(_Person(
          (m['user_name'] as String?) ??
              (m['user_email'] as String? ?? '').split('@').first,
          m['user_email'] as String? ?? '',
          m['permission'] == 'view' ? 'Xem' : 'Điều khiển',
          userId: m['user_id'] as String?,
        ));
      }
    } catch (_) {
      // Owner-only fallback (e.g. shared viewer can't list shares).
    }

    if (!mounted) return;
    setState(() {
      _shares = people;
      _loading = false;
    });
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, Object?>>(
        '/devices/${widget.device.id}/share',
        data: {'email': email, 'permission': 'control'},
      );
      _emailController.clear();
      if (mounted) luniToast(context, 'Đã chia sẻ với $email');
      await _loadShares();
    } catch (e) {
      if (mounted) {
        luniToast(context, 'Không chia sẻ được: $e',
            icon: 'alert', color: LuniColors.red);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(_Person person) async {
    final userId = person.userId;
    if (userId == null || _busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.delete<Map<String, Object?>>(
        '/devices/${widget.device.id}/shares/$userId',
      );
      if (mounted) luniToast(context, 'Đã gỡ quyền truy cập');
      await _loadShares();
    } catch (e) {
      if (mounted) {
        luniToast(context, 'Không gỡ được: $e',
            icon: 'alert', color: LuniColors.red);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openQr() {
    showLuniSheet<void>(
      context: context,
      title: 'Chia sẻ bằng mã QR',
      builder: (_) => _QrSheet(device: widget.device, rootContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _emailController,
                    onSubmitted: (_) => _invite(),
                    decoration: const InputDecoration(
                      hintText: 'Mời qua email…',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Press(
                onTap: _busy ? null : _invite,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: LuniColors.cyan,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                      child: LuniIcon('plus',
                          size: 22,
                          color: LuniColors.onCyan,
                          strokeWidth: 2.2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Press(
            onTap: _openQr,
            child: DottedBorderBox(
              radius: 14,
              padding: const EdgeInsets.all(14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LuniIcon('qr', size: 20, color: LuniColors.cyan),
                  SizedBox(width: 10),
                  Text('Chia sẻ bằng mã QR',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: LuniColors.txSoft)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionLabel('Người có quyền (${_shares.length})',
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10)),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: CircularProgressIndicator(color: LuniColors.cyan)),
            )
          else
            for (final p in _shares) ...[
              _PersonTile(person: p, onRemove: p.owner ? null : () => _remove(p)),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, this.onRemove});
  final _Person person;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final color = person.owner ? LuniColors.cyan : LuniColors.txMute;
    return LuniCard2(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hexA(color, 0.16),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(person.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14.5)),
                Text(person.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: LuniColors.txMute)),
              ],
            ),
          ),
          LuniPill(
            label: person.role,
            color: person.owner ? LuniColors.cyan : LuniColors.txMute,
            bg: person.owner ? hexA(LuniColors.cyan, 0.14) : LuniColors.bg3,
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            Press(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: LuniIcon('trash', size: 18, color: LuniColors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// QR share sheet — a decorative (non-scannable) code + actions.
/// TODO(backend): replace QRPlaceholder with a real share-link QR.
class _QrSheet extends StatefulWidget {
  const _QrSheet({required this.device, required this.rootContext});
  final Device device;
  final BuildContext rootContext;

  @override
  State<_QrSheet> createState() => _QrSheetState();
}

class _QrSheetState extends State<_QrSheet> {
  int _gen = 0;

  String get _shortId {
    final clean = widget.device.id.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    final tail = clean.length >= 6 ? clean.substring(clean.length - 6) : clean;
    return 'LUNI-${tail.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quét mã này bằng app Luni trên điện thoại khác để nhận quyền điều khiển robot.',
          style: TextStyle(
              fontSize: 12.5, color: LuniColors.txMute, height: 1.45),
        ),
        const SizedBox(height: 16),
        Center(child: _QrPlaceholder(seed: '${widget.device.id}#$_gen')),
        const SizedBox(height: 14),
        Center(
          child: Text(_shortId,
              style: LuniTextStyles.mono.copyWith(
                  fontSize: 13, color: LuniColors.txSoft, letterSpacing: 1)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: LuniGhostButton(
                label: 'Sao chép liên kết',
                icon: 'copy',
                onPressed: () {
                  Navigator.pop(context);
                  luniToast(widget.rootContext, 'Đã sao chép liên kết',
                      icon: 'copy', color: LuniColors.cyan);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LuniCta(
                label: 'Mã mới',
                icon: 'refresh',
                onPressed: () {
                  setState(() => _gen++);
                  luniToast(context, 'Đã tạo mã mới', color: LuniColors.green);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// A deterministic, decorative QR-like pattern seeded by the device id.
class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({required this.seed});
  final String seed;

  static const double _size = 188;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        size: const Size.square(_size - 28),
        painter: _QrPainter(seed),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.seed);
  final String seed;
  static const _n = 21;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    final dark = Paint()
      ..color = const Color(0xFF0B0F18)
      ..isAntiAlias = true;

    var s = seed.hashCode & 0x7fffffff;
    if (s == 0) s = 1;
    double rnd() {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      return s / 0x7fffffff;
    }

    bool inFinder(int r, int c) {
      bool box(int or, int oc) => r >= or && r < or + 7 && c >= oc && c < oc + 7;
      return box(0, 0) || box(0, _n - 7) || box(_n - 7, 0);
    }

    void rect(int r, int c) =>
        canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), dark);

    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        final bit = rnd() > 0.52; // keep the RNG stream stable per cell
        if (inFinder(r, c)) continue;
        if (bit) rect(r, c);
      }
    }

    void finder(int or, int oc) {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 7; c++) {
          final edge = r == 0 || r == 6 || c == 0 || c == 6;
          final center = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          if (edge || center) rect(or + r, oc + c);
        }
      }
    }

    finder(0, 0);
    finder(0, _n - 7);
    finder(_n - 7, 0);
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}
