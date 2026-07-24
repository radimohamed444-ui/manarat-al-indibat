import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:workmanager/workmanager.dart";
import "core/constants/app_constants.dart";
import "core/di/injection.dart";
import "core/theme/app_theme.dart";
import "core/background/background_dispatcher.dart";
import "core/services/notification_service.dart";
import "domain/services/behavior_memory_engine.dart";
import "domain/services/notification_intelligence_engine.dart";
import "data/models/task_model.dart";
import "data/models/habit_model.dart";
import "data/models/scheduled_task_model.dart";
import "data/models/task_log_entry_model.dart";
import "data/models/behavior_profile_model.dart";
import "presentation/navigation/main_shell.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initHive();
  await initDependencyInjection();

  // Notification Intelligence — init the local delivery channel and
  // ask for the OS permission once, up front. 100% on-device: no FCM/
  // APNs, no server involved.
  final notificationService = sl<NotificationService>();
  await notificationService.init();
  await notificationService.requestPermission();

  await _initBackgroundTasks();

  runApp(const ManaratApp());
}

/// Registers all Hive adapters and opens every box up front. Boxes stay
/// open for the app's lifetime (offline-first, no lazy re-opening).
Future<void> _initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(HabitLogModelAdapter());
  Hive.registerAdapter(ScheduledTaskModelAdapter());
  Hive.registerAdapter(TaskLogEntryModelAdapter());
  Hive.registerAdapter(DayLogModelAdapter());
  Hive.registerAdapter(BehaviorProfileModelAdapter());

  await Future.wait([
    Hive.openBox<TaskModel>(AppConstants.boxTasks),
    Hive.openBox<HabitModel>(AppConstants.boxHabits),
    Hive.openBox<ScheduledTaskModel>(AppConstants.boxScheduleBase),
    Hive.openBox(AppConstants.boxScheduleOverrides),
    Hive.openBox<DayLogModel>(AppConstants.boxDayLogs),
    Hive.openBox<BehaviorProfileModel>(AppConstants.boxBehaviorProfile),
  ]);
}

/// Background Tasks — `workmanager` drives both Android `WorkManager`
/// and iOS `BGTaskScheduler` from the same Dart API. Periodic interval
/// is Android's practical minimum (15 min); iOS treats this as a
/// hint only (see `background_dispatcher.dart` for the platform
/// caveats). Requires the native wiring documented in the README
/// (`AndroidManifest.xml` / `Info.plist`) once `flutter create .` has
/// generated the platform folders.
Future<void> _initBackgroundTasks() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    kBehaviorAnalysisTask,
    kBehaviorAnalysisTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.not_required),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}

class ManaratApp extends StatefulWidget {
  const ManaratApp({super.key});

  @override
  State<ManaratApp> createState() => _ManaratAppState();
}

class _ManaratAppState extends State<ManaratApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First-run-of-the-day foreground pass — the background task
    // covers "app closed", this covers "app just opened".
    WidgetsBinding.instance.addPostFrameCallback((_) => _foregroundIntelligenceTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foregroundIntelligenceTick();
    }
  }

  Future<void> _foregroundIntelligenceTick() async {
    await sl<BehaviorMemoryEngine>().recordDailySnapshotIfNeeded();
    await sl<NotificationIntelligenceEngine>().evaluateAndDeliver();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appNameAr,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: const Locale("ar"),
      supportedLocales: const [Locale("ar"), Locale("en")],
      home: const MainShell(),
    );
  }
}
