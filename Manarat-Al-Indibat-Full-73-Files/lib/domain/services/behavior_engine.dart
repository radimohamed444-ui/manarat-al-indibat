import "dart:math";
import "../entities/scheduled_task_entity.dart";
import "../entities/task_log_entry.dart";
import "../entities/day_stat.dart";
import "../entities/behavior_profile_entity.dart";
import "../entities/behavior_insight_types.dart";
import "../entities/habit_entity.dart";
import "../entities/message_types.dart";
import "../repositories/schedule_repository.dart";
import "../repositories/behavior_profile_repository.dart";
import "../repositories/habit_repository.dart";
import "../../core/utils/day_key.dart";
import "message_engine.dart";

/// The local, fully offline rule-based Behavior Engine — a faithful,
/// function-by-function port of the "DEEP BEHAVIORAL INTELLIGENCE CORE
/// v4" section of the original HTML app (analyzeBehavior,
/// deepPatternScan, computePersonaModel, computeRiskAssessment,
/// generateSmartNotification, interpretHiddenReason,
/// computeAppPersonality, generateWeeklyMirrorReport,
/// maybeLockIdentity, checkSilenceAnomaly). No network calls, no
/// external AI — every score is computed from data already on device.
class BehaviorEngine {
  final ScheduleRepository scheduleRepository;
  final BehaviorProfileRepository profileRepository;
  final HabitRepository habitRepository;
  final MessageEngine messageEngine;

  BehaviorEngine({
    required this.scheduleRepository,
    required this.profileRepository,
    required this.habitRepository,
    MessageEngine? messageEngine,
  }) : messageEngine = messageEngine ?? MessageEngine();

  /// Composes text via [messageEngine], dodging the profile's recent
  /// message history, and appends the new hash to that history so the
  /// next nudge (of any kind) doesn't immediately repeat it. Callers
  /// that already have `profile` loaded should use the returned
  /// updated profile instead of re-fetching.
  Future<(GeneratedMessage, BehaviorProfileEntity)> _composeTracked(
    BehaviorProfileEntity profile,
    MessageCategory category,
    Map<String, String> params,
  ) async {
    final msg = messageEngine.compose(
      category,
      params: params,
      recentHashes: profile.recentMessageHashes,
    );
    final updatedHashes = [...profile.recentMessageHashes, messageEngine.hashOf(msg)];
    final updatedProfile = profile.copyWith(
      recentMessageHashes:
          updatedHashes.length > 60 ? updatedHashes.sublist(updatedHashes.length - 60) : updatedHashes,
    );
    return (msg, updatedProfile);
  }

  /// True when today's scheduled task count is well above the recent
  /// (last 7 active days) average — spec section 3's "زاد الضغط"
  /// example. Needs at least 4 days of history to avoid false
  /// positives on a barely-used app.
  Future<bool> _isScheduleOverloaded(int todayTotal) async {
    if (todayTotal < 6) return false;
    final days = await computeStats(14);
    final withData = days.where((d) => d.total > 0).toList();
    if (withData.length < 4) return false;
    final avg = withData.map((d) => d.total).reduce((a, b) => a + b) / withData.length;
    return todayTotal > avg * 1.4 && todayTotal - avg >= 3;
  }

  // ── analyzeBehavior() ──
  /// Scans today's schedule against the current time: how many tasks
  /// are overdue-and-still-pending right now, today's completion rate,
  /// and which hours accumulate fails/completes historically. Also
  /// updates & persists worstHour/peakHour, mirroring the original's
  /// side-effecting analyzeBehavior().
  Future<AnalyzeResult> analyzeBehavior() async {
    final now = DateTime.now();
    final todayKey = dayKey(now);
    final schedResult = await scheduleRepository.getScheduleForDay(jsWeekday(now));
    final sched = schedResult.getOrElse(() => []);
    final logResult = await scheduleRepository.getDayLog(todayKey);
    final log = logResult.getOrElse(() => {});
    final nowMin = now.hour * 60 + now.minute;

    int skippedNow = 0;
    final overdueHours = <int>[];
    int done = 0, failed = 0;
    for (final t in sched) {
      final ts = log[t.id] ?? const TaskLogEntry();
      final taskMin = t.hour * 60;
      if (ts.status == DayTaskStatus.pending && nowMin > taskMin + 15) {
        skippedNow++;
        overdueHours.add(t.hour);
      }
      if (ts.status == DayTaskStatus.done) done++;
      if (ts.status == DayTaskStatus.failed) failed++;
    }
    final total = sched.length;
    final rateNow = total > 0 ? done / total : 0.0;

    // Update hourly fail/complete maps + peak/worst hour (persisted).
    var profile = await profileRepository.get();
    final hourlyFails = Map<int, int>.from(profile.hourlyFails);
    final hourlyCompletes = Map<int, int>.from(profile.hourlyCompletes);
    for (final t in sched) {
      final ts = log[t.id] ?? const TaskLogEntry();
      if (ts.status == DayTaskStatus.failed) {
        hourlyFails[t.hour] = (hourlyFails[t.hour] ?? 0) + 1;
      }
      if (ts.status == DayTaskStatus.done && ts.completedAt != null) {
        final h = ts.completedAt!.hour;
        hourlyCompletes[h] = (hourlyCompletes[h] ?? 0) + 1;
      }
    }
    int? worstHour = profile.worstHour;
    if (hourlyFails.isNotEmpty) {
      final sorted = hourlyFails.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      worstHour = sorted.first.key;
    }
    int? peakHour = profile.peakHour;
    if (hourlyCompletes.isNotEmpty) {
      final sorted = hourlyCompletes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      peakHour = sorted.first.key;
    }
    profile = profile.copyWith(
      hourlyFails: hourlyFails,
      hourlyCompletes: hourlyCompletes,
      worstHour: worstHour,
      peakHour: peakHour,
      consecutiveSkips: skippedNow,
      skipPattern: skippedNow > 0 ? overdueHours : profile.skipPattern,
    );
    await profileRepository.save(profile);

    return AnalyzeResult(
      skippedNow: skippedNow,
      rateNow: rateNow,
      done: done,
      failed: failed,
      total: total,
      overdueHours: overdueHours,
    );
  }

  // ── computeStats(n) passthrough, exposed for callers that need raw stats ──
  Future<List<DayStat>> computeStats(int n) async {
    final result = await scheduleRepository.computeStats(n);
    return result.getOrElse(() => []);
  }

  // ── deepPatternScan() ──
  Future<List<PatternInsight>> deepPatternScan() async {
    final allDays = await computeStats(28);
    final days = allDays.where((d) => d.total > 0).toList();
    final patterns = <PatternInsight>[];
    if (days.length < 4) return patterns;

    // day-of-week averages
    final byDow = List.generate(7, (_) => <double>[]);
    for (final d in days) {
      byDow[jsWeekday(d.date)].add(d.rate);
    }
    final dowAvg = byDow
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length))
        .toList();
    if (dowAvg.length >= 4) {
      final overallAvg = dowAvg.map((e) => e.value).reduce((a, b) => a + b) / dowAvg.length;
      final worstDow = dowAvg.reduce((a, b) => b.value < a.value ? b : a);
      if (worstDow.value < overallAvg * 0.6 && overallAvg > 0.15) {
        patterns.add(PatternInsight(
          icon: "📉",
          text:
              "أداؤك يوم ${dayNamesAr[worstDow.key]} ينخفض بشكل واضح عن باقي الأسبوع (${(worstDow.value * 100).round()}% مقابل متوسط ${(overallAvg * 100).round()}%).",
        ));
      }
      final bestDow = dowAvg.reduce((a, b) => b.value > a.value ? b : a);
      if (bestDow.value > overallAvg * 1.3 && bestDow.value > 0.5) {
        patterns.add(PatternInsight(
          icon: "⭐",
          text: "يوم ${dayNamesAr[bestDow.key]} هو أقوى أيامك من حيث الالتزام (${(bestDow.value * 100).round()}%).",
        ));
      }
    }

    // success-streak break pattern
    final successStreaks = <int>[];
    int cur = 0;
    for (final d in days) {
      if (d.rate >= 0.7) {
        cur++;
      } else {
        if (cur >= 2) successStreaks.add(cur);
        cur = 0;
      }
    }
    if (cur >= 2) successStreaks.add(cur);
    if (successStreaks.length >= 2) {
      final avgBreak = (successStreaks.reduce((a, b) => a + b) / successStreaks.length).round();
      patterns.add(PatternInsight(
        icon: "🔁",
        text: "غالباً ينخفض التزامك بعد $avgBreak أيام متتالية من النجاح — كن منتبهاً عند الوصول لهذه النقطة.",
      ));
    }

    final profile = await profileRepository.get();
    if (profile.worstHour != null) {
      final failsAtHour = profile.hourlyFails[profile.worstHour] ?? 0;
      if (failsAtHour >= 3) {
        patterns.add(PatternInsight(
          icon: "⏰",
          text: "الساعة ${formatHour(profile.worstHour!)} هي أكثر وقت تفشل فيه بتنفيذ مهامك ($failsAtHour مرة فشل مسجلة).",
        ));
      }
    }
    if (profile.peakHour != null) {
      final doneAtHour = profile.hourlyCompletes[profile.peakHour] ?? 0;
      if (doneAtHour >= 3) {
        patterns.add(PatternInsight(
          icon: "🎯",
          text: "الساعة ${formatHour(profile.peakHour!)} هي أكثر وقت تنجح فيه بإكمال مهامك ($doneAtHour إنجاز مسجل).",
        ));
      }
    }

    final habitsResult = await habitRepository.getAllHabits();
    final habits = habitsResult.getOrElse(() => []);
    if (habits.length >= 2) {
      final weakest = [...habits]..sort((a, b) => a.currentStreak.compareTo(b.currentStreak));
      final w = weakest.first;
      if (w.currentStreak < 3) {
        patterns.add(PatternInsight(
          icon: "⚠️",
          text: "عادة \"${w.title}\" هي الأضعف حالياً (${w.currentStreak} يوم فقط) — تحتاج تركيزاً إضافياً.",
        ));
      }
    }

    final ot = profile.openTimestamps;
    if (ot.length >= 10) {
      final lateOpens = ot.where((t) => t.hour >= 0 && t.hour < 5).length;
      if (lateOpens / ot.length > 0.25) {
        patterns.add(const PatternInsight(
          icon: "🌙",
          text: "نسبة ملحوظة من استخدامك للتطبيق تحدث في ساعات متأخرة جداً من الليل — قد يؤثر ذلك على جودة نومك وتركيزك.",
        ));
      }
    }

    return patterns.take(6).toList();
  }

  // ── computePersonaModel() ──
  Future<PersonaModel> computePersonaModel() async {
    final allDays = await computeStats(21);
    final days = allDays.where((d) => d.total > 0).toList();
    final profile = await profileRepository.get();
    if (days.length < 3) return PersonaModel.analyzing;

    final avgRate = days.map((d) => d.rate).reduce((a, b) => a + b) / days.length;
    final variance =
        days.map((d) => pow(d.rate - avgRate, 2)).reduce((a, b) => a + b) / days.length;
    final consistency = 1 - min(1, sqrt(variance) * 2);

    bool nightHeavy = false, morningHeavy = false;
    final hc = profile.hourlyCompletes;
    final totalC = hc.values.fold(0, (a, b) => a + b);
    if (totalC > 3) {
      final night = [22, 23, 0, 1, 2].fold(0, (s, h) => s + (hc[h] ?? 0));
      nightHeavy = night / totalC > 0.35;
      final morning = [5, 6, 7, 8, 9].fold(0, (s, h) => s + (hc[h] ?? 0));
      morningHeavy = morning / totalC > 0.45;
    }

    if (avgRate >= 0.75 && consistency >= 0.6) {
      return const PersonaModel(
        label: "Extreme Productive Mode",
        ar: "أداء إنتاجي استثنائي",
        icon: "🚀",
        desc: "تحافظ على معدل إنجاز مرتفع جداً مع استقرار قوي. هذا مستوى أداء نادر — استمر في حماية هذا النظام.",
      );
    } else if (nightHeavy) {
      return const PersonaModel(
        label: "Night Worker",
        ar: "عامل الليل",
        icon: "🌙",
        desc: "أغلب إنجازاتك تحدث في ساعات متأخرة من الليل. قد يفيدك تجربة نقل بعض المهام الحرجة لساعات الصباح لتحسين الجودة.",
      );
    } else if (morningHeavy && avgRate >= 0.5) {
      return const PersonaModel(
        label: "High Focus Performer",
        ar: "مؤدٍ عالي التركيز صباحاً",
        icon: "☀️",
        desc: "تركيزك في أعلى مستوياته صباحاً. استثمر هذه الفترة في أهم وأصعب مهامك.",
      );
    } else if (avgRate < 0.35 && consistency < 0.4) {
      return const PersonaModel(
        label: "Discipline Breaker",
        ar: "كاسر الانضباط",
        icon: "⚡",
        desc: "نمط أداءك غير مستقر مع معدل إنجاز منخفض. هذا لا يعني الفشل، بل إشارة لإعادة بناء جدول أخف وأكثر واقعية.",
      );
    } else if (variance > 0.06) {
      return const PersonaModel(
        label: "Inconsistent Builder",
        ar: "باني غير مستقر",
        icon: "🌊",
        desc: "أداؤك يتراوح بشدة بين أيام قوية وأيام ضعيفة. التركيز على الثبات أهم الآن من السرعة.",
      );
    } else if (avgRate < 0.5) {
      return const PersonaModel(
        label: "Chronic Procrastinator",
        ar: "مماطل مزمن",
        icon: "⏳",
        desc: "يلاحظ النظام نمط تأجيل متكرر للمهام. خطوات صغيرة ومتكررة ستكسر هذا النمط أسرع من خطوات كبيرة متقطعة.",
      );
    } else {
      return const PersonaModel(
        label: "Consistent Builder",
        ar: "باني مستقر",
        icon: "🧱",
        desc: "أداؤك معقول ومستقر نسبياً. زيادة تدريجية في صعوبة المهام ستدفعك للمستوى التالي.",
      );
    }
  }

  // ── computeRiskAssessment() ──
  Future<RiskAssessment> computeRiskAssessment() async {
    final allDays = await computeStats(10);
    final days = allDays.where((d) => d.total > 0).toList();
    final profile = await profileRepository.get();
    final analyze = await analyzeBehavior();

    int abandonRisk = 0;
    final ot = profile.openTimestamps;
    if (ot.length >= 3) {
      final gaps = <int>[];
      for (int i = 1; i < ot.length; i++) {
        gaps.add(ot[i].difference(ot[i - 1]).inMilliseconds);
      }
      final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
      final lastGap = DateTime.now().difference(ot.last).inMilliseconds;
      abandonRisk = min(95, ((lastGap / (avgGap == 0 ? 86400000 : avgGap)) * 30).round());
    }
    if (days.isNotEmpty) {
      final recent = days.length >= 3 ? days.sublist(days.length - 3) : days;
      final recentAvg = recent.map((d) => d.rate).reduce((a, b) => a + b) / recent.length;
      abandonRisk = min(95, (abandonRisk * 0.5 + (1 - recentAvg) * 50).round());
    }

    final now = DateTime.now();
    final hoursLeft = 24 - now.hour;
    int breakStreakRisk = min(
      95,
      (analyze.skippedNow * 18 + (1 - analyze.rateNow) * 40 + (hoursLeft < 6 ? 20 : 0)).round(),
    );
    if (profile.streak == 0) breakStreakRisk = max(breakStreakRisk, 10);

    int relapseRisk = 0;
    final habitsResult = await habitRepository.getAllHabits();
    final habits = habitsResult.getOrElse(() => []);
    if (habits.isNotEmpty) {
      final fragile = habits.where((h) => h.currentStreak > 0 && h.currentStreak < 5).length;
      relapseRisk =
          min(95, ((fragile / habits.length) * 60 + profile.failStreak * 8).round());
    }

    return RiskAssessment(
      abandonRisk: abandonRisk,
      breakStreakRisk: breakStreakRisk,
      relapseRisk: relapseRisk,
    );
  }

  // ── generateSmartNotification() ──
  /// Rate-limited to one nudge per 45 minutes, deduped per day+key, just
  /// like the original.
  Future<SmartNotification?> generateSmartNotification() async {
    var profile = await profileRepository.get();
    final now = DateTime.now();
    if (profile.lastSmartNotifAt != null &&
        now.difference(profile.lastSmartNotifAt!).inMinutes < 45) {
      return null;
    }
    final todayKey = dayKey(now);
    final analyze = await analyzeBehavior();
    final risk = await computeRiskAssessment();
    final hr = now.hour;

    // Text for every branch below is composed fresh each time via
    // MessageEngine (four independently-varying sentence pools), so
    // the same trigger never shows literally the same sentence twice
    // in a row — per spec: "لا أريد رسائل مكررة... تنوع كبير." The
    // *trigger conditions*, `kind`, and dedupe `key` stay exactly as
    // before; only the composed `text`/`icon` vary.
    SmartNotification? msg;
    if (analyze.skippedNow >= 3 && profile.lastSmartNotifKey != "${todayKey}_skip3") {
      final (gm, p) = await _composeTracked(
        profile,
        MessageCategory.laziness,
        {"n": "${analyze.skippedNow}", "days": "1"},
      );
      profile = p;
      msg = SmartNotification(icon: gm.icon, text: gm.text, kind: NotifKind.danger, key: "${todayKey}_skip3");
    } else if (risk.breakStreakRisk >= 65 &&
        profile.streak > 0 &&
        profile.lastSmartNotifKey != "${todayKey}_streakrisk") {
      final (gm, p) = await _composeTracked(
        profile,
        MessageCategory.streakRisk,
        {"streak": "${profile.streak}"},
      );
      profile = p.copyWith(riskWarnedHigh: true);
      msg = SmartNotification(icon: gm.icon, text: gm.text, kind: NotifKind.warn, key: "${todayKey}_streakrisk");
    } else if (analyze.rateNow >= 0.7 &&
        analyze.done >= 3 &&
        profile.lastSmartNotifKey != "${todayKey}_great") {
      final (gm, p) = await _composeTracked(
        profile,
        MessageCategory.progress,
        {
          "pct": "${(analyze.rateNow * 100).round()}",
          "n": "${analyze.done}",
          "streak": "${profile.streak}",
        },
      );
      profile = p;
      msg = SmartNotification(icon: gm.icon, text: gm.text, kind: NotifKind.gold, key: "${todayKey}_great");
    } else if (profile.worstHour != null &&
        hr == profile.worstHour &&
        profile.lastSmartNotifKey != "${todayKey}_worsthour") {
      final (gm, p) = await _composeTracked(
        profile,
        MessageCategory.worstHourPattern,
        {"hour": formatHour(hr)},
      );
      profile = p;
      msg = SmartNotification(icon: gm.icon, text: gm.text, kind: NotifKind.warn, key: "${todayKey}_worsthour");
    } else if (await _isScheduleOverloaded(analyze.total) &&
        profile.lastSmartNotifKey != "${todayKey}_overload") {
      final (gm, p) = await _composeTracked(
        profile,
        MessageCategory.overload,
        {"n": "${analyze.total}", "days": "7"},
      );
      profile = p;
      msg = SmartNotification(icon: gm.icon, text: gm.text, kind: NotifKind.warn, key: "${todayKey}_overload");
    } else {
      final habitsResult = await habitRepository.getAllHabits();
      final habits = habitsResult.getOrElse(() => []);
      final h7 = habits.where((h) => h.currentStreak > 0 && h.currentStreak % 7 == 0);
      if (h7.isNotEmpty && profile.lastSmartNotifKey != "${todayKey}_habit7") {
        final h = h7.first;
        final (gm, p) = await _composeTracked(
          profile,
          MessageCategory.streakSaved,
          {"streak": "${h.currentStreak}"},
        );
        profile = p;
        msg = SmartNotification(icon: gm.icon, text: gm.text, kind: NotifKind.success, key: "${todayKey}_habit7");
      } else if (hr >= 21 &&
          analyze.total > 0 &&
          analyze.rateNow < 0.4 &&
          profile.lastSmartNotifKey != "${todayKey}_lownight") {
        final (gm, p) = await _composeTracked(
          profile,
          MessageCategory.relapse,
          {"n": "1", "streak": "${profile.streak}"},
        );
        profile = p;
        msg = SmartNotification(icon: gm.icon, text: gm.text, kind: NotifKind.warn, key: "${todayKey}_lownight");
      }
    }

    if (msg != null) {
      profile = profile.copyWith(lastSmartNotifAt: now, lastSmartNotifKey: msg.key);
      await profileRepository.save(profile);
    }
    return msg;
  }

  // ── interpretHiddenReason() ──
  Future<List<HiddenReason>> interpretHiddenReason() async {
    var profile = await profileRepository.get();
    final analyze = await analyzeBehavior();
    final hr = DateTime.now().hour;
    final risk = await computeRiskAssessment();
    final reasons = <HiddenReason>[];

    final schedResult = await scheduleRepository.getScheduleForDay(jsWeekday(DateTime.now()));
    final sched = schedResult.getOrElse(() => []);
    final logResult = await scheduleRepository.getDayLog(dayKey());
    final log = logResult.getOrElse(() => {});
    final hardPending = sched.any((t) =>
        t.priority == SchedPriority.high &&
        (log[t.id]?.status ?? DayTaskStatus.pending) == DayTaskStatus.pending);

    if (hardPending && analyze.skippedNow >= 1 && hr >= 10) {
      final (gm, p) = await _composeTracked(profile, MessageCategory.hiddenAvoidance, {});
      profile = p;
      reasons.add(HiddenReason(icon: gm.icon, type: HiddenReasonType.avoidance, text: gm.text));
    }
    if (profile.failStreak >= 3) {
      final (gm, p) = await _composeTracked(profile, MessageCategory.hiddenBurnout, {});
      profile = p;
      reasons.add(HiddenReason(icon: gm.icon, type: HiddenReasonType.burnout, text: gm.text));
    }
    if (analyze.skippedNow >= 2 && analyze.rateNow < 0.3 && analyze.total > 0) {
      final (gm, p) = await _composeTracked(profile, MessageCategory.hiddenProcrastination, {});
      profile = p;
      reasons.add(HiddenReason(icon: gm.icon, type: HiddenReasonType.procrastination, text: gm.text));
    }
    if (profile.consecutiveSkips >= 3) {
      final (gm, p) = await _composeTracked(profile, MessageCategory.hiddenOverload, {});
      profile = p;
      reasons.add(HiddenReason(icon: gm.icon, type: HiddenReasonType.overload, text: gm.text));
    }
    final ot = profile.openTimestamps;
    if (ot.length >= 6) {
      final lastFew = ot.sublist(ot.length - 6);
      final durations = <int>[];
      for (int i = 1; i < lastFew.length; i++) {
        durations.add(lastFew[i].difference(lastFew[i - 1]).inMilliseconds);
      }
      if (durations.where((d) => d < 3 * 60 * 1000).length >= 3) {
        final (gm, p) = await _composeTracked(profile, MessageCategory.hiddenHesitation, {});
        profile = p;
        reasons.add(HiddenReason(icon: gm.icon, type: HiddenReasonType.hesitation, text: gm.text));
      }
    }
    if (risk.breakStreakRisk >= 60 && profile.streak > 0) {
      final (gm, p) = await _composeTracked(
        profile,
        MessageCategory.hiddenMotivationCollapse,
        {"streak": "${profile.streak}"},
      );
      profile = p;
      reasons.add(HiddenReason(icon: gm.icon, type: HiddenReasonType.motivationCollapse, text: gm.text));
    }
    if ((hr >= 23 || hr < 5) && analyze.rateNow < 0.4 && analyze.total > 0) {
      final (gm, p) = await _composeTracked(profile, MessageCategory.hiddenFatigue, {});
      profile = p;
      reasons.add(HiddenReason(icon: gm.icon, type: HiddenReasonType.fatigue, text: gm.text));
    }

    // Persist the recentMessageHashes bookkeeping accumulated above.
    // Must happen before _recordDeepReasons(), which does its own fresh
    // get()+save() for reasonLog and would otherwise read a stale
    // (pre-hash-update) profile.
    await profileRepository.save(profile);
    if (reasons.isNotEmpty) await _recordDeepReasons(reasons);
    return reasons;
  }

  Future<void> _recordDeepReasons(List<HiddenReason> reasons) async {
    var profile = await profileRepository.get();
    final todayKey = dayKey();
    final alreadyLogged =
        profile.reasonLog.any((r) => r.day == todayKey && r.type == reasons.first.type);
    if (alreadyLogged) return;
    final updated = [...profile.reasonLog, ReasonLogEntry(
      day: todayKey,
      type: reasons.first.type,
      text: reasons.first.text,
      icon: reasons.first.icon,
      at: DateTime.now(),
    )];
    profile = profile.copyWith(
      reasonLog: updated.length > 60 ? updated.sublist(updated.length - 60) : updated,
    );
    await profileRepository.save(profile);
  }

  // ── computeAppPersonality() ──
  Future<AppPersonalityMode> computeAppPersonality() async {
    var profile = await profileRepository.get();
    final risk = await computeRiskAssessment();
    final persona = await computePersonaModel();

    AppPersonalityMode mode = AppPersonalityMode.calm;
    if (profile.failStreak >= 3 || profile.cheatFlags >= 2) {
      mode = AppPersonalityMode.recovery;
    } else if (risk.breakStreakRisk >= 65 || risk.relapseRisk >= 60 || risk.abandonRisk >= 65) {
      mode = AppPersonalityMode.warning;
    } else if (persona.label == "Extreme Productive Mode" ||
        persona.label == "High Focus Performer") {
      mode = AppPersonalityMode.analytical;
    }

    if (profile.personality != mode) {
      final history = [
        ...profile.personalityHistory,
        PersonalityChange(mode: mode, at: DateTime.now()),
      ];
      profile = profile.copyWith(
        personality: mode,
        personalityHistory: history.length > 40 ? history.sublist(history.length - 40) : history,
      );
      await profileRepository.save(profile);
    }
    return mode;
  }

  // ── generateWeeklyMirrorReport() ──
  Future<List<PatternInsight>> generateWeeklyMirrorReport() async {
    final allDays = await computeStats(7);
    final days = allDays.where((d) => d.total > 0).toList();
    if (days.length < 3) return [];
    final lines = <PatternInsight>[];
    final avgRate = days.map((d) => d.rate).reduce((a, b) => a + b) / days.length;

    final allLogsResult = await scheduleRepository.getAllLogs();
    final allLogs = allLogsResult.getOrElse(() => {});
    int hiFail = 0, hiTotal = 0, otherFail = 0, otherTotal = 0;
    for (final entry in allLogs.entries) {
      final d = DateTime.tryParse(entry.key);
      if (d == null) continue;
      if (DateTime.now().difference(d).inMilliseconds > 8 * 86400000) continue;
      final schedResult = await scheduleRepository.getScheduleForDay(jsWeekday(d));
      final sched = schedResult.getOrElse(() => []);
      for (final t in sched) {
        final ts = entry.value[t.id];
        if (ts == null) continue;
        if (t.priority == SchedPriority.high) {
          hiTotal++;
          if (ts.status == DayTaskStatus.failed) hiFail++;
        } else {
          otherTotal++;
          if (ts.status == DayTaskStatus.failed) otherFail++;
        }
      }
    }
    final hiRate = hiTotal > 0 ? hiFail / hiTotal : 0.0;
    final otherRate = otherTotal > 0 ? otherFail / otherTotal : 0.0;
    if (hiRate > otherRate * 1.4 && hiRate > 0.25) {
      lines.add(PatternInsight(
        icon: "🎯",
        text: "هذا الأسبوع تجنبت المهام التي تحتاج جهداً ذهنياً مرتفعاً بنسبة ملحوظة (${(hiRate * 100).round()}% فشل في المهام عالية الأولوية).",
      ));
    }

    final mid = (days.length / 2).ceil();
    final early = days.sublist(0, mid);
    final late = days.sublist(mid);
    final earlyAvg =
        early.isNotEmpty ? early.map((d) => d.rate).reduce((a, b) => a + b) / early.length : 0.0;
    final lateAvg =
        late.isNotEmpty ? late.map((d) => d.rate).reduce((a, b) => a + b) / late.length : 0.0;
    if (earlyAvg - lateAvg > 0.25) {
      lines.add(const PatternInsight(
        icon: "📉",
        text: "لوحظ أنك تبدأ العمل بسهولة في بداية الفترة، لكنك تنسحب سريعاً عند زيادة الصعوبة أو مرور الوقت.",
      ));
    }

    final profile = await profileRepository.get();
    final hc = profile.hourlyCompletes;
    final night = [22, 23, 0, 1, 2].fold(0, (s, h) => s + (hc[h] ?? 0));
    final totalC = hc.values.fold(0, (a, b) => a + b);
    if (totalC > 4 && night / totalC > 0.3) {
      lines.add(const PatternInsight(
        icon: "🌙",
        text: "أداؤك ينخفض بشكل متكرر بعد ساعات الليل مقارنة بباقي اليوم.",
      ));
    }
    if (profile.streak == 0 && profile.bestStreak >= 5) {
      lines.add(const PatternInsight(
        icon: "💔",
        text: "يبدو أنك تتأثر كثيراً عند كسر سلسلة الإنجاز اليومية، وتحتاج وقتاً أطول للعودة بعدها.",
      ));
    }
    if (lines.isEmpty && avgRate >= 0.6) {
      lines.add(const PatternInsight(
        icon: "✅",
        text: "هذا الأسبوع كان مستقراً نسبياً بدون أنماط سلبية واضحة — استمر على هذا النهج.",
      ));
    }
    return lines.take(4).toList();
  }

  /// Should be called once on app open (Friday-gated, 6-day cooldown),
  /// mirroring maybeShowWeeklyMirror(). Returns the report if it should
  /// be shown now, null otherwise.
  Future<List<PatternInsight>?> maybeGenerateWeeklyMirror() async {
    var profile = await profileRepository.get();
    final now = DateTime.now();
    if (profile.lastWeeklyMirrorAt != null &&
        now.difference(profile.lastWeeklyMirrorAt!).inMilliseconds < 6 * 24 * 3600 * 1000) {
      return null;
    }
    if (jsWeekday(now) != 5) return null; // Friday
    final lines = await generateWeeklyMirrorReport();
    if (lines.isEmpty) return null;
    final snapshots = [...profile.weeklyMirrors, WeeklyMirrorSnapshot(at: now, lines: lines)];
    profile = profile.copyWith(
      lastWeeklyMirrorAt: now,
      weeklyMirrors: snapshots.length > 12 ? snapshots.sublist(snapshots.length - 12) : snapshots,
    );
    await profileRepository.save(profile);
    return lines;
  }

  // ── maybeLockIdentity() ──
  /// After 30 days since first open AND 18+ active days, permanently
  /// locks a behavioral identity profile.
  Future<IdentityProfile?> maybeLockIdentity() async {
    var profile = await profileRepository.get();
    if (profile.identityLocked) return profile.identityProfile;
    if (profile.firstOpenAt == null) return null;
    final daysSinceFirst = DateTime.now().difference(profile.firstOpenAt!).inDays;
    final allLogsResult = await scheduleRepository.getAllLogs();
    final activeDays = allLogsResult.getOrElse(() => {}).keys.length;
    if (daysSinceFirst < 30 || activeDays < 18) return null;

    final persona = await computePersonaModel();
    final allDays = await computeStats(30);
    final days = allDays.where((d) => d.total > 0).toList();
    final avgRate =
        days.isNotEmpty ? days.map((d) => d.rate).reduce((a, b) => a + b) / days.length : 0.0;
    final variance = days.isNotEmpty
        ? days.map((d) => pow(d.rate - avgRate, 2)).reduce((a, b) => a + b) / days.length
        : 0.0;

    final identity = IdentityProfile(
      persona: persona.ar,
      bestHour: profile.peakHour,
      worstHour: profile.worstHour,
      weaknessType: variance > 0.06
          ? "عدم الاستقرار"
          : (avgRate < 0.4 ? "التسويف المزمن" : "ضغط المواعيد النهائية"),
      resilientAfterFail: profile.bestStreak > 0 && profile.streak > 0,
      lockedAt: DateTime.now(),
    );
    profile = profile.copyWith(identityLocked: true, identityProfile: identity);
    await profileRepository.save(profile);
    return identity;
  }

  // ── checkSilenceAnomaly() ──
  Future<PatternInsight?> checkSilenceAnomaly() async {
    var profile = await profileRepository.get();
    final ot = profile.openTimestamps;
    if (ot.length < 8) return null;
    final gaps = <int>[];
    for (int i = 1; i < ot.length - 1; i++) {
      gaps.add(ot[i].difference(ot[i - 1]).inMilliseconds);
    }
    final avgGap = gaps.isNotEmpty ? gaps.reduce((a, b) => a + b) / gaps.length : 0.0;
    final lastGap = DateTime.now().difference(ot.last).inMilliseconds;
    profile = profile.copyWith(avgGapMs: avgGap);
    if (avgGap <= 0) {
      await profileRepository.save(profile);
      return null;
    }
    final threshold = max(avgGap * 2.5, 36 * 3600 * 1000);
    final cooldownOk = profile.lastSilenceWarnAt == null ||
        DateTime.now().difference(profile.lastSilenceWarnAt!).inMilliseconds > 48 * 3600 * 1000;
    if (lastGap > threshold && cooldownOk) {
      final daysGone = (lastGap / 86400000).floor();
      final (gm, p) = await _composeTracked(
        profile,
        MessageCategory.disappearance,
        {"days": "$daysGone"},
      );
      profile = p.copyWith(lastSilenceWarnAt: DateTime.now());
      await profileRepository.save(profile);
      return PatternInsight(icon: gm.icon, text: gm.text);
    }
    await profileRepository.save(profile);
    return null;
  }

  // ── recordOpenEvent() — call once per app open ──
  Future<void> recordOpenEvent() async {
    var profile = await profileRepository.get();
    final timestamps = [...profile.openTimestamps, DateTime.now()];
    profile = profile.copyWith(
      openTimestamps:
          timestamps.length > 300 ? timestamps.sublist(timestamps.length - 300) : timestamps,
      totalOpens: profile.totalOpens + 1,
      firstOpenAt: profile.firstOpenAt ?? DateTime.now(),
    );
    await profileRepository.save(profile);
  }

  // ── touchStreak() — call once per app open, after recordOpenEvent ──
  Future<void> touchStreak() async {
    var profile = await profileRepository.get();
    final today = dayKey();
    if (profile.lastActiveKey == today) return;
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    int newStreak;
    if (profile.lastActiveKey == yesterday) {
      newStreak = profile.streak + 1;
    } else {
      newStreak = 1;
    }
    profile = profile.copyWith(
      streak: newStreak,
      bestStreak: max(profile.bestStreak, newStreak),
      lastActiveKey: today,
      gems: newStreak > 0 && newStreak % 7 == 0 ? profile.gems + 3 : profile.gems,
    );
    await profileRepository.save(profile);
  }

  // ── regCompletion() / regFail() — XP + streak bookkeeping ──
  /// Returns the XP actually granted (may be reduced by the
  /// authenticity check in a later pass — see README roadmap).
  // ── profile passthrough (for Shadow Mode gating in the UI) ──
  Future<BehaviorProfileEntity> getProfile() => profileRepository.get();

  Future<int> registerCompletion(ScheduledTaskEntity task, {bool perfect = false}) async {
    var profile = await profileRepository.get();
    int gained = 25;
    if (perfect) gained += 50;
    final newCombo = profile.combo + 1;
    gained += min(newCombo * 3, 60);
    gained += min(profile.streak * 5, 100);
    if (task.priority == SchedPriority.high) gained += 15;
    if (task.priority == SchedPriority.medium) gained += 5;

    profile = profile.copyWith(
      totalXP: profile.totalXP + gained,
      combo: newCombo,
      bestCombo: max(profile.bestCombo, newCombo),
      gems: perfect ? profile.gems + 1 : profile.gems,
    );
    await profileRepository.save(profile);
    return gained;
  }

  Future<int> registerFail(String kind) async {
    var profile = await profileRepository.get();
    final pen = kind == "escape" ? -40 : -20;
    profile = profile.copyWith(
      totalXP: max(0, profile.totalXP + pen),
      combo: 0,
      failStreak: profile.failStreak + 1,
    );
    await profileRepository.save(profile);
    return pen;
  }
}

class AnalyzeResult {
  final int skippedNow;
  final double rateNow;
  final int done;
  final int failed;
  final int total;
  final List<int> overdueHours;
  const AnalyzeResult({
    required this.skippedNow,
    required this.rateNow,
    required this.done,
    required this.failed,
    required this.total,
    required this.overdueHours,
  });
}

