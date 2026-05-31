import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';

/// ============================================================
/// Luni Moon — Vietnamese lunar engine. Luni *is* the moon, so the app
/// breathes with the synodic cycle: the orb wears tonight's phase, and Luni
/// auto-shifts mood on Rằm (đêm 15) and Mùng Một (đêm 1).
///
/// Phase/illumination come from the *astronomical* new-moon day that begins
/// the current lunar month, while the lunar day (1..30), month and year use
/// the standard Vietnamese calendar (thuật toán Hồ Ngọc Đức, múi giờ GMT+7).
/// Port of `ui_design/luni-moon.jsx`, minus the prototype-only date scrubber.
/// ============================================================

/// Mean synodic month in days.
const double kSynodic = 29.530588853;

/// Vietnam standard time zone offset (giờ Đông Dương, GMT+7).
const double kVnTimeZone = 7.0;

/// Special accents for the two extremes of the cycle.
const Color kFullGold = Color(0xFFFFD96B); // Rằm
const Color kNewViolet = Color(0xFFB9A0FF); // Sóc / mùng 1

/// One of the 8 canonical phases (tên dân gian + thiên văn).
class MoonPhase {
  const MoonPhase(this.key, this.vi, this.sub, this.p);
  final String key;
  final String vi;
  final String sub;
  final double p;
}

/// 8 canonical phases with Vietnamese names.
const List<MoonPhase> kMoonPhases = [
  MoonPhase('new', 'Trăng non', 'Sóc · mùng 1', 0.0),
  MoonPhase('wax-cre', 'Lưỡi liềm đầu', 'Trăng thượng tuần', 0.125),
  MoonPhase('first-q', 'Thượng huyền', 'Bán nguyệt đầu', 0.25),
  MoonPhase('wax-gib', 'Trăng khuyết đầu', 'Trương huyền đầu', 0.375),
  MoonPhase('full', 'Trăng tròn', 'Vọng · Rằm', 0.5),
  MoonPhase('wan-gib', 'Trăng khuyết cuối', 'Trương huyền cuối', 0.625),
  MoonPhase('last-q', 'Hạ huyền', 'Bán nguyệt cuối', 0.75),
  MoonPhase('wan-cre', 'Lưỡi liềm tàn', 'Trăng hạ tuần', 0.875),
];

/// Live lunar info for a given calendar day.
class LunarInfo {
  const LunarInfo({
    required this.p,
    required this.illum,
    required this.age,
    required this.lunarDay,
    required this.lunarMonth,
    required this.lunarYear,
    required this.isLeap,
    required this.waxing,
    required this.phaseIndex,
  });

  /// Synodic phase 0..1 (0 = new → .5 = full → 1 = new again).
  final double p;

  /// Illuminated fraction 0..1.
  final double illum;

  /// Days since the new moon that began this lunar month (0..~29).
  final int age;

  /// Vietnamese lunar day 1..30 (ngày âm lịch).
  final int lunarDay;
  final int lunarMonth;
  final int lunarYear;
  final bool isLeap;
  final bool waxing;
  final int phaseIndex;

  MoonPhase get phase => kMoonPhases[phaseIndex];
}

/// On the two extremes of the cycle Luni shifts mood on its own.
class SpecialDay {
  const SpecialDay({
    required this.kind, // 'ram' | 'soc'
    required this.vi,
    required this.emotion,
    required this.color,
    required this.desc,
  });
  final String kind;
  final String vi;
  final String emotion;
  final Color color;
  final String desc;
}

/// Returns the auto-mood shift for tonight, or null on ordinary days.
/// Rằm = đêm 15–16 (trăng tròn vài đêm liền); Mùng Một = đêm 1 (Sóc).
SpecialDay? specialDay(LunarInfo info) {
  if (info.lunarDay == 15 || info.lunarDay == 16) {
    return const SpecialDay(
      kind: 'ram',
      vi: 'Đêm Rằm',
      emotion: 'excited',
      color: LuniColors.warm, // #FFD166
      desc: 'Trăng tròn vành vạnh — Luni rạng rỡ, vầng sáng nở hết cỡ.',
    );
  }
  if (info.lunarDay == 1) {
    return const SpecialDay(
      kind: 'soc',
      vi: 'Mùng Một',
      emotion: 'sleepy',
      color: LuniColors.purple, // #B48CFF
      desc: 'Trăng tối (Sóc) — Luni trầm lắng, thắp ánh dịu để bầu bạn.',
    );
  }
  return null;
}

/// Accent for a moon glyph at the given illumination: warm-gold at Rằm, a
/// luminous violet at Sóc, the base tone otherwise.
({String kind, Color accent}) moonAccent(double illum, Color base) {
  if (illum > 0.985) return (kind: 'full', accent: kFullGold);
  if (illum < 0.03) return (kind: 'new', accent: kNewViolet);
  return (kind: 'normal', accent: base);
}

/// Standard Vietnamese lunar calendar (Hồ Ngọc Đức astronomical algorithm).
class VnLunarCalendar {
  const VnLunarCalendar._();

  static int _int(double d) => d.floor();

  /// Julian day number from a Gregorian date (proleptic before 1582-10-15).
  static int jdFromDate(int dd, int mm, int yy) {
    final a = _int((14 - mm) / 12);
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    var jd = dd +
        _int((153 * m + 2) / 5) +
        365 * y +
        _int(y / 4) -
        _int(y / 100) +
        _int(y / 400) -
        32045;
    if (jd < 2299161) {
      jd = dd + _int((153 * m + 2) / 5) + 365 * y + _int(y / 4) - 32083;
    }
    return jd;
  }

  /// Day of the k-th new moon since 1900-01-01, in the given time zone.
  static int getNewMoonDay(int k, double timeZone) {
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    const dr = math.pi / 180;
    var jd1 = 2415020.75933 +
        29.53058868 * k +
        0.0001178 * t2 -
        0.000000155 * t3;
    jd1 = jd1 +
        0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);
    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mpr =
        306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
    var c1 = (0.1734 - 0.000393 * t) * math.sin(m * dr) +
        0.0021 * math.sin(2 * dr * m);
    c1 = c1 - 0.4068 * math.sin(mpr * dr) + 0.0161 * math.sin(dr * 2 * mpr);
    c1 = c1 - 0.0004 * math.sin(dr * 3 * mpr);
    c1 = c1 + 0.0104 * math.sin(dr * 2 * f) - 0.0051 * math.sin(dr * (m + mpr));
    c1 = c1 -
        0.0074 * math.sin(dr * (m - mpr)) +
        0.0004 * math.sin(dr * (2 * f + m));
    c1 = c1 -
        0.0004 * math.sin(dr * (2 * f - m)) -
        0.0006 * math.sin(dr * (2 * f + mpr));
    c1 = c1 +
        0.0010 * math.sin(dr * (2 * f - mpr)) +
        0.0005 * math.sin(dr * (2 * mpr + m));
    double deltat;
    if (t < -11) {
      deltat = 0.001 +
          0.000839 * t +
          0.0002261 * t2 -
          0.00000845 * t3 -
          0.000000081 * t * t3;
    } else {
      deltat = -0.000278 + 0.000265 * t + 0.000262 * t2;
    }
    final jdNew = jd1 + c1 - deltat;
    return _int(jdNew + 0.5 + timeZone / 24);
  }

  /// Sun's ecliptic longitude bucket (0..11) at a julian day.
  static int getSunLongitude(int jdn, double timeZone) {
    final t = (jdn - 2451545.5 - timeZone / 24) / 36525;
    final t2 = t * t;
    const dr = math.pi / 180;
    final m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(dr * m);
    dl = dl +
        (0.019993 - 0.000101 * t) * math.sin(dr * 2 * m) +
        0.000290 * math.sin(dr * 3 * m);
    var l = l0 + dl;
    l = l * dr;
    l = l - math.pi * 2 * _int(l / (math.pi * 2));
    return _int(l / math.pi * 6);
  }

  /// Julian day of the 11th-month new moon for [yy].
  static int getLunarMonth11(int yy, double timeZone) {
    final off = jdFromDate(31, 12, yy) - 2415021;
    final k = _int(off / kSynodic);
    var nm = getNewMoonDay(k, timeZone);
    final sunLong = getSunLongitude(nm, timeZone);
    if (sunLong >= 9) {
      nm = getNewMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  static int getLeapMonthOffset(int a11, double timeZone) {
    final k = _int((a11 - 2415021.076998695) / kSynodic + 0.5);
    var last = 0;
    var i = 1;
    var arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc;
      i++;
      arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc != last && i < 14);
    return i - 1;
  }

  /// Converts a solar (Gregorian) date to the Vietnamese lunar date.
  /// Returns the lunar day/month/year, a leap flag and — additionally — the
  /// julian day of the new moon that begins the lunar month (for phase math).
  static ({
    int day,
    int month,
    int year,
    bool leap,
    int monthStartJd,
    int dayNumber,
  }) convertSolar2Lunar(int dd, int mm, int yy, double timeZone) {
    final dayNumber = jdFromDate(dd, mm, yy);
    final k = _int((dayNumber - 2415021.076998695) / kSynodic);
    var monthStart = getNewMoonDay(k + 1, timeZone);
    if (monthStart > dayNumber) {
      monthStart = getNewMoonDay(k, timeZone);
    }
    var a11 = getLunarMonth11(yy, timeZone);
    var b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = yy;
      a11 = getLunarMonth11(yy - 1, timeZone);
    } else {
      lunarYear = yy + 1;
      b11 = getLunarMonth11(yy + 1, timeZone);
    }
    final lunarDay = dayNumber - monthStart + 1;
    final diff = _int((monthStart - a11) / 29);
    var lunarLeap = false;
    var lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      final leapMonthDiff = getLeapMonthOffset(a11, timeZone);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) lunarLeap = true;
      }
    }
    if (lunarMonth > 12) lunarMonth -= 12;
    if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;
    return (
      day: lunarDay,
      month: lunarMonth,
      year: lunarYear,
      leap: lunarLeap,
      monthStartJd: monthStart,
      dayNumber: dayNumber,
    );
  }
}

/// Entry point for lunar info. Caches today's result so the many [LuniFace]
/// instances on screen share one computation.
class LuniMoon {
  const LuniMoon._();

  static String? _cacheKey;
  static LunarInfo? _cached;

  /// Lunar info for [date] (defaults to now), Vietnam time zone.
  static LunarInfo forDate(DateTime date) {
    final r = VnLunarCalendar.convertSolar2Lunar(
        date.day, date.month, date.year, kVnTimeZone);
    final age = r.dayNumber - r.monthStartJd; // integer days, 0..~29
    final p = (age / kSynodic) % 1.0;
    final illum = (1 - math.cos(2 * math.pi * p)) / 2;

    // nearest canonical phase (min circular distance)
    var nearest = 0;
    var best = 9.0;
    for (var i = 0; i < kMoonPhases.length; i++) {
      var d = (kMoonPhases[i].p - p).abs();
      d = math.min(d, 1 - d);
      if (d < best) {
        best = d;
        nearest = i;
      }
    }

    return LunarInfo(
      p: p,
      illum: illum,
      age: age,
      lunarDay: r.day,
      lunarMonth: r.month,
      lunarYear: r.year,
      isLeap: r.leap,
      waxing: p < 0.5,
      phaseIndex: nearest,
    );
  }

  /// Cached lunar info for today.
  static LunarInfo today() {
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    if (key != _cacheKey) {
      _cacheKey = key;
      _cached = forDate(now);
    }
    return _cached!;
  }
}

/// Today's lunar info, for widgets that want to rebuild reactively.
final lunarTodayProvider = Provider<LunarInfo>((ref) => LuniMoon.today());
