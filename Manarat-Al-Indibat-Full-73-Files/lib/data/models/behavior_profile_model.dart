import "package:hive/hive.dart";

part "behavior_profile_model.g.dart";

/// Single-record Hive model persisting the entire behavioral profile —
/// mirrors `S.profile` + `S.profile.behavior` from the original. Stored
/// as one object under a fixed key ("profile") since there's only ever
/// one profile per device.
@HiveType(typeId: 6)
class BehaviorProfileModel {
  @HiveField(0)
  int totalXP;
  @HiveField(1)
  int gems;
  @HiveField(2)
  int failStreak;
  @HiveField(3)
  int streak;
  @HiveField(4)
  int bestStreak;
  @HiveField(5)
  int combo;
  @HiveField(6)
  int bestCombo;
  @HiveField(7)
  String? lastActiveKey;
  @HiveField(8)
  DateTime? firstOpenAt;
  @HiveField(9)
  int totalOpens;
  @HiveField(10)
  Map<int, int> hourlyFails;
  @HiveField(11)
  Map<int, int> hourlyCompletes;
  @HiveField(12)
  int? peakHour;
  @HiveField(13)
  int? worstHour;
  @HiveField(14)
  List<int> skipPattern;
  @HiveField(15)
  int consecutiveSkips;
  @HiveField(16)
  int totalSkipped;
  @HiveField(17)
  List<DateTime> openTimestamps;
  @HiveField(18)
  int personalityIndex;
  @HiveField(19)
  bool identityLocked;
  @HiveField(20)
  DateTime? lastSmartNotifAt;
  @HiveField(21)
  String? lastSmartNotifKey;
  @HiveField(22)
  bool riskWarnedHigh;
  @HiveField(23)
  DateTime? lastWeeklyMirrorAt;
  @HiveField(24)
  double? avgGapMs;
  @HiveField(25)
  DateTime? lastSilenceWarnAt;
  @HiveField(26)
  int cheatFlags;
  // Identity profile (flattened, nullable together)
  @HiveField(27)
  String? idPersona;
  @HiveField(28)
  int? idBestHour;
  @HiveField(29)
  int? idWorstHour;
  @HiveField(30)
  String? idWeaknessType;
  @HiveField(31)
  bool? idResilientAfterFail;
  @HiveField(32)
  DateTime? idLockedAt;
  // reasonLog serialized as flat parallel lists (kept simple, no nested adapter)
  @HiveField(33)
  List<String> reasonDays;
  @HiveField(34)
  List<String> reasonTypes;
  @HiveField(35)
  List<String> reasonTexts;
  @HiveField(36)
  List<String> reasonIcons;
  @HiveField(37)
  List<DateTime> reasonAts;
  @HiveField(38)
  List<String> recentMessageHashes;
  // Behavior Memory snapshots, flattened as parallel lists (same
  // convention as reasonLog above — no build_runner access here).
  @HiveField(39)
  List<String> memDayKeys;
  @HiveField(40)
  List<DateTime> memDates;
  @HiveField(41)
  List<int> memTotalXP;
  @HiveField(42)
  List<int> memStreak;
  @HiveField(43)
  List<int> memBestStreak;
  @HiveField(44)
  List<double> memCompletionRate;
  @HiveField(45)
  List<int> memPersonalityIndex;
  // Notification Intelligence dedupe bookkeeping.
  @HiveField(46)
  Map<String, DateTime> lastDeliveredNotifAt;

  BehaviorProfileModel({
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
    Map<int, int>? hourlyFails,
    Map<int, int>? hourlyCompletes,
    this.peakHour,
    this.worstHour,
    List<int>? skipPattern,
    this.consecutiveSkips = 0,
    this.totalSkipped = 0,
    List<DateTime>? openTimestamps,
    this.personalityIndex = 0,
    this.identityLocked = false,
    this.lastSmartNotifAt,
    this.lastSmartNotifKey,
    this.riskWarnedHigh = false,
    this.lastWeeklyMirrorAt,
    this.avgGapMs,
    this.lastSilenceWarnAt,
    this.cheatFlags = 0,
    this.idPersona,
    this.idBestHour,
    this.idWorstHour,
    this.idWeaknessType,
    this.idResilientAfterFail,
    this.idLockedAt,
    List<String>? reasonDays,
    List<String>? reasonTypes,
    List<String>? reasonTexts,
    List<String>? reasonIcons,
    List<DateTime>? reasonAts,
    List<String>? recentMessageHashes,
    List<String>? memDayKeys,
    List<DateTime>? memDates,
    List<int>? memTotalXP,
    List<int>? memStreak,
    List<int>? memBestStreak,
    List<double>? memCompletionRate,
    List<int>? memPersonalityIndex,
    Map<String, DateTime>? lastDeliveredNotifAt,
  })  : hourlyFails = hourlyFails ?? {},
        hourlyCompletes = hourlyCompletes ?? {},
        skipPattern = skipPattern ?? [],
        openTimestamps = openTimestamps ?? [],
        reasonDays = reasonDays ?? [],
        reasonTypes = reasonTypes ?? [],
        reasonTexts = reasonTexts ?? [],
        reasonIcons = reasonIcons ?? [],
        reasonAts = reasonAts ?? [],
        recentMessageHashes = recentMessageHashes ?? [],
        memDayKeys = memDayKeys ?? [],
        memDates = memDates ?? [],
        memTotalXP = memTotalXP ?? [],
        memStreak = memStreak ?? [],
        memBestStreak = memBestStreak ?? [],
        memCompletionRate = memCompletionRate ?? [],
        memPersonalityIndex = memPersonalityIndex ?? [],
        lastDeliveredNotifAt = lastDeliveredNotifAt ?? {};
}
