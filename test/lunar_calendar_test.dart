import 'package:flutter_test/flutter_test.dart';
import 'package:luni_app/core/lunar/lunar_calendar.dart';

void main() {
  group('VnLunarCalendar.convertSolar2Lunar — Tết (mùng 1 tháng 1)', () {
    // Well-known Lunar New Year (Tết) Gregorian dates → lunar day 1, month 1.
    const tets = <(int, int, int)>[
      (25, 1, 2020),
      (12, 2, 2021),
      (1, 2, 2022),
      (22, 1, 2023),
      (10, 2, 2024),
      (29, 1, 2025),
      (17, 2, 2026),
    ];

    for (final (d, m, y) in tets) {
      test('$d/$m/$y is lunar 1/1', () {
        final r = VnLunarCalendar.convertSolar2Lunar(d, m, y, kVnTimeZone);
        expect(r.day, 1, reason: 'lunar day');
        expect(r.month, 1, reason: 'lunar month');
        // On Tết, lunarDay - 1 == days since the new moon (age 0).
        expect(r.dayNumber - r.monthStartJd, 0);
      });
    }
  });

  group('LunarInfo + specialDay', () {
    test('Tết 2026 (17/2) → Mùng Một, new moon (illum ~ 0)', () {
      final info = LuniMoon.forDate(DateTime(2026, 2, 17));
      expect(info.lunarDay, 1);
      expect(info.illum, lessThan(0.05));
      final sp = specialDay(info);
      expect(sp, isNotNull);
      expect(sp!.kind, 'soc');
      expect(sp.emotion, 'sleepy');
    });

    test('Rằm tháng Giêng 2026 (3/3) → đêm Rằm, full moon (illum ~ 1)', () {
      // 14 days after Tết 2026 → lunar day 15.
      final info = LuniMoon.forDate(DateTime(2026, 3, 3));
      expect(info.lunarDay, 15);
      expect(info.illum, greaterThan(0.9));
      final sp = specialDay(info);
      expect(sp, isNotNull);
      expect(sp!.kind, 'ram');
      expect(sp.emotion, 'excited');
    });

    test('ordinary day (24/2/2026, mùng 8) has no auto-mood', () {
      final info = LuniMoon.forDate(DateTime(2026, 2, 24));
      expect(info.lunarDay, 8);
      expect(specialDay(info), isNull);
      // ~half lit, waxing.
      expect(info.waxing, isTrue);
      expect(info.illum, inInclusiveRange(0.2, 0.8));
    });
  });

  group('phase math invariants', () {
    test('phase p, illum and nearest phase stay consistent', () {
      final info = LuniMoon.forDate(DateTime(2026, 2, 17));
      expect(info.p, inInclusiveRange(0.0, 1.0));
      expect(info.illum, inInclusiveRange(0.0, 1.0));
      expect(info.phaseIndex, inInclusiveRange(0, kMoonPhases.length - 1));
      // new moon → nearest canonical phase is 'new'
      expect(info.phase.key, 'new');
    });

    test('today() is cached and matches forDate(now)', () {
      final a = LuniMoon.today();
      final b = LuniMoon.today();
      expect(identical(a, b), isTrue);
    });
  });
}
