import 'package:equatable/equatable.dart';
import 'behavior_insight_types.dart';
import 'memory_types.dart';

/// Full behavioral profile — a faithful 1:1 port of `S.profile.behavior`
/// plus the top-level streak/combo/XP fields from `S.profile` that the
/// Behavior Engine reads. Persisted via BehaviorProfileModel (Hive).
class BehaviorProfileEntity extends Equatable {
  // ── top-level profile fields the engine reads ──
  final int totalXP;
  final int gems;
  final int failStreak;
  final int streak;
  final int bestStreak;
  final int combo;
  final int bestCombo;
  final String? lastActiveKey; // dayKey of last active day
  final DateTime? firstOpenAt;
  final int totalOpens;

  // ── S.profile.behavior ──
  final Map<int, int> hourlyFails; // hour -> count
  final Map<int, int> hourlyCompletes; // hour -> count
  final int? peakHour;
  final int? worstHour;
  final List<int> skipPattern; // overdue hours from the last scan
  final int consecutiveSkips;
  final int totalSkipped;
  final List<DateTime> openTimestamps;

  final AppPersonalityMode personality;
  final List<PersonalityChange> personalityHistory;

  final bool identityLocked;
  final IdentityProfile? identityProfile;

  final List<ReasonLogEntry> reasonLog;

  final DateTime? lastSmartNotifAt;
  final String? lastSmartNotifKey;
  final bool riskWarnedHigh;

  final DateTime? lastWeeklyMirrorAt;
  final List<WeeklyMirrorSnapshot> weeklyMirrors;

  final double? avgGapMs;
  final DateTime? lastSilenceWarnAt;

  final int cheatFlags;

  /// Rolling history of composed-message text hashes (most recent
  /// last, capped ~60), used by MessageEngine/PredictionEngine to
  /// avoid showing the same exact nudge twice in a row.
  final List<String> recentMessageHashes;

  /// Behavior Memory — periodic checkpoints of past state (XP, streak,
  /// completion rate, persona), most-recent last, capped ~400 entries.
  final List<MemorySnapshot> memorySnapshots;

  /// Notification Intelligence bookkeeping — last delivered time per
  /// trigger id, so background evaluation doesn't spam duplicate local
  /// notifications for the same detected situation on the same day.
  final Map<String, DateTime> lastDeliveredNotifAt;

  const BehaviorProfileEntity({
    this.totalXP = 0,
    this.gems = 0,
    this.failStreak = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.combo = 0,
    this.bestCombo = 0,
    this.lastActiveKey,
    this.firstOpenAt,
    this.totalOpens = 0,
    this.hourlyFails = const {},
    this.hourlyCompletes = const {},
    this.peakHour,
    this.worstHour,
    this.skipPattern = const [],
    this.consecutiveSkips = 0,
    this.totalSkipped = 0,
    this.openTimestamps = const [],
    this.personality = AppPersonalityMode.calm,
    this.personalityHistory = const [],
    this.identityLocked = false,
    this.identityProfile,
    this.reasonLog = const [],
    this.lastSmartNotifAt,
    this.lastSmartNotifKey,
    this.riskWarnedHigh = false,
    this.lastWeeklyMirrorAt,
    this.weeklyMirrors = const [],
    this.avgGapMs,
    this.lastSilenceWarnAt,
    this.cheatFlags = 0,
    this.recentMessageHashes = const [],
    this.memorySnapshots = const [],
    this.lastDeliveredNotifAt = const {},
  });

  BehaviorProfileEntity copyWith({
    int? totalXP,
    int? gems,
    int? failStreak,
    int? streak,
    int? bestStreak,
    int? combo,
    int? bestCombo,
    String? lastActiveKey,
    DateTime? firstOpenAt,
    int? totalOpens,
    Map<int, int>? hourlyFails,
    Map<int, int>? hourlyCompletes,
    int? peakHour,
    int? worstHour,
    List<int>? skipPattern,
    int? consecutiveSkips,
    int? totalSkipped,
    List<DateTime>? openTimestamps,
    AppPersonalityMode? personality,
    List<PersonalityChange>? personalityHistory,
    bool? identityLocked,
    IdentityProfile? identityProfile,
    List<ReasonLogEntry>? reasonLog,
    DateTime? lastSmartNotifAt,
    String? lastSmartNotifKey,
    bool? riskWarnedHigh,
    DateTime? lastWeeklyMirrorAt,
    List<WeeklyMirrorSnapshot>? weeklyMirrors,
    double? avgGapMs,
    DateTime? lastSilenceWarnAt,
    int? cheatFlags,
    List<String>? recentMessageHashes,
    List<MemorySnapshot>? memorySnapshots,
    Map<String, DateTime>? lastDeliveredNotifAt,
  }) {
    return BehaviorProfileEntity(
      totalXP: totalXP ?? this.totalXP,
      gems: gems ?? this.gems,
      failStreak: failStreak ?? this.failStreak,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      combo: combo ?? this.combo,
      bestCombo: bestCombo ?? this.bestCombo,
      lastActiveKey: lastActiveKey ?? this.lastActiveKey,
      firstOpenAt: firstOpenAt ?? this.firstOpenAt,
      totalOpens: totalOpens ?? this.totalOpens,
      hourlyFails: hourlyFails ?? this.hourlyFails,
      hourlyCompletes: hourlyCompletes ?? this.hourlyCompletes,
      peakHour: peakHour ?? this.peakHour,
      worstHour: worstHour ?? this.worstHour,
      skipPattern: skipPattern ?? this.skipPattern,
      consecutiveSkips: consecutiveSkips ?? this.consecutiveSkips,
      totalSkipped: totalSkipped ?? this.totalSkipped,
      openTimestamps: openTimestamps ?? this.openTimestamps,
      personality: personality ?? this.personality,
      personalityHistory: personalityHistory ?? this.personalityHistory,
      identityLocked: identityLocked ?? this.identityLocked,
      identityProfile: identityProfile ?? this.identityProfile,
      reasonLog: reasonLog ?? this.reasonLog,
      lastSmartNotifAt: lastSmartNotifAt ?? this.lastSmartNotifAt,
      lastSmartNotifKey: lastSmartNotifKey ?? this.lastSmartNotifKey,
      riskWarnedHigh: riskWarnedHigh ?? this.riskWarnedHigh,
      lastWeeklyMirrorAt: lastWeeklyMirrorAt ?? this.lastWeeklyMirrorAt,
      weeklyMirrors: weeklyMirrors ?? this.weeklyMirrors,
      avgGapMs: avgGapMs ?? this.avgGapMs,
      lastSilenceWarnAt: lastSilenceWarnAt ?? this.lastSilenceWarnAt,
      cheatFlags: cheatFlags ?? this.cheatFlags,
      recentMessageHashes: recentMessageHashes ?? this.recentMessageHashes,
      memorySnapshots: memorySnapshots ?? this.memorySnapshots,
      lastDeliveredNotifAt: lastDeliveredNotifAt ?? this.lastDeliveredNotifAt,
    );
  }

  @override
  List<Object?> get props => [
        totalXP,
        gems,
        failStreak,
        streak,
        bestStreak,
        combo,
        bestCombo,
        lastActiveKey,
        firstOpenAt,
        totalOpens,
        hourlyFails,
        hourlyCompletes,
        peakHour,
        worstHour,
        skipPattern,
        consecutiveSkips,
        totalSkipped,
        openTimestamps,
        personality,
        personalityHistory,
        identityLocked,
        identityProfile,
        reasonLog,
        lastSmartNotifAt,
        lastSmartNotifKey,
        riskWarnedHigh,
        lastWeeklyMirrorAt,
        weeklyMirrors,
        avgGapMs,
        lastSilenceWarnAt,
        cheatFlags,
        recentMessageHashes,
        memorySnapshots,
        lastDeliveredNotifAt,
      ];
}

class PersonalityChange extends Equatable {
  final AppPersonalityMode mode;
  final DateTime at;
  const PersonalityChange({required this.mode, required this.at});
  @override
  List<Object?> get props => [mode, at];
}

class ReasonLogEntry extends Equatable {
  final String day; // dayKey
  final HiddenReasonType type;
  final String text;
  final String icon;
  final DateTime at;
  const ReasonLogEntry({
    required this.day,
    required this.type,
    required this.text,
    required this.icon,
    required this.at,
  });
  @override
  List<Object?> get props => [day, type, text, icon, at];
}

class WeeklyMirrorSnapshot extends Equatable {
  final DateTime at;
  final List<PatternInsight> lines;
  const WeeklyMirrorSnapshot({required this.at, required this.lines});
  @override
  List<Object?> get props => [at, lines];
}
