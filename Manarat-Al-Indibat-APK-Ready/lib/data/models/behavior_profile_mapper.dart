import "behavior_profile_model.dart";
import "../../domain/entities/behavior_profile_entity.dart";
import "../../domain/entities/behavior_insight_types.dart";
import "../../domain/entities/memory_types.dart";

extension BehaviorProfileModelMapper on BehaviorProfileModel {
  BehaviorProfileEntity toEntity() {
    IdentityProfile? identity;
    if (idPersona != null && idLockedAt != null) {
      identity = IdentityProfile(
        persona: idPersona!,
        bestHour: idBestHour,
        worstHour: idWorstHour,
        weaknessType: idWeaknessType ?? "",
        resilientAfterFail: idResilientAfterFail ?? false,
        lockedAt: idLockedAt!,
      );
    }
    final reasonLog = <ReasonLogEntry>[];
    for (int i = 0; i < reasonDays.length; i++) {
      reasonLog.add(ReasonLogEntry(
        day: reasonDays[i],
        type: HiddenReasonType.values.firstWhere(
          (t) => t.name == reasonTypes[i],
          orElse: () => HiddenReasonType.procrastination,
        ),
        text: reasonTexts[i],
        icon: reasonIcons[i],
        at: reasonAts[i],
      ));
    }
    final memorySnapshots = <MemorySnapshot>[];
    for (int i = 0; i < memDayKeys.length; i++) {
      memorySnapshots.add(MemorySnapshot(
        dayKey: memDayKeys[i],
        date: memDates[i],
        totalXP: memTotalXP[i],
        streak: memStreak[i],
        bestStreak: memBestStreak[i],
        completionRate7d: memCompletionRate[i],
        personality: AppPersonalityMode.values[memPersonalityIndex[i]],
      ));
    }
    return BehaviorProfileEntity(
      totalXP: totalXP,
      gems: gems,
      failStreak: failStreak,
      streak: streak,
      bestStreak: bestStreak,
      combo: combo,
      bestCombo: bestCombo,
      lastActiveKey: lastActiveKey,
      firstOpenAt: firstOpenAt,
      totalOpens: totalOpens,
      hourlyFails: hourlyFails,
      hourlyCompletes: hourlyCompletes,
      peakHour: peakHour,
      worstHour: worstHour,
      skipPattern: skipPattern,
      consecutiveSkips: consecutiveSkips,
      totalSkipped: totalSkipped,
      openTimestamps: openTimestamps,
      personality: AppPersonalityMode.values[personalityIndex],
      identityLocked: identityLocked,
      identityProfile: identity,
      reasonLog: reasonLog,
      lastSmartNotifAt: lastSmartNotifAt,
      lastSmartNotifKey: lastSmartNotifKey,
      riskWarnedHigh: riskWarnedHigh,
      lastWeeklyMirrorAt: lastWeeklyMirrorAt,
      avgGapMs: avgGapMs,
      lastSilenceWarnAt: lastSilenceWarnAt,
      cheatFlags: cheatFlags,
      recentMessageHashes: recentMessageHashes,
      memorySnapshots: memorySnapshots,
      lastDeliveredNotifAt: lastDeliveredNotifAt,
    );
  }
}

extension BehaviorProfileEntityMapper on BehaviorProfileEntity {
  BehaviorProfileModel toModel() {
    return BehaviorProfileModel(
      totalXP: totalXP,
      gems: gems,
      failStreak: failStreak,
      streak: streak,
      bestStreak: bestStreak,
      combo: combo,
      bestCombo: bestCombo,
      lastActiveKey: lastActiveKey,
      firstOpenAt: firstOpenAt,
      totalOpens: totalOpens,
      hourlyFails: hourlyFails,
      hourlyCompletes: hourlyCompletes,
      peakHour: peakHour,
      worstHour: worstHour,
      skipPattern: skipPattern,
      consecutiveSkips: consecutiveSkips,
      totalSkipped: totalSkipped,
      openTimestamps: openTimestamps,
      personalityIndex: personality.index,
      identityLocked: identityLocked,
      lastSmartNotifAt: lastSmartNotifAt,
      lastSmartNotifKey: lastSmartNotifKey,
      riskWarnedHigh: riskWarnedHigh,
      lastWeeklyMirrorAt: lastWeeklyMirrorAt,
      avgGapMs: avgGapMs,
      lastSilenceWarnAt: lastSilenceWarnAt,
      cheatFlags: cheatFlags,
      idPersona: identityProfile?.persona,
      idBestHour: identityProfile?.bestHour,
      idWorstHour: identityProfile?.worstHour,
      idWeaknessType: identityProfile?.weaknessType,
      idResilientAfterFail: identityProfile?.resilientAfterFail,
      idLockedAt: identityProfile?.lockedAt,
      reasonDays: reasonLog.map((r) => r.day).toList(),
      reasonTypes: reasonLog.map((r) => r.type.name).toList(),
      reasonTexts: reasonLog.map((r) => r.text).toList(),
      reasonIcons: reasonLog.map((r) => r.icon).toList(),
      reasonAts: reasonLog.map((r) => r.at).toList(),
      recentMessageHashes: recentMessageHashes,
      memDayKeys: memorySnapshots.map((m) => m.dayKey).toList(),
      memDates: memorySnapshots.map((m) => m.date).toList(),
      memTotalXP: memorySnapshots.map((m) => m.totalXP).toList(),
      memStreak: memorySnapshots.map((m) => m.streak).toList(),
      memBestStreak: memorySnapshots.map((m) => m.bestStreak).toList(),
      memCompletionRate: memorySnapshots.map((m) => m.completionRate7d).toList(),
      memPersonalityIndex: memorySnapshots.map((m) => m.personality.index).toList(),
      lastDeliveredNotifAt: lastDeliveredNotifAt,
    );
  }
}
