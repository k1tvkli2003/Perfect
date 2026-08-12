import 'dart:async';

import 'package:flutter/widgets.dart';

typedef PerfectNow = DateTime Function();
typedef PerfectMinuteSchedule =
    VoidCallback Function(Duration delay, VoidCallback callback);

VoidCallback _scheduleMinuteTick(Duration delay, VoidCallback callback) {
  final timer = Timer(delay, callback);
  return timer.cancel;
}

/// A deterministic Solar Hijri date projection.
///
/// Conversion deliberately lives in the client rather than depending on the
/// process locale. Perfect stores instants in UTC, then converts to device-local
/// time exactly once before deriving either calendar date.
@immutable
class PerfectJalaliDate {
  const PerfectJalaliDate({
    required this.year,
    required this.month,
    required this.day,
  });

  factory PerfectJalaliDate.fromGregorian(DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    if (local.year < 1600 || local.year > 3799) {
      throw RangeError.range(
        local.year,
        1600,
        3799,
        'value.year',
        'Perfect supports deterministic Jalali conversion from 1600 to 3799.',
      );
    }

    var gregorianYear = local.year - 1600;
    final gregorianMonth = local.month - 1;
    final gregorianDay = local.day - 1;
    var gregorianDayNumber =
        (365 * gregorianYear) +
        ((gregorianYear + 3) ~/ 4) -
        ((gregorianYear + 99) ~/ 100) +
        ((gregorianYear + 399) ~/ 400);
    const gregorianMonthDays = <int>[
      31,
      28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    for (var month = 0; month < gregorianMonth; month++) {
      gregorianDayNumber += gregorianMonthDays[month];
    }
    final gregorianLeap =
        local.year % 400 == 0 || (local.year % 4 == 0 && local.year % 100 != 0);
    if (gregorianMonth > 1 && gregorianLeap) gregorianDayNumber++;
    gregorianDayNumber += gregorianDay;

    var jalaliDayNumber = gregorianDayNumber - 79;
    final jalaliCycle = jalaliDayNumber ~/ 12053;
    jalaliDayNumber %= 12053;
    var jalaliYear = 979 + (33 * jalaliCycle) + (4 * (jalaliDayNumber ~/ 1461));
    jalaliDayNumber %= 1461;
    if (jalaliDayNumber >= 366) {
      jalaliYear += (jalaliDayNumber - 1) ~/ 365;
      jalaliDayNumber = (jalaliDayNumber - 1) % 365;
    }

    final jalaliMonth = jalaliDayNumber < 186
        ? 1 + (jalaliDayNumber ~/ 31)
        : 7 + ((jalaliDayNumber - 186) ~/ 30);
    final jalaliDay = jalaliDayNumber < 186
        ? 1 + (jalaliDayNumber % 31)
        : 1 + ((jalaliDayNumber - 186) % 30);
    return PerfectJalaliDate(
      year: jalaliYear,
      month: jalaliMonth,
      day: jalaliDay,
    );
  }

  final int year;
  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      other is PerfectJalaliDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// The single user-facing date/time vocabulary for Perfect.
abstract final class PerfectLocalTime {
  static const gregorianWeekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const gregorianMonths = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const gregorianMonthsShort = <String>[
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
  static const jalaliMonths = <String>[
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

  static DateTime local(DateTime value) =>
      value.isUtc ? value.toLocal() : value;

  static String clock(DateTime value, {bool includePeriod = true}) {
    final localValue = local(value);
    final hour = localValue.hour == 0
        ? 12
        : (localValue.hour > 12 ? localValue.hour - 12 : localValue.hour);
    final minute = localValue.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';
    if (!includePeriod) return time;
    return '$time ${localValue.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String gregorianLong(DateTime value, {bool includeYear = false}) {
    final localValue = local(value);
    final base =
        '${gregorianWeekdays[localValue.weekday - 1]}, '
        '${gregorianMonths[localValue.month - 1]} ${localValue.day}';
    return includeYear ? '$base, ${localValue.year}' : base;
  }

  static String gregorianShort(DateTime value, {bool includeYear = false}) {
    final localValue = local(value);
    final base =
        '${gregorianMonthsShort[localValue.month - 1]} ${localValue.day}';
    return includeYear ? '$base, ${localValue.year}' : base;
  }

  static String jalaliLong(DateTime value, {bool includeYear = true}) {
    final jalali = PerfectJalaliDate.fromGregorian(value);
    final base =
        '${persianDigits('${jalali.day}')} ${jalaliMonths[jalali.month - 1]}';
    return includeYear ? '$base ${persianDigits('${jalali.year}')}' : base;
  }

  static String dualDate(DateTime value, {bool includeGregorianYear = false}) =>
      '${gregorianLong(value, includeYear: includeGregorianYear)} · ${jalaliLong(value)}';

  static String inspector(DateTime value) {
    final localValue = local(value);
    return '${gregorianShort(localValue, includeYear: true)} · ${clock(localValue)}';
  }

  static String syncStamp(DateTime value) {
    final localValue = local(value);
    return '${gregorianShort(localValue, includeYear: true)} at ${clock(localValue)}';
  }

  static String persianDigits(String value) {
    const western = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return value.split('').map((character) {
      final index = western.indexOf(character);
      return index < 0 ? character : persian[index];
    }).join();
  }
}

/// Rebuilds only its builder subtree at the next real minute boundary.
///
/// One-shot scheduling is intentional: every tick reads the clock again, so a
/// timezone change, sleep/wake jump or delayed frame re-aligns instead of
/// accumulating periodic-timer drift.
class PerfectMinuteClockBuilder extends StatefulWidget {
  const PerfectMinuteClockBuilder({
    super.key,
    required this.builder,
    this.now = DateTime.now,
    this.schedule = _scheduleMinuteTick,
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final PerfectNow now;
  final PerfectMinuteSchedule schedule;

  @override
  State<PerfectMinuteClockBuilder> createState() =>
      _PerfectMinuteClockBuilderState();
}

class _PerfectMinuteClockBuilderState extends State<PerfectMinuteClockBuilder>
    with WidgetsBindingObserver {
  late DateTime _now;
  VoidCallback? _cancelTick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = PerfectLocalTime.local(widget.now());
    _scheduleNextTick();
  }

  @override
  void didUpdateWidget(covariant PerfectMinuteClockBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.now != widget.now || oldWidget.schedule != widget.schedule) {
      _refreshAndRealign();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAndRealign();
  }

  void _refreshAndRealign() {
    _cancelTick?.call();
    _cancelTick = null;
    final next = PerfectLocalTime.local(widget.now());
    if (mounted) setState(() => _now = next);
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    final current = PerfectLocalTime.local(widget.now());
    final elapsed = Duration(
      seconds: current.second,
      milliseconds: current.millisecond,
      microseconds: current.microsecond,
    );
    final delay = const Duration(minutes: 1) - elapsed;
    _cancelTick = widget.schedule(delay, () {
      if (!mounted) return;
      final next = PerfectLocalTime.local(widget.now());
      setState(() => _now = next);
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _cancelTick?.call();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
