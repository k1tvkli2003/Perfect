import 'planner_entity.dart';

/// Explicit outcome for a missed task or habit occurrence. The UI can surface
/// an `ask` outcome without ever silently moving a user's work.
enum PlannerRecoveryDisposition {
  pending('pending'),
  missed('missed'),
  carryForward('carry_forward'),
  ask('ask');

  const PlannerRecoveryDisposition(this.wireValue);

  final String wireValue;
}

class PlannerRecoveryOutcome {
  const PlannerRecoveryOutcome({
    required this.disposition,
    required this.nextEligibleAt,
    required this.carryCount,
    this.reason,
  });

  final PlannerRecoveryDisposition disposition;
  final DateTime? nextEligibleAt;
  final int carryCount;
  final String? reason;

  @override
  String toString() {
    final parts = <String>['${disposition.wireValue}', 'carry=$carryCount'];
    if (nextEligibleAt != null) {
      parts.add('next=${nextEligibleAt!.toUtc().toIso8601String()}');
    }
    if (reason != null) parts.add("'$reason'");
    return 'PlannerRecoveryOutcome(${parts.join(', ')})';
  }
}

enum PlannerTodayEligibilityReason {
  unscheduled,
  scheduledToday,
  completedToday,
  recurringOccurrence,
  carriedForward,
  awaitingRecoveryDecision,
  inactive,
  scheduledLater,
  recoveredAsMissed,
  notScheduledToday,
}

/// A shared, side-effect-free answer for every surface that projects Today.
///
/// `isEligible` deliberately stays true when recovery requires the owner to
/// decide. That prevents capped carry-forward work from silently disappearing,
/// while [requiresDecision] lets interactive surfaces render the right action
/// instead of pretending the item was carried again.
class PlannerTodayEligibility {
  const PlannerTodayEligibility({
    required this.isEligible,
    required this.reason,
    this.recovery,
  });

  final bool isEligible;
  final PlannerTodayEligibilityReason reason;
  final PlannerRecoveryOutcome? recovery;

  bool get requiresDecision =>
      recovery?.disposition == PlannerRecoveryDisposition.ask;

  @override
  String toString() {
    final state = isEligible ? 'eligible' : 'ineligible';
    if (recovery == null) return 'PlannerTodayEligibility($state, ${reason.name})';
    return 'PlannerTodayEligibility($state, ${reason.name}, recovery=$recovery)';
  }
}

/// Pure lifecycle rules shared by the interaction layer, notification planner,
/// and any future server-side occurrence projection. Nothing here writes data.
abstract final class PlannerRecoveryEngine {
  static PlannerRecoveryOutcome resolveMiss({
    required PlannerEntity entity,
    required DateTime occurrenceAt,
    required DateTime now,
    int carryCount = 0,
  }) {
    final recovery = entity.recovery;
    final configured = safeNullableJsonString(recovery['on_miss']);
    final policy = configured ?? _defaultPolicy(entity);
    final cap = safeJsonInt(recovery['carry_cap'], fallback: 7).clamp(1, 30);
    final next = PlannerRecurrenceEngine.nextEligibleAt(
      entity: entity,
      after: occurrenceAt,
    );
    return switch (policy) {
      'ask' => PlannerRecoveryOutcome(
        disposition: PlannerRecoveryDisposition.ask,
        nextEligibleAt: next,
        carryCount: carryCount,
        reason: 'Your preference is to decide before moving a missed item.',
      ),
      'pending' when carryCount >= cap => PlannerRecoveryOutcome(
        disposition: PlannerRecoveryDisposition.ask,
        nextEligibleAt: next,
        carryCount: carryCount,
        reason: 'Carry cap reached after $cap days.',
      ),
      'pending' => PlannerRecoveryOutcome(
        disposition: PlannerRecoveryDisposition.carryForward,
        nextEligibleAt: now.isAfter(occurrenceAt) ? now : occurrenceAt,
        carryCount: carryCount + 1,
      ),
      'carry_forward' ||
      'carry' when carryCount >= cap => PlannerRecoveryOutcome(
        disposition: PlannerRecoveryDisposition.ask,
        nextEligibleAt: next,
        carryCount: carryCount,
        reason: 'Carry cap reached after $cap days.',
      ),
      'carry_forward' || 'carry' => PlannerRecoveryOutcome(
        disposition: PlannerRecoveryDisposition.carryForward,
        nextEligibleAt: now.isAfter(occurrenceAt) ? now : occurrenceAt,
        carryCount: carryCount + 1,
      ),
      _ => PlannerRecoveryOutcome(
        disposition: PlannerRecoveryDisposition.missed,
        nextEligibleAt: next,
        carryCount: 0,
      ),
    };
  }

  static String _defaultPolicy(PlannerEntity entity) {
    if (entity.kind == PlannerEntityKind.oneOffTask) return 'pending';
    return 'miss_then_next';
  }
}

/// Canonical Today projection for the app, Android widget, and future Windows
/// widget. All calendar comparisons are made in the device's local calendar.
abstract final class PlannerTodayEngine {
  static PlannerTodayEligibility evaluate({
    required PlannerEntity entity,
    required DateTime day,
    int? carryCount,
    int completedOccurrencesInPeriod = 0,
    int totalCompletedOccurrences = 0,
  }) {
    if (entity.isDeleted ||
        entity.status == PlannerEntityStatus.archived ||
        entity.status == PlannerEntityStatus.cancelled) {
      return const PlannerTodayEligibility(
        isEligible: false,
        reason: PlannerTodayEligibilityReason.inactive,
      );
    }

    final today = PlannerRecurrenceEngine._localDate(day.toLocal());
    final scheduled = entity.scheduledAt?.toLocal();
    if (entity.kind == PlannerEntityKind.oneOffTask) {
      if (entity.status == PlannerEntityStatus.completed) {
        final completedAt = safeJsonDateTime(
          entity.payload['completed_at'],
        )?.toLocal();
        final completedToday =
            scheduled != null &&
                PlannerRecurrenceEngine._sameLocalDate(scheduled, today) ||
            completedAt != null &&
                PlannerRecurrenceEngine._sameLocalDate(completedAt, today);
        return PlannerTodayEligibility(
          isEligible: completedToday,
          reason: completedToday
              ? PlannerTodayEligibilityReason.completedToday
              : PlannerTodayEligibilityReason.inactive,
        );
      }
      if (scheduled == null) {
        return const PlannerTodayEligibility(
          isEligible: true,
          reason: PlannerTodayEligibilityReason.unscheduled,
        );
      }

      final scheduledDay = PlannerRecurrenceEngine._localDate(scheduled);
      if (scheduledDay.isAfter(today)) {
        return const PlannerTodayEligibility(
          isEligible: false,
          reason: PlannerTodayEligibilityReason.scheduledLater,
        );
      }
      if (PlannerRecurrenceEngine._sameLocalDate(scheduledDay, today)) {
        return const PlannerTodayEligibility(
          isEligible: true,
          reason: PlannerTodayEligibilityReason.scheduledToday,
        );
      }

      final resolution = safeJsonMap(
        entity.recovery[PlannerRecoveryKeys.resolution],
      );
      final resolvedDisposition = safeNullableJsonString(
        resolution[PlannerRecoveryKeys.disposition],
      );
      final resolvedFor = safeJsonDateTime(
        resolution[PlannerRecoveryKeys.resolvedFor],
      );
      final resolvesThisOccurrence =
          resolvedFor != null &&
          PlannerRecurrenceEngine._sameLocalDate(resolvedFor, scheduledDay);
      final legacyMissResolution =
          entity.payload[PlannerPayloadKeys.taskProgressState] == 'missed';
      if (legacyMissResolution ||
          resolvesThisOccurrence &&
              resolvedDisposition ==
                  PlannerRecoveryDisposition.missed.wireValue) {
        return const PlannerTodayEligibility(
          isEligible: false,
          reason: PlannerTodayEligibilityReason.recoveredAsMissed,
        );
      }
      final resolvedAt = safeJsonDateTime(
        resolution[PlannerRecoveryKeys.resolvedAt],
      );
      if (resolvesThisOccurrence &&
          (resolvedDisposition ==
                  PlannerRecoveryDisposition.pending.wireValue ||
              resolvedDisposition ==
                  PlannerRecoveryDisposition.carryForward.wireValue) &&
          resolvedAt != null &&
          PlannerRecurrenceEngine._sameLocalDate(resolvedAt, today)) {
        return PlannerTodayEligibility(
          isEligible: true,
          reason: PlannerTodayEligibilityReason.carriedForward,
          recovery: PlannerRecoveryOutcome(
            disposition: PlannerRecoveryDisposition.carryForward,
            nextEligibleAt: day,
            carryCount: safeJsonInt(
              resolution[PlannerRecoveryKeys.carryCount],
              fallback: 0,
            ),
          ),
        );
      }

      final configuredCarryCount =
          carryCount ??
          safeJsonInt(
            entity.recovery['carry_count'],
            fallback: PlannerRecurrenceEngine._calendarDayDifference(
              scheduledDay,
              today,
            ),
          ).clamp(0, 1000000).toInt();
      final recovery = PlannerRecoveryEngine.resolveMiss(
        entity: entity,
        occurrenceAt: scheduled,
        now: day,
        carryCount: configuredCarryCount,
      );
      return switch (recovery.disposition) {
        PlannerRecoveryDisposition.pending ||
        PlannerRecoveryDisposition.carryForward => PlannerTodayEligibility(
          isEligible: true,
          reason: PlannerTodayEligibilityReason.carriedForward,
          recovery: recovery,
        ),
        PlannerRecoveryDisposition.ask => PlannerTodayEligibility(
          isEligible: true,
          reason: PlannerTodayEligibilityReason.awaitingRecoveryDecision,
          recovery: recovery,
        ),
        PlannerRecoveryDisposition.missed => PlannerTodayEligibility(
          isEligible: false,
          reason: PlannerTodayEligibilityReason.recoveredAsMissed,
          recovery: recovery,
        ),
      };
    }

    if (entity.status == PlannerEntityStatus.completed) {
      return const PlannerTodayEligibility(
        isEligible: false,
        reason: PlannerTodayEligibilityReason.inactive,
      );
    }

    final occursToday = PlannerRecurrenceEngine.occursOnDate(
      entity: entity,
      date: today,
      completedOccurrencesInPeriod: completedOccurrencesInPeriod,
      totalCompletedOccurrences: totalCompletedOccurrences,
    );
    return PlannerTodayEligibility(
      isEligible: occursToday,
      reason: occursToday
          ? PlannerTodayEligibilityReason.recurringOccurrence
          : PlannerTodayEligibilityReason.notScheduledToday,
    );
  }
}

class PlannerRecurrencePeriodWindow {
  const PlannerRecurrencePeriodWindow({
    required this.period,
    required this.startInclusive,
    required this.endExclusive,
  });

  final String period;
  final DateTime startInclusive;
  final DateTime endExclusive;
}

class PlannerRecurrenceHistory {
  const PlannerRecurrenceHistory({
    this.completedInPeriod = 0,
    this.totalCompleted = 0,
  });

  /// Successful occurrences in the flexible period containing the query day.
  final int completedInPeriod;

  /// Successful occurrences across the entity's retained lifetime history.
  final int totalCompleted;
}

/// Deterministic recurrence expansion for the rule surface exposed in the
/// editor. Times remain in the item's stored timezone representation; callers
/// persist instants as UTC once a choice is made.
abstract final class PlannerRecurrenceEngine {
  static PlannerRecurrencePeriodWindow? flexiblePeriodWindow({
    required PlannerEntity entity,
    required DateTime date,
  }) {
    final frequency = safeJsonMap(
      entity.recurrence[PlannerRecurrenceKeys.frequency],
    );
    if (frequency.isEmpty) return null;
    final period = safeJsonString(
      frequency[PlannerRecurrenceKeys.frequencyPeriod],
      fallback: 'week',
    );
    final local = _localDate(date.toLocal());
    switch (period) {
      case 'week':
        final start = local.subtract(
          Duration(days: local.weekday - DateTime.monday),
        );
        return PlannerRecurrencePeriodWindow(
          period: period,
          startInclusive: start.toUtc(),
          endExclusive: start.add(const Duration(days: 7)).toUtc(),
        );
      case 'month':
        return PlannerRecurrencePeriodWindow(
          period: period,
          startInclusive: DateTime(local.year, local.month).toUtc(),
          endExclusive: DateTime(local.year, local.month + 1).toUtc(),
        );
      default:
        return null;
    }
  }

  static bool occursOnDate({
    required PlannerEntity entity,
    required DateTime date,
    int completedOccurrencesInPeriod = 0,
    int totalCompletedOccurrences = 0,
  }) {
    final target = _localDate(date.toLocal());
    final recurrence = entity.recurrence;
    if (recurrence['paused'] == true) return false;

    final endAt = safeJsonDateTime(recurrence['end_at'])?.toLocal();
    if (endAt != null && target.isAfter(_localDate(endAt))) return false;
    if (_exceptionDates(
      recurrence,
    ).any((exception) => _sameLocalDate(exception, target))) {
      return false;
    }

    final scheduled = entity.scheduledAt?.toLocal();
    final anchor = _localDate((scheduled ?? entity.createdAt).toLocal());
    if (target.isBefore(anchor)) return false;
    final rule = safeJsonString(
      recurrence[PlannerRecurrenceKeys.rule],
      fallback: 'none',
    );
    if (rule == 'none') {
      // Older unscheduled habits predate explicit recurrence and were daily.
      return scheduled == null && entity.kind == PlannerEntityKind.habit ||
          scheduled != null && _sameLocalDate(scheduled, target);
    }

    final interval = safeJsonInt(
      recurrence[PlannerRecurrenceKeys.interval],
      fallback: 1,
    ).clamp(1, 99).toInt();
    final dayDelta = _calendarDayDifference(anchor, target);
    final frequency = safeJsonMap(recurrence[PlannerRecurrenceKeys.frequency]);
    late final bool eligible;
    late final int ordinal;

    if (rule == 'flexible' || frequency.isNotEmpty) {
      final required = safeJsonInt(
        frequency[PlannerRecurrenceKeys.frequencyCount],
        fallback: 1,
      ).clamp(1, 31).toInt();
      final period = safeJsonString(
        frequency[PlannerRecurrenceKeys.frequencyPeriod],
        fallback: 'week',
      );
      eligible =
          (period == 'week' || period == 'month') &&
          completedOccurrencesInPeriod < required;
      ordinal = totalCompletedOccurrences + 1;
    } else {
      switch (rule) {
        case 'daily':
        case 'interval':
          eligible = dayDelta % interval == 0;
          ordinal = eligible
              ? _dailyOccurrenceCount(
                  recurrence: recurrence,
                  anchor: anchor,
                  target: target,
                  interval: interval,
                )
              : 0;
          break;
        case 'weekdays':
          eligible =
              target.weekday >= DateTime.monday &&
              target.weekday <= DateTime.friday;
          ordinal = eligible
              ? _weekdayOccurrenceCount(
                  recurrence: recurrence,
                  anchor: anchor,
                  target: target,
                )
              : 0;
          break;
        case 'weekly':
          final weekdays = _weekdays(recurrence, fallback: anchor.weekday);
          final weeks =
              _calendarDayDifference(
                _startOfWeek(anchor),
                _startOfWeek(target),
              ) ~/
              7;
          eligible = weeks % interval == 0 && weekdays.contains(target.weekday);
          ordinal = eligible
              ? _weeklyOccurrenceCount(
                  anchor: anchor,
                  target: target,
                  interval: interval,
                  weekdays: weekdays,
                  recurrence: recurrence,
                )
              : 0;
          break;
        case 'monthly':
          final monthDelta =
              (target.year - anchor.year) * 12 + target.month - anchor.month;
          eligible =
              monthDelta % interval == 0 &&
              _monthDaysFor(
                recurrence: recurrence,
                anchor: anchor,
                year: target.year,
                month: target.month,
              ).contains(target.day);
          ordinal = eligible
              ? _monthlyOccurrenceCount(
                  recurrence: recurrence,
                  anchor: anchor,
                  target: target,
                  interval: interval,
                )
              : 0;
          break;
        case 'yearly':
          final yearDelta = target.year - anchor.year;
          eligible =
              yearDelta % interval == 0 &&
              _annualDatesFor(
                recurrence: recurrence,
                anchor: anchor,
                year: target.year,
              ).contains((target.month, target.day));
          ordinal = eligible
              ? _yearlyOccurrenceCount(
                  recurrence: recurrence,
                  anchor: anchor,
                  target: target,
                  interval: interval,
                )
              : 0;
          break;
        default:
          return false;
      }
    }
    if (!eligible) return false;
    final occurrenceLimit = safeJsonInt(
      recurrence[PlannerRecurrenceKeys.occurrenceLimit],
      fallback: 0,
    );
    return occurrenceLimit <= 0 || ordinal <= occurrenceLimit;
  }

  static DateTime? nextEligibleAt({
    required PlannerEntity entity,
    required DateTime after,

    /// Lifetime successful occurrence count. For flexible rules this enforces
    /// `occurrence_limit` independently from the current period quota.
    int completedOccurrences = 0,

    /// Successful occurrences only in the flexible period containing [after].
    /// The value resets to zero when expansion reaches a later period.
    int completedOccurrencesInPeriod = 0,
  }) {
    final recurrence = entity.recurrence;
    final rule = safeJsonString(
      recurrence[PlannerRecurrenceKeys.rule],
      fallback: 'none',
    );
    final frequency = safeJsonMap(recurrence[PlannerRecurrenceKeys.frequency]);
    if ((rule == 'none' && frequency.isEmpty) ||
        recurrence[PlannerRecurrenceKeys.paused] == true) {
      return null;
    }
    final occurrenceLimit = safeJsonInt(
      recurrence[PlannerRecurrenceKeys.occurrenceLimit],
      fallback: 0,
    );
    if (occurrenceLimit > 0 && completedOccurrences >= occurrenceLimit) {
      return null;
    }
    final interval = safeJsonInt(
      recurrence[PlannerRecurrenceKeys.interval],
      fallback: 1,
    ).clamp(1, 99).toInt();
    final local = after.toLocal();
    final anchor = (entity.scheduledAt ?? entity.createdAt).toLocal();
    final maxDays = switch (rule) {
      'yearly' => 366 * (interval + 1),
      'monthly' => 31 * (interval + 1),
      _ => 3660,
    };
    final firstDate = _localDate(local);
    final referenceFlexibleWindow = flexiblePeriodWindow(
      entity: entity,
      date: after,
    );
    for (var offset = 0; offset <= maxDays; offset++) {
      final date = firstDate.add(Duration(days: offset));
      final candidate = DateTime(
        date.year,
        date.month,
        date.day,
        anchor.hour,
        anchor.minute,
        anchor.second,
        anchor.millisecond,
        anchor.microsecond,
      );
      final candidateUtc = candidate.toUtc();
      final completedInCandidatePeriod =
          referenceFlexibleWindow != null &&
              !candidateUtc.isBefore(referenceFlexibleWindow.startInclusive) &&
              candidateUtc.isBefore(referenceFlexibleWindow.endExclusive)
          ? completedOccurrencesInPeriod
          : 0;
      if (_afterEnd(candidate, recurrence)) return null;
      if (candidate.isAfter(local) &&
          occursOnDate(
            entity: entity,
            date: candidate,
            completedOccurrencesInPeriod: completedInCandidatePeriod,
            totalCompletedOccurrences: completedOccurrences,
          )) {
        return candidateUtc;
      }
    }
    return null;
  }

  static int _clampDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return day.clamp(1, last).toInt();
  }

  static Set<int> _monthDaysFor({
    required Map<String, dynamic> recurrence,
    required DateTime anchor,
    required int year,
    required int month,
  }) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final result = <int>{};
    final configured = recurrence[PlannerRecurrenceKeys.monthDays];
    var hasExplicitConfiguration =
        recurrence[PlannerRecurrenceKeys.lastDayOfMonth] == true;
    if (configured is Iterable) {
      for (final value in configured) {
        hasExplicitConfiguration = true;
        final normalized = value.toString().trim().toLowerCase();
        if (normalized == 'last' || normalized == '-1') {
          result.add(lastDay);
          continue;
        }
        final day = safeJsonInt(value, fallback: 0);
        if (day >= 1 && day <= lastDay) result.add(day);
      }
    }
    if (recurrence[PlannerRecurrenceKeys.lastDayOfMonth] == true) {
      result.add(lastDay);
    }
    if (result.isEmpty && !hasExplicitConfiguration) {
      result.add(_clampDay(year, month, anchor.day));
    }
    return result;
  }

  static int _monthlyOccurrenceCount({
    required Map<String, dynamic> recurrence,
    required DateTime anchor,
    required DateTime target,
    required int interval,
  }) {
    final targetMonth =
        (target.year - anchor.year) * 12 + target.month - anchor.month;
    var count = 0;
    for (
      var monthOffset = 0;
      monthOffset <= targetMonth;
      monthOffset += interval
    ) {
      final monthIndex = anchor.month - 1 + monthOffset;
      final year = anchor.year + monthIndex ~/ 12;
      final month = monthIndex % 12 + 1;
      final days = _monthDaysFor(
        recurrence: recurrence,
        anchor: anchor,
        year: year,
        month: month,
      ).toList()..sort();
      for (final day in days) {
        final candidate = DateTime(year, month, day);
        if (candidate.isBefore(anchor) || candidate.isAfter(target)) continue;
        if (_isException(recurrence, candidate)) continue;
        count++;
      }
    }
    return count;
  }

  static Set<(int, int)> _annualDatesFor({
    required Map<String, dynamic> recurrence,
    required DateTime anchor,
    required int year,
  }) {
    final result = <(int, int)>{};
    final configured = recurrence[PlannerRecurrenceKeys.annualDates];
    var hasExplicitConfiguration = false;
    if (configured is Iterable) {
      for (final value in configured) {
        hasExplicitConfiguration = true;
        int month = 0;
        int day = 0;
        if (value is Map) {
          month = safeJsonInt(value['month'], fallback: 0);
          day = safeJsonInt(value['day'], fallback: 0);
        } else if (value is String) {
          final match = RegExp(
            r'^(\d{1,2})[-/](\d{1,2})$',
          ).firstMatch(value.trim());
          if (match != null) {
            month = int.tryParse(match.group(1)!) ?? 0;
            day = int.tryParse(match.group(2)!) ?? 0;
          }
        }
        if (month < 1 || month > 12) continue;
        final lastDay = DateTime(year, month + 1, 0).day;
        if (day >= 1 && day <= lastDay) result.add((month, day));
      }
    }
    if (result.isEmpty && !hasExplicitConfiguration) {
      result.add((anchor.month, _clampDay(year, anchor.month, anchor.day)));
    }
    return result;
  }

  static int _yearlyOccurrenceCount({
    required Map<String, dynamic> recurrence,
    required DateTime anchor,
    required DateTime target,
    required int interval,
  }) {
    var count = 0;
    for (var year = anchor.year; year <= target.year; year += interval) {
      final dates =
          _annualDatesFor(
            recurrence: recurrence,
            anchor: anchor,
            year: year,
          ).toList()..sort((left, right) {
            final month = left.$1.compareTo(right.$1);
            return month == 0 ? left.$2.compareTo(right.$2) : month;
          });
      for (final date in dates) {
        final candidate = DateTime(year, date.$1, date.$2);
        if (candidate.isBefore(anchor) || candidate.isAfter(target)) continue;
        if (_isException(recurrence, candidate)) continue;
        count++;
      }
    }
    return count;
  }

  static Set<int> _weekdays(
    Map<String, dynamic> recurrence, {
    required int fallback,
  }) {
    final stored = recurrence['weekdays'];
    final allowed = stored is Iterable
        ? stored
              .map((value) => safeJsonInt(value, fallback: -1))
              .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
              .toSet()
        : <int>{};
    return allowed.isEmpty ? <int>{fallback} : allowed;
  }

  static int _dailyOccurrenceCount({
    required Map<String, dynamic> recurrence,
    required DateTime anchor,
    required DateTime target,
    required int interval,
  }) {
    final days = _calendarDayDifference(anchor, target);
    var count = 0;
    for (var offset = 0; offset <= days; offset += interval) {
      final candidate = anchor.add(Duration(days: offset));
      if (!_isException(recurrence, candidate)) count++;
    }
    return count;
  }

  static int _weekdayOccurrenceCount({
    required Map<String, dynamic> recurrence,
    required DateTime anchor,
    required DateTime target,
  }) {
    final days = _calendarDayDifference(anchor, target);
    var count = 0;
    for (var offset = 0; offset <= days; offset++) {
      final candidate = anchor.add(Duration(days: offset));
      if (candidate.weekday >= DateTime.monday &&
          candidate.weekday <= DateTime.friday &&
          !_isException(recurrence, candidate)) {
        count++;
      }
    }
    return count;
  }

  static int _weeklyOccurrenceCount({
    required DateTime anchor,
    required DateTime target,
    required int interval,
    required Set<int> weekdays,
    required Map<String, dynamic> recurrence,
  }) {
    var count = 0;
    final anchorWeek = _startOfWeek(anchor);
    final lastWeek = _startOfWeek(target);
    for (
      var week = anchorWeek;
      !week.isAfter(lastWeek);
      week = week.add(Duration(days: 7 * interval))
    ) {
      for (final weekday in weekdays) {
        final candidate = week.add(Duration(days: weekday - DateTime.monday));
        if (!candidate.isBefore(anchor) &&
            !candidate.isAfter(target) &&
            !_isException(recurrence, candidate)) {
          count++;
        }
      }
    }
    return count;
  }

  static DateTime _startOfWeek(DateTime value) => DateTime(
    value.year,
    value.month,
    value.day,
  ).subtract(Duration(days: value.weekday - DateTime.monday));

  static List<DateTime> _exceptionDates(Map<String, dynamic> recurrence) {
    final values = recurrence[PlannerRecurrenceKeys.exceptions];
    if (values is! Iterable) return const <DateTime>[];
    return values.map(safeJsonDateTime).whereType<DateTime>().toList();
  }

  static bool _isException(
    Map<String, dynamic> recurrence,
    DateTime candidate,
  ) => _exceptionDates(
    recurrence,
  ).any((exception) => _sameLocalDate(exception, candidate));

  static bool _afterEnd(DateTime candidate, Map<String, dynamic> recurrence) {
    final endAt = safeJsonDateTime(recurrence[PlannerRecurrenceKeys.endAt]);
    if (endAt == null) return false;
    final localCandidate = candidate.toLocal();
    final localEnd = endAt.toLocal();
    return DateTime(
      localCandidate.year,
      localCandidate.month,
      localCandidate.day,
    ).isAfter(DateTime(localEnd.year, localEnd.month, localEnd.day));
  }

  static bool _sameLocalDate(DateTime first, DateTime second) {
    final left = first.toLocal();
    final right = second.toLocal();
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static DateTime _localDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _calendarDayDifference(DateTime start, DateTime end) =>
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
}
