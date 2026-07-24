part of "behavior_profile_model.dart";

class BehaviorProfileModelAdapter extends TypeAdapter<BehaviorProfileModel> {
  @override
  final int typeId = 6;

  @override
  BehaviorProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BehaviorProfileModel(
      totalXP: fields[0] as int? ?? 0,
      gems: fields[1] as int? ?? 0,
      failStreak: fields[2] as int? ?? 0,
      streak: fields[3] as int? ?? 0,
      bestStreak: fields[4] as int? ?? 0,
      combo: fields[5] as int? ?? 0,
      bestCombo: fields[6] as int? ?? 0,
      lastActiveKey: fields[7] as String?,
      firstOpenAt: fields[8] as DateTime?,
      totalOpens: fields[9] as int? ?? 0,
      hourlyFails: (fields[10] as Map?)?.cast<int, int>() ?? {},
      hourlyCompletes: (fields[11] as Map?)?.cast<int, int>() ?? {},
      peakHour: fields[12] as int?,
      worstHour: fields[13] as int?,
      skipPattern: (fields[14] as List?)?.cast<int>() ?? [],
      consecutiveSkips: fields[15] as int? ?? 0,
      totalSkipped: fields[16] as int? ?? 0,
      openTimestamps: (fields[17] as List?)?.cast<DateTime>() ?? [],
      personalityIndex: fields[18] as int? ?? 0,
      identityLocked: fields[19] as bool? ?? false,
      lastSmartNotifAt: fields[20] as DateTime?,
      lastSmartNotifKey: fields[21] as String?,
      riskWarnedHigh: fields[22] as bool? ?? false,
      lastWeeklyMirrorAt: fields[23] as DateTime?,
      avgGapMs: fields[24] as double?,
      lastSilenceWarnAt: fields[25] as DateTime?,
      cheatFlags: fields[26] as int? ?? 0,
      idPersona: fields[27] as String?,
      idBestHour: fields[28] as int?,
      idWorstHour: fields[29] as int?,
      idWeaknessType: fields[30] as String?,
      idResilientAfterFail: fields[31] as bool?,
      idLockedAt: fields[32] as DateTime?,
      reasonDays: (fields[33] as List?)?.cast<String>() ?? [],
      reasonTypes: (fields[34] as List?)?.cast<String>() ?? [],
      reasonTexts: (fields[35] as List?)?.cast<String>() ?? [],
      reasonIcons: (fields[36] as List?)?.cast<String>() ?? [],
      reasonAts: (fields[37] as List?)?.cast<DateTime>() ?? [],
      recentMessageHashes: (fields[38] as List?)?.cast<String>() ?? [],
      memDayKeys: (fields[39] as List?)?.cast<String>() ?? [],
      memDates: (fields[40] as List?)?.cast<DateTime>() ?? [],
      memTotalXP: (fields[41] as List?)?.cast<int>() ?? [],
      memStreak: (fields[42] as List?)?.cast<int>() ?? [],
      memBestStreak: (fields[43] as List?)?.cast<int>() ?? [],
      memCompletionRate: (fields[44] as List?)?.cast<double>() ?? [],
      memPersonalityIndex: (fields[45] as List?)?.cast<int>() ?? [],
      lastDeliveredNotifAt: (fields[46] as Map?)?.cast<String, DateTime>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, BehaviorProfileModel obj) {
    writer
      ..writeByte(47)
      ..writeByte(0)
      ..write(obj.totalXP)
      ..writeByte(1)
      ..write(obj.gems)
      ..writeByte(2)
      ..write(obj.failStreak)
      ..writeByte(3)
      ..write(obj.streak)
      ..writeByte(4)
      ..write(obj.bestStreak)
      ..writeByte(5)
      ..write(obj.combo)
      ..writeByte(6)
      ..write(obj.bestCombo)
      ..writeByte(7)
      ..write(obj.lastActiveKey)
      ..writeByte(8)
      ..write(obj.firstOpenAt)
      ..writeByte(9)
      ..write(obj.totalOpens)
      ..writeByte(10)
      ..write(obj.hourlyFails)
      ..writeByte(11)
      ..write(obj.hourlyCompletes)
      ..writeByte(12)
      ..write(obj.peakHour)
      ..writeByte(13)
      ..write(obj.worstHour)
      ..writeByte(14)
      ..write(obj.skipPattern)
      ..writeByte(15)
      ..write(obj.consecutiveSkips)
      ..writeByte(16)
      ..write(obj.totalSkipped)
      ..writeByte(17)
      ..write(obj.openTimestamps)
      ..writeByte(18)
      ..write(obj.personalityIndex)
      ..writeByte(19)
      ..write(obj.identityLocked)
      ..writeByte(20)
      ..write(obj.lastSmartNotifAt)
      ..writeByte(21)
      ..write(obj.lastSmartNotifKey)
      ..writeByte(22)
      ..write(obj.riskWarnedHigh)
      ..writeByte(23)
      ..write(obj.lastWeeklyMirrorAt)
      ..writeByte(24)
      ..write(obj.avgGapMs)
      ..writeByte(25)
      ..write(obj.lastSilenceWarnAt)
      ..writeByte(26)
      ..write(obj.cheatFlags)
      ..writeByte(27)
      ..write(obj.idPersona)
      ..writeByte(28)
      ..write(obj.idBestHour)
      ..writeByte(29)
      ..write(obj.idWorstHour)
      ..writeByte(30)
      ..write(obj.idWeaknessType)
      ..writeByte(31)
      ..write(obj.idResilientAfterFail)
      ..writeByte(32)
      ..write(obj.idLockedAt)
      ..writeByte(33)
      ..write(obj.reasonDays)
      ..writeByte(34)
      ..write(obj.reasonTypes)
      ..writeByte(35)
      ..write(obj.reasonTexts)
      ..writeByte(36)
      ..write(obj.reasonIcons)
      ..writeByte(37)
      ..write(obj.reasonAts)
      ..writeByte(38)
      ..write(obj.recentMessageHashes)
      ..writeByte(39)
      ..write(obj.memDayKeys)
      ..writeByte(40)
      ..write(obj.memDates)
      ..writeByte(41)
      ..write(obj.memTotalXP)
      ..writeByte(42)
      ..write(obj.memStreak)
      ..writeByte(43)
      ..write(obj.memBestStreak)
      ..writeByte(44)
      ..write(obj.memCompletionRate)
      ..writeByte(45)
      ..write(obj.memPersonalityIndex)
      ..writeByte(46)
      ..write(obj.lastDeliveredNotifAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BehaviorProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
