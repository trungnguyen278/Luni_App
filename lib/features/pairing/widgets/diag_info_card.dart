import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../shared/widgets/luni_kit.dart';

class DiagInfoCard extends StatelessWidget {
  const DiagInfoCard({required this.data, super.key});

  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return LuniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              LuniIcon('cpu', size: 18, color: LuniColors.purple),
              SizedBox(width: 8),
              Text('Chẩn đoán', style: LuniTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entries[i].key,
                        style: const TextStyle(color: LuniColors.txMute, fontSize: 13.5)),
                  ),
                  Text('${entries[i].value}',
                      style: LuniTextStyles.mono.copyWith(
                          fontWeight: FontWeight.w700, color: LuniColors.tx)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
