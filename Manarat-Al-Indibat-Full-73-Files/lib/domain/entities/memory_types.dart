import "package:equatable/equatable.dart";
import "behavior_insight_types.dart";

/// One periodic checkpoint of the user's behavioral state — recorded at
/// most once per calendar day by [BehaviorMemoryEngine], capped to the
/// last ~400 days (~13 months) of history. This is what lets the app
/// answer "كيف كنت قبل شهر / قبل ستة أشهر / قبل سنة؟" with an actual
/// past state instead of re-deriving it (XP and persona in particular
/// can't be reconstructed purely from day logs).
class MemorySnapshot extends Equatable {
  final String dayKey; // yyyy-MM-dd
  final DateTime date;
  final int totalXP;
  final int streak;
  final int bestStreak;
  final double completionRate7d; // 0-100, trailing 7-day window at the time
  final AppPersonalityMode personality;

  const MemorySnapshot({
    required this.dayKey,
    required this.date,
    required this.totalXP,
    required this.streak,
    required this.bestStreak,
    required this.completionRate7d,
    required this.personality,
  });

  @override
  List<Object?> get props =>
      [dayKey, date, totalXP, streak, bestStreak, completionRate7d, personality];
}

enum MemoryPeriod { oneMonth, sixMonths, oneYear }

extension MemoryPeriodX on MemoryPeriod {
  int get days => switch (this) {
        MemoryPeriod.oneMonth => 30,
        MemoryPeriod.sixMonths => 182,
        MemoryPeriod.oneYear => 365,
      };

  String get label => switch (this) {
        MemoryPeriod.oneMonth => "قبل شهر",
        MemoryPeriod.sixMonths => "قبل ستة أشهر",
        MemoryPeriod.oneYear => "قبل سنة",
      };
}

enum MemoryTrend { improved, declined, stable }

/// Result of comparing the user's current state against a past
/// [MemorySnapshot] for a given [MemoryPeriod].
class MemoryComparison extends Equatable {
  final MemoryPeriod period;
  final bool hasData;
  final MemorySnapshot? past;
  final double? completionDelta; // current - past, percentage points
  final int? xpDelta;
  final int? streakDelta;
  final bool personaChanged;
  final MemoryTrend trend;
  final String icon;
  final String narrative;

  const MemoryComparison({
    required this.period,
    required this.hasData,
    this.past,
    this.completionDelta,
    this.xpDelta,
    this.streakDelta,
    this.personaChanged = false,
    this.trend = MemoryTrend.stable,
    required this.icon,
    required this.narrative,
  });

  @override
  List<Object?> get props => [
        period,
        hasData,
        past,
        completionDelta,
        xpDelta,
        streakDelta,
        personaChanged,
        trend,
        icon,
        narrative,
      ];
}

/// Full "Behavior Memory" report — one comparison per period, always in
/// month → 6-months → year order.
class MemoryReport extends Equatable {
  final List<MemoryComparison> comparisons;
  const MemoryReport(this.comparisons);

  @override
  List<Object?> get props => [comparisons];
}
