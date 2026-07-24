import "package:flutter/widgets.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:workmanager/workmanager.dart";
import "../constants/app_constants.dart";
import "../di/injection.dart";
import "../../data/models/task_model.dart";
import "../../data/models/habit_model.dart";
import "../../data/models/scheduled_task_model.dart";
import "../../data/models/task_log_entry_model.dart";
import "../../data/models/behavior_profile_model.dart";
import "../../domain/services/behavior_memory_engine.dart";
import "../../domain/services/notification_intelligence_engine.dart";

/// Unique task name registered with `workmanager`. Kept as a constant
/// so `main.dart` (registration) and this file (execution) never drift
/// apart.
const String kBehaviorAnalysisTask = "behaviorAnalysisTask";

/// The single background entry point for the whole "Behavior AI
/// Coach": periodic analysis + local notification delivery even when
/// the app is fully closed.
///
/// - **Android**: `workmanager` schedules this via `WorkManager`,
///   respecting Doze/App-Standby; minimum periodic interval is 15
///   minutes (an OS constraint, not this app's choice).
/// - **iOS**: `workmanager` schedules this via `BGTaskScheduler`
///   (`BGAppRefreshTask`/`BGProcessingTask`). iOS decides *when* —
///   opportunistically, based on usage patterns and battery — it does
///   not guarantee the requested interval. This is a platform
///   limitation of BGTaskScheduler itself, not something any Flutter
///   plugin can work around; see the setup notes in README for the
///   required `Info.plist`/`AppDelegate` wiring.
///
/// Must be a **top-level** (or static) function, annotated exactly
/// like this, per `workmanager`'s isolate-entry-point requirement.
@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await _bootstrapHeadless();

      final memoryEngine = sl<BehaviorMemoryEngine>();
      final notificationIntelligence = sl<NotificationIntelligenceEngine>();

      await memoryEngine.recordDailySnapshotIfNeeded();
      await notificationIntelligence.evaluateAndDeliver();

      return true;
    } catch (_) {
      // Background isolates should never crash the OS scheduler —
      // report failure so the platform can retry with its own
      // backoff policy instead of the app force-throwing.
      return false;
    }
  });
}

/// This isolate is separate from the UI isolate, so Hive + DI need
/// their own (idempotent) init — mirrors `main.dart`'s `_initHive` +
/// `initDependencyInjection`, minus anything UI-only.
Future<void> _bootstrapHeadless() async {
  await Hive.initFlutter();

  // registerAdapter is a no-op if already registered in this isolate,
  // but each background wake-up gets a fresh isolate, so this always
  // runs once per invocation — safe.
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HabitModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HabitLogModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ScheduledTaskModelAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TaskLogEntryModelAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(DayLogModelAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(BehaviorProfileModelAdapter());

  if (!Hive.isBoxOpen(AppConstants.boxTasks)) {
    await Hive.openBox<TaskModel>(AppConstants.boxTasks);
  }
  if (!Hive.isBoxOpen(AppConstants.boxHabits)) {
    await Hive.openBox<HabitModel>(AppConstants.boxHabits);
  }
  if (!Hive.isBoxOpen(AppConstants.boxScheduleBase)) {
    await Hive.openBox<ScheduledTaskModel>(AppConstants.boxScheduleBase);
  }
  if (!Hive.isBoxOpen(AppConstants.boxScheduleOverrides)) {
    await Hive.openBox(AppConstants.boxScheduleOverrides);
  }
  if (!Hive.isBoxOpen(AppConstants.boxDayLogs)) {
    await Hive.openBox<DayLogModel>(AppConstants.boxDayLogs);
  }
  if (!Hive.isBoxOpen(AppConstants.boxBehaviorProfile)) {
    await Hive.openBox<BehaviorProfileModel>(AppConstants.boxBehaviorProfile);
  }

  if (!sl.isRegistered<BehaviorMemoryEngine>()) {
    await initDependencyInjection();
  }
}
