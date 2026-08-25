import 'package:flutter/foundation.dart';

@immutable
class PerfectJalaliDate {
  const PerfectJalaliDate({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;

  static PerfectJalaliDate fromGregorian(DateTime value) {
    final local = value.toLocal();
    var gy = local.year;
    final gm = local.month;
    final gd = local.day;
    const gregorianMonthOffsets = <int>[
      0,
      31,
      59,
      90,
      120,
      151,
      181,
      212,
      243,
      273,
      304,
      334,
    ];

    late int jy;
    if (gy > 1600) {
      jy = 979;
      gy -= 1600;
    } else {
      jy = 0;
      gy -= 621;
    }
    final leapAwareYear = gm > 2 ? gy + 1 : gy;
    var days =
        365 * gy +
        ((leapAwareYear + 3) ~/ 4) -
        ((leapAwareYear + 99) ~/ 100) +
        ((leapAwareYear + 399) ~/ 400) -
        80 +
        gd +
        gregorianMonthOffsets[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
    final jd = days < 186 ? 1 + days % 31 : 1 + (days - 186) % 30;
    return PerfectJalaliDate(year: jy, month: jm, day: jd);
  }
}

const _gregorianWeekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const _gregorianMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _jalaliMonths = <String>[
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

String perfectGregorianDate(DateTime value) {
  final local = value.toLocal();
  return '${_gregorianWeekdays[local.weekday - 1]}, '
      '${_gregorianMonths[local.month - 1]} ${local.day}, ${local.year}';
}

String perfectJalaliDate(DateTime value) {
  final jalali = PerfectJalaliDate.fromGregorian(value);
  return '${_persianDigits(jalali.day)} ${_jalaliMonths[jalali.month - 1]} '
      '${_persianDigits(jalali.year)}';
}

String perfectDualDate(DateTime value) =>
    '${perfectGregorianDate(value)}  ·  ${perfectJalaliDate(value)}';

String perfectLocalClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
}

String _persianDigits(Object value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return value.toString().split('').map((character) {
    final index = latin.indexOf(character);
    return index < 0 ? character : persian[index];
  }).join();
}
