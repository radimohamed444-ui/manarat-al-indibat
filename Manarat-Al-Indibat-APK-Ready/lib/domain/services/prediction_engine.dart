import "dart:math";
import "../entities/prediction_types.dart";
import "../entities/message_types.dart";
import "../repositories/behavior_profile_repository.dart";
import "../repositories/habit_repository.dart";
import "behavior_engine.dart";
import "message_engine.dart";

/// ── Prediction Engine ──
///
/// Ported from spec section 4 ("رابعاً: محرك التوقعات"). Sits on top
/// of [BehaviorEngine] (reuses its stats/risk primitives rather than
/// re-reading raw repositories) and produces forward-looking
/// probabilities *before* the day/habit/week actually fails — plus a
/// proactive, human-readable solution for each risk that crosses its
/// threshold, composed via [MessageEngine] so the wording varies every
/// time instead of a single fixed warning string.
///
/// Every number here is a rule-based estimate derived from on-device
/// history (recent completion rates, hourly fail/complete maps, streak
/// volatility, absence gaps). There is no cloud model and no network
/// call — "بدون استخدام الإنترنت، وبدون إرسال أي بيانات" per the spec.
class PredictionEngine {
  final BehaviorEngine behaviorEngine;
  final BehaviorProfileRepository profileRepository;
  final HabitRepository habitRepository;
  final MessageEngine messageEngine;

  PredictionEngine({
    required this.behaviorEngine,
    required this.profileRepository,
    required this.habitRepository,
    MessageEngine? messageEngine,
  }) : messageEngine = messageEngine ?? MessageEngine();

  // ── 1) احتمال نجاح/فشل اليوم ──
  Future<DayOutcomePrediction> predictTodayOutcome() async {
    final analyze = await behaviorEngine.analyzeBehavior();
    final risk = await behaviorEngine.computeRiskAssessment();
    final days = await behaviorEngine.computeStats(14);
    final withData = days.where((d) => d.total > 0).toList();

    final now = DateTime.now();
    final dayProgress = (now.hour * 60 + now.minute) / (24 * 60); // 0..1
    final remaining = 1 - dayProgress;

    // Baseline: historical average rate at this same point in the day,
    // approximated by the overall recent average (no per-hour dataset
    // for "rate as of hour X" without re-simulating full history, so we
    // blend live rate with the general trend, weighted by how much of
    // the day is already over — early-day live rate is noisy, late-day
    // live rate is near-final).
    final histAvg = withData.isNotEmpty
        ? withData.map((d) => d.rate).reduce((a, b) => a + b) / withData.length
        : 0.5;

    final liveWeight = min(1.0, 0.25 + dayProgress * 0.75);
    var successScore = analyze.rateNow * liveWeight + histAvg * (1 - liveWeight);

    // Penalize for pending overdue tasks and elevated streak-break risk;
    // reward remaining time if nothing is overdue yet.
    successScore -= min(0.35, analyze.skippedNow * 0.07);
    successScore -= (risk.breakStreakRisk / 100) * 0.15;
    if (analyze.total == 0) successScore = histAvg; // nothing scheduled yet today
    if (remaining < 0.15 && analyze.skippedNow == 0 && analyze.total > 0) {
      successScore += 0.1; // day nearly over and clean so far
    }
    successScore = successScore.clamp(0.02, 0.98);

    final confidence = min(100, (withData.length * 6).round() + (analyze.total > 0 ? 15 : 0));

    return DayOutcomePrediction(
      successProbability: (successScore * 100).round(),
      failureProbability: ((1 - successScore) * 100).round(),
      confidence: confidence.clamp(0, 100),
    );
  }

  // ── 2) احتمال ترك عادة (per habit, sorted worst-first) ──
  Future<List<HabitDropPrediction>> predictHabitDrops() async {
    final habitsResult = await habitRepository.getAllHabits();
    final habits = habitsResult.getOrElse(() => []);
    final profile = await profileRepository.get();

    final out = <HabitDropPrediction>[];
    for (final h in habits) {
      if (h.logs.isEmpty) continue;
      final recent = [...h.logs]..sort((a, b) => b.date.compareTo(a.date));
      final last14 = recent.take(14).toList();
      final successRate =
          last14.isNotEmpty ? last14.where((l) => l.success).length / last14.length : 0.5;

      // volatility: how much success flips day to day recently
      int flips = 0;
      for (int i = 1; i < last14.length; i++) {
        if (last14[i].success != last14[i - 1].success) flips++;
      }
      final volatility = last14.length > 1 ? flips / (last14.length - 1) : 0.0;

      var drop = (1 - successRate) * 55 + volatility * 25;
      if (h.currentStreak == 0) drop += 15;
      if (h.currentStreak > 0 && h.currentStreak < 4) drop += 8;
      drop += profile.failStreak * 2; // general fatigue bleeds into habit risk
      out.add(HabitDropPrediction(
        habitId: h.id,
        title: h.title,
        dropProbability: drop.clamp(0, 97).round(),
      ));
    }
    out.sort((a, b) => b.dropProbability.compareTo(a.dropProbability));
    return out;
  }

  // ── 3) احتمال العودة بعد الانقطاع ──
  Future<ReturnPrediction> predictReturn() async {
    final profile = await profileRepository.get();
    final ot = profile.openTimestamps;
    if (ot.length < 4) {
      return const ReturnPrediction(
        isCurrentlyAbsent: false,
        returnProbability: 0,
        estimatedDaysToReturn: 0,
      );
    }
    final gaps = <int>[];
    for (int i = 1; i < ot.length; i++) {
      gaps.add(ot[i].difference(ot[i - 1]).inMilliseconds);
    }
    final avgGapMs = gaps.reduce((a, b) => a + b) / gaps.length;
    final lastGapMs = DateTime.now().difference(ot.last).inMilliseconds;
    final isAbsent = lastGapMs > max(avgGapMs * 1.8, 30 * 3600 * 1000);
    if (!isAbsent) {
      return const ReturnPrediction(
        isCurrentlyAbsent: false,
        returnProbability: 0,
        estimatedDaysToReturn: 0,
      );
    }

    // Historically, longer track record + higher best streak → more
    // likely to eventually return; longer current gap → lower
    // short-term probability of returning *soon*.
    final gapRatio = lastGapMs / (avgGapMs == 0 ? 1 : avgGapMs);
    final trackRecordBonus = min(20, profile.totalOpens ~/ 5);
    final resilienceBonus = profile.bestStreak >= 7 ? 15 : (profile.bestStreak >= 3 ? 8 : 0);
    var returnProb = 80 - (gapRatio * 12) + trackRecordBonus + resilienceBonus;
    returnProb = returnProb.clamp(5, 95);

    final estimatedDays = max(1, (gapRatio * 0.8).round());

    return ReturnPrediction(
      isCurrentlyAbsent: true,
      returnProbability: returnProb.round(),
      estimatedDaysToReturn: estimatedDays,
    );
  }

  // ── 4) احتمال الإرهاق (short horizon) ──
  Future<FatiguePrediction> predictFatigue() async {
    final profile = await profileRepository.get();
    final analyze = await behaviorEngine.analyzeBehavior();
    final days = await behaviorEngine.computeStats(7);
    final withData = days.where((d) => d.total > 0).toList();

    var score = profile.failStreak * 12.0;
    score += analyze.skippedNow * 6;
    if (withData.length >= 3) {
      final avg = withData.map((d) => d.rate).reduce((a, b) => a + b) / withData.length;
      final trend = withData.last.rate - withData.first.rate;
      if (avg < 0.4) score += 20;
      if (trend < -0.25) score += 15;
    }
    final hc = profile.hourlyCompletes;
    final totalC = hc.values.fold(0, (a, b) => a + b);
    if (totalC > 4) {
      final lateNight = [23, 0, 1, 2, 3].fold(0, (s, h) => s + (hc[h] ?? 0));
      if (lateNight / totalC > 0.3) score += 12;
    }
    return FatiguePrediction(fatigueProbability: score.clamp(0, 96).round());
  }

  // ── 5) احتمال الاحتراق الذهني (longer horizon, cumulative) ──
  Future<BurnoutPrediction> predictBurnout() async {
    final profile = await profileRepository.get();
    final days = await behaviorEngine.computeStats(30);
    final withData = days.where((d) => d.total > 0).toList();

    var score = 0.0;
    if (withData.length >= 10) {
      final avg = withData.map((d) => d.rate).reduce((a, b) => a + b) / withData.length;
      final variance =
          withData.map((d) => pow(d.rate - avg, 2)).reduce((a, b) => a + b) / withData.length;
      // sustained high load (many scheduled tasks) with declining rate is
      // the clearest burnout signature, more than one-off bad days.
      final avgLoad = withData.map((d) => d.total).reduce((a, b) => a + b) / withData.length;
      if (avgLoad > 8 && avg < 0.55) score += 30;
      if (variance > 0.08) score += 15;
      final firstHalf = withData.take(withData.length ~/ 2).map((d) => d.rate);
      final secondHalf = withData.skip(withData.length ~/ 2).map((d) => d.rate);
      if (firstHalf.isNotEmpty && secondHalf.isNotEmpty) {
        final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
        final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
        if (secondAvg < firstAvg - 0.15) score += 20;
      }
    }
    score += profile.failStreak * 4;
    score += profile.cheatFlags * 5; // repeated self-manipulation flags read as strain too
    return BurnoutPrediction(burnoutProbability: score.clamp(0, 95).round());
  }

  // ── aggregate pass + proactive solutions ──
  /// Computes every prediction above in one pass and attaches a
  /// [MessageEngine]-composed solution for each risk that crosses its
  /// threshold — "ثم يعرض حلولاً قبل وقوع المشكلة."
  Future<PredictionBundle> computeAll() async {
    var profile = await profileRepository.get();
    final dayOutcome = await predictTodayOutcome();
    final habitDrops = await predictHabitDrops();
    final returnPrediction = await predictReturn();
    final fatigue = await predictFatigue();
    final burnout = await predictBurnout();

    final recent = List<String>.from(profile.recentMessageHashes);
    final solutions = <ProactiveSolution>[];

    void addSolution(MessageCategory cat, Map<String, String> params) {
      final msg = messageEngine.compose(cat, params: params, recentHashes: recent);
      solutions.add(ProactiveSolution(icon: msg.icon, text: msg.text, relatedTo: cat));
      recent.add(messageEngine.hashOf(msg));
    }

    if (dayOutcome.failureProbability >= 60 && dayOutcome.confidence >= 25) {
      addSolution(MessageCategory.laziness, {
        "days": "2",
        "n": "${max(1, 100 - dayOutcome.successProbability) ~/ 20}",
      });
    }
    if (habitDrops.isNotEmpty && habitDrops.first.dropProbability >= 55) {
      addSolution(MessageCategory.habitRisk, {"title": habitDrops.first.title});
    }
    if (returnPrediction.isCurrentlyAbsent) {
      addSolution(MessageCategory.disappearance, {
        "days": "${max(1, (returnPrediction.estimatedDaysToReturn))}",
      });
    }
    if (fatigue.fatigueProbability >= 55) {
      addSolution(MessageCategory.fatigueWarning, {});
    }
    if (burnout.burnoutProbability >= 55) {
      addSolution(MessageCategory.burnoutWarning, {});
    }
    if (solutions.isEmpty) {
      addSolution(MessageCategory.steady, {});
    }

    // persist the rolling anti-repeat window (cap 60)
    profile = profile.copyWith(
      recentMessageHashes: recent.length > 60 ? recent.sublist(recent.length - 60) : recent,
    );
    await profileRepository.save(profile);

    return PredictionBundle(
      dayOutcome: dayOutcome,
      habitDrops: habitDrops,
      returnPrediction: returnPrediction,
      fatigue: fatigue,
      burnout: burnout,
      solutions: solutions,
    );
  }
}
