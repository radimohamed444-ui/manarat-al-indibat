import "../entities/behavior_profile_entity.dart";
import "../entities/memory_types.dart";
import "../entities/message_types.dart";
import "../repositories/schedule_repository.dart";
import "../repositories/behavior_profile_repository.dart";
import "../../core/utils/day_key.dart";
import "message_engine.dart";

/// ── Behavior Memory ──
///
/// Ported from the spec's "Behavior Memory" section: the app should
/// know how the user was a month ago, six months ago, a year ago, and
/// compare that to now. `computeStats(n)` alone can answer this for
/// completion-rate trends, but XP and the app's adaptive "persona"
/// mood at a past point in time can't be reconstructed after the fact
/// — they have to have been recorded when they happened. So this
/// engine's job has two halves:
///
/// 1. [recordDailySnapshotIfNeeded] — called once per day (from the
///    dashboard on open and from the background task) to append a
///    lightweight [MemorySnapshot] checkpoint to the profile.
/// 2. [compareToDaysAgo] / [getFullMemoryReport] — find the nearest
///    past checkpoint to a target date and compare it against today.
///
/// 100% local, zero network — same as the rest of the intelligence
/// stack.
class BehaviorMemoryEngine {
  final ScheduleRepository scheduleRepository;
  final BehaviorProfileRepository profileRepository;
  final MessageEngine messageEngine;

  /// How many days of tolerance around the exact target date count as
  /// "close enough" when looking for a past checkpoint. Snapshots are
  /// recorded daily so this mostly matters for the very first weeks
  /// after the feature ships, when history is sparse.
  static const int _toleranceDays = 6;

  /// Snapshots are capped so the profile record doesn't grow forever —
  /// ~400 days is well over a year of daily checkpoints.
  static const int _maxSnapshots = 400;

  BehaviorMemoryEngine({
    required this.scheduleRepository,
    required this.profileRepository,
    MessageEngine? messageEngine,
  }) : messageEngine = messageEngine ?? MessageEngine();

  Future<double> _trailingCompletionRate() async {
    final days = await scheduleRepository.computeStats(7);
    final withData = days.getOrElse(() => []).where((d) => d.total > 0).toList();
    if (withData.isEmpty) return 0;
    final avg = withData.map((d) => d.rate).reduce((a, b) => a + b) / withData.length;
    return (avg * 100).clamp(0, 100);
  }

  /// Appends today's checkpoint if one hasn't been recorded yet today.
  /// Safe to call as often as the app likes (dashboard open, app
  /// resume, background task) — it's a no-op after the first call each
  /// day. Returns the (possibly unchanged) profile.
  Future<BehaviorProfileEntity> recordDailySnapshotIfNeeded() async {
    final profile = await profileRepository.get();
    final today = dayKey();
    if (profile.memorySnapshots.isNotEmpty && profile.memorySnapshots.last.dayKey == today) {
      return profile;
    }

    final snapshot = MemorySnapshot(
      dayKey: today,
      date: DateTime.now(),
      totalXP: profile.totalXP,
      streak: profile.streak,
      bestStreak: profile.bestStreak,
      completionRate7d: await _trailingCompletionRate(),
      personality: profile.personality,
    );

    final updated = [...profile.memorySnapshots, snapshot];
    final capped =
        updated.length > _maxSnapshots ? updated.sublist(updated.length - _maxSnapshots) : updated;
    final newProfile = profile.copyWith(memorySnapshots: capped);
    await profileRepository.save(newProfile);
    return newProfile;
  }

  MemorySnapshot? _nearestSnapshot(List<MemorySnapshot> snapshots, DateTime target) {
    if (snapshots.isEmpty) return null;
    MemorySnapshot? best;
    Duration? bestDiff;
    for (final s in snapshots) {
      final diff = s.date.difference(target).abs();
      if (bestDiff == null || diff < bestDiff) {
        best = s;
        bestDiff = diff;
      }
    }
    if (best == null || bestDiff == null) return null;
    if (bestDiff.inDays > _toleranceDays &&
        best.date.isAfter(target.subtract(Duration(days: _toleranceDays)))) {
      // The nearest thing we have is still more recent than the
      // window we're looking for — not enough history yet.
      return null;
    }
    return best;
  }

  /// Compares now vs. [period] ago. Composes a varied Arabic narrative
  /// through [MessageEngine] and persists the updated recent-message
  /// history + a fresh snapshot in the same call (so calling this from
  /// the dashboard also keeps memory bookkeeping current).
  Future<MemoryComparison> compareToDaysAgo(MemoryPeriod period) async {
    final profile = await recordDailySnapshotIfNeeded();
    final target = DateTime.now().subtract(Duration(days: period.days));
    final past = _nearestSnapshot(profile.memorySnapshots, target);

    if (past == null) {
      return MemoryComparison(
        period: period,
        hasData: false,
        icon: "📭",
        narrative: "لا تتوفر بيانات كافية لمقارنة ${period.label} بعد — "
            "استمر في استخدام التطبيق وسيبني لك سجلاً كاملاً قريباً.",
      );
    }

    final currentRate = await _trailingCompletionRate();
    final completionDelta = currentRate - past.completionRate7d;
    final xpDelta = profile.totalXP - past.totalXP;
    final streakDelta = profile.streak - past.streak;
    final personaChanged = profile.personality != past.personality;

    MessageCategory category;
    MemoryTrend trend;
    if (completionDelta > 8) {
      category = MessageCategory.memoryImproved;
      trend = MemoryTrend.improved;
    } else if (completionDelta < -8) {
      category = MessageCategory.memoryDeclined;
      trend = MemoryTrend.declined;
    } else if (xpDelta > 0 && streakDelta >= 0) {
      category = MessageCategory.memoryImproved;
      trend = MemoryTrend.improved;
    } else {
      category = MessageCategory.memoryStable;
      trend = MemoryTrend.stable;
    }

    final msg = messageEngine.compose(
      category,
      params: {
        "period": period.label,
        "delta": "${completionDelta.abs().round()}%",
      },
      recentHashes: profile.recentMessageHashes,
    );
    final updatedHashes = [...profile.recentMessageHashes, messageEngine.hashOf(msg)];
    await profileRepository.save(profile.copyWith(
      recentMessageHashes:
          updatedHashes.length > 60 ? updatedHashes.sublist(updatedHashes.length - 60) : updatedHashes,
    ));

    return MemoryComparison(
      period: period,
      hasData: true,
      past: past,
      completionDelta: completionDelta,
      xpDelta: xpDelta,
      streakDelta: streakDelta,
      personaChanged: personaChanged,
      trend: trend,
      icon: msg.icon,
      narrative: msg.text,
    );
  }

  /// The full month / 6-months / year report, in that order — the
  /// direct answer to "كيف كان قبل شهر؟ قبل ستة أشهر؟ قبل سنة؟".
  Future<MemoryReport> getFullMemoryReport() async {
    final comparisons = <MemoryComparison>[];
    for (final period in MemoryPeriod.values) {
      comparisons.add(await compareToDaysAgo(period));
    }
    return MemoryReport(comparisons);
  }
}
