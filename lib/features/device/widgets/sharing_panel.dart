import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../shared/models/device.dart';
import '../../../shared/widgets/luni_kit.dart';

class _Person {
  _Person(this.name, this.email, this.role, this.emotion, {this.owner = false});
  final String name;
  final String email;
  final String role;
  final String emotion;
  final bool owner;
}

/// Shared-users panel: invite field, QR option, and the access list.
/// Port of `SharingPanel` in `ui_design/screens-settings.jsx`.
class SharingPanel extends StatefulWidget {
  const SharingPanel({required this.device, super.key});
  final Device device;

  @override
  State<SharingPanel> createState() => _SharingPanelState();
}

class _SharingPanelState extends State<SharingPanel> {
  final _emailController = TextEditingController();
  final List<_Person> _people = [
    _Person('Test User', 'test@example.com', 'Chủ sở hữu', 'happy', owner: true),
    _Person('Minh Anh', 'minhanh@vidu.com', 'Điều khiển', 'love'),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _invite() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _people.add(_Person(
          email.split('@').first, email, 'Xem', 'curious'));
      _emailController.clear();
    });
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
                onTap: _invite,
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
            onTap: () {},
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
          SectionLabel('Người có quyền (${_people.length})',
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10)),
          for (final p in _people) ...[
            _PersonTile(person: p),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person});
  final _Person person;

  @override
  Widget build(BuildContext context) {
    final color = luniEmotion(person.emotion).color;
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
        ],
      ),
    );
  }
}
