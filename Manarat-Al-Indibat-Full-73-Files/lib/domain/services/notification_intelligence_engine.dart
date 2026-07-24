import "../entities/message_types.dart";
import "../entities/memory_types.dart";
import "../repositories/behavior_profile_repository.dart";
import "../../core/utils/day_key.dart";
import "message_engine.dart";
import "behavior_engine.dart";
import "prediction_engine.dart";
import "behavior_memory_engine.dart";
import "notification_dispatcher.dart";

/// ── Notification Intelligence ──
///
/// Spec: "لا يعتمد فقط على الوقت. بل يعتمد على السلوك." This engine is
/// the bridge between the (already-built) rule-based intelligence —
/// [BehaviorEngine], [PredictionEngine], [BehaviorMemoryEngine] — and
/// *actually delivered* local notifications via [NotificationDispatcher].
/// Everything it decides is derived from on-device behavioral data,
/// never from a fixed clock alone:
///
/// - "اعتاد فتح التطبيق حوالي الساعة 8 مساءً ونسي اليوم" → detected
///   from the histogram of [BehaviorProfileEntity.openTimestamps].
/// - "ينجز المهام صباحاً" → detected from
///   [BehaviorProfileEntity.peakHour] (already computed by
///   BehaviorEngine.analyzeBehavior()).
/// - "لاحظ تراجعاً" → relays BehaviorEngine.generateSmartNotification()
///   and the top PredictionEngine risk/solution.
/// - Long-horizon "كيف كنت قبل شهر" nudges → relays
///   BehaviorMemoryEngine, throttled to roughly once a week.
///
/// Call [evaluateAndDeliver] from both the background task
/// (`background_dispatcher.dart`, so it fires even with the app
/// closed) and opportunistically on app resume. It is fully
/// idempotent/rate-limited internally, so calling it often is safe.
class NotificationIntelligenceEngine {
  final BehaviorProfileRepository profileRepository;
  final BehaviorEngine behaviorEngine;
  final PredictionEngine? predictionEngine;
  final BehaviorMemoryEngine? memoryEngine;
  final NotificationDispatcher dispatcher;
  final MessageEngine messageEngine;

  static const String appTitle = "منارة الانضباط";

  NotificationIntelligenceEngine({
    required this.profileRepository,
    required this.behaviorEngine,
    required this.dispatcher,
    this.predictionEngine,
    this.memoryEngine,
    MessageEngine? messageEngine,
  }) : messageEngine = messageEngine ?? MessageEngine();

  /// Mode of the hour-of-day histogram in [timestamps], i.e. the hour
  /// the user most consistently opens the app — only returned once
  /// there's enough signal (>=8 samples, mode is a clearly-dominant
  /// pattern, not noise).
  int? _usualOpenHour(List<DateTime> timestamps) {
    if (timestamps.length < 8) return null;
    final counts = <int, int>{};
    for (final t in timestamps) {
      counts[t.hour] = (counts[t.hour] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.first;
    if (top.value / timestamps.length < 0.22) return null; // too scattered
    return top.key;
  }

  /// Runs every adaptive check once and delivers whatever fires.
  /// Returns the list of trigger keys that were actually delivered
  /// this call (useful for logging/tests).
  Future<List<String>> evaluateAndDeliver() async {
    final delivered = <String>[];
    if (!await dispatcher.hasPermission()) return delivered;

    var profile = await profileRepository.get();
    final now = DateTime.now();
    final today = dayKey(now);

    bool sentToday(String key) {
      final t = profile.lastDeliveredNotifAt[key];
      return t != null && dayKey(t) == today;
    }

    bool sentWithin(String key, Duration span) {
      final t = profile.lastDeliveredNotifAt[key];
      return t != null && now.difference(t) < span;
    }

    Future<void> mark(String key) async {
      profile = profile.copyWith(
        lastDeliveredNotifAt: {...profile.lastDeliveredNotifAt, key: now},
      );
      await profileRepository.save(profile);
    }

    Future<void> markHash(String text) async {
      final h = text.hashCode.toString();
      final updated = [...profile.recentMessageHashes, h];
      profile = profile.copyWith(
        recentMessageHashes: updated.length > 60 ? updated.sublist(updated.length - 60) : updated,
      );
      await profileRepository.save(profile);
    }

    // 1) Behavior-adaptive "missed your usual open time" nudge.
    final usualHour = _usualOpenHour(profile.openTimestamps);
    if (usualHour != null &&
        profile.lastActiveKey != today &&
        now.hour >= usualHour + 1 &&
        !sentToday("missedUsualTime")) {
      final msg = messageEngine.compose(
        MessageCategory.notifMissedUsualTime,
        params: {"hour": formatHour(usualHour)},
        recentHashes: profile.recentMessageHashes,
      );
      await dispatcher.showNow(id: 3001, title: appTitle, body: "${msg.icon} ${msg.text}");
      await markHash(msg.text);
      await mark("missedUsualTime");
      delivered.add("missedUsualTime");
    }

    // 2) Behavior-adaptive morning productivity boost, fired right at
    // the user's own historical peak hour — not a fixed clock time.
    final peak = profile.peakHour;
    if (peak != null && peak >= 5 && peak <= 11 && now.hour == peak && !sentToday("morningBoost")) {
      final msg = messageEngine.compose(
        MessageCategory.notifMorningBoost,
        params: {"hour": formatHour(peak)},
        recentHashes: profile.recentMessageHashes,
      );
      await dispatcher.showNow(id: 3002, title: appTitle, body: "${msg.icon} ${msg.text}");
      await markHash(msg.text);
      await mark("morningBoost");
      delivered.add("morningBoost");
    }

    // 3) Relay the core Behavior Engine's own proactive nudge — it
    // already rate-limits itself (45 min cooldown + per-day key), so
    // no extra dedupe needed here.
    final smart = await behaviorEngine.generateSmartNotification();
    if (smart != null) {
      await dispatcher.showNow(id: 3003, title: appTitle, body: "${smart.icon} ${smart.text}");
      delivered.add("smart:${smart.key}");
      profile = await profileRepository.get(); // re-read: engine saved its own state
    }

    // 4) Relay the Prediction Engine's top proactive solution,
    // throttled to roughly once every 6 hours so it doesn't spam on
    // every 15-minute background run.
    final prediction = predictionEngine;
    if (prediction != null && !sentWithin("prediction", const Duration(hours: 6))) {
      final bundle = await prediction.computeAll();
      if (bundle.solutions.isNotEmpty) {
        final sol = bundle.solutions.first;
        await dispatcher.showNow(id: 3004, title: appTitle, body: "${sol.icon} ${sol.text}");
        await mark("prediction");
        delivered.add("prediction:${sol.relatedTo.name}");
      }
    }

    // 5) Relay Behavior Memory's month-over-month comparison, only
    // when there's an actual improvement/decline to report, throttled
    // to roughly once every 6 days.
    final memory = memoryEngine;
    if (memory != null && !sentWithin("memory", const Duration(days: 6))) {
      final cmp = await memory.compareToDaysAgo(MemoryPeriod.oneMonth);
      if (cmp.hasData && cmp.trend != MemoryTrend.stable) {
        await dispatcher.showNow(id: 3005, title: appTitle, body: "${cmp.icon} ${cmp.narrative}");
        await mark("memory");
        delivered.add("memory");
      }
    }

    return delivered;
  }
}
