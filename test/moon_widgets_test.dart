import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luni_app/core/config/theme.dart';
import 'package:luni_app/shared/widgets/moon_glyph.dart';

void main() {
  testWidgets('MoonGlyph paints across the whole cycle without throwing',
      (tester) async {
    for (final p in [0.0, 0.125, 0.25, 0.5, 0.75, 0.875, 0.97]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(child: MoonGlyph(p: p, size: 64)),
        ),
      ));
      await tester.pump();
      expect(find.byType(MoonGlyph), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('MoonCard builds and shows the âm lịch line', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: LuniTheme.darkTheme,
        home: const Scaffold(
          body: Padding(padding: EdgeInsets.all(18), child: MoonCard()),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(MoonCard), findsOneWidget);
    expect(find.textContaining('Âm lịch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
