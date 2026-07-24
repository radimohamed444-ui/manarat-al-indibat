import "package:get_it/get_it.dart";
import "../../data/datasources/local/task_local_datasource.dart";
import "../../data/datasources/local/habit_local_datasource.dart";
import "../../data/datasources/local/schedule_local_datasource.dart";
import "../../data/datasources/local/behavior_profile_local_datasource.dart";
import "../../data/repositories/task_repository_impl.dart";
import "../../data/repositories/habit_repository_impl.dart";
import "../../data/repositories/schedule_repository_impl.dart";
import "../../data/repositories/behavior_profile_repository_impl.dart";
import "../../domain/repositories/task_repository.dart";
import "../../domain/repositories/habit_repository.dart";
import "../../domain/repositories/schedule_repository.dart";
import "../../domain/repositories/behavior_profile_repository.dart";
import "../../domain/usecases/task/create_task_usecase.dart";
import "../../domain/usecases/task/postpone_task_usecase.dart";
import "../../domain/usecases/task/decompose_task_usecase.dart";
import "../../domain/usecases/habit/log_habit_usecase.dart";
import "../../domain/services/behavior_engine.dart";
import "../../domain/services/message_engine.dart";
import "../../domain/services/prediction_engine.dart";
import "../../domain/services/behavior_memory_engine.dart";
import "../../domain/services/notification_dispatcher.dart";
import "../../domain/services/notification_intelligence_engine.dart";
import "../services/notification_service.dart";
import "../../presentation/viewmodels/task_viewmodel.dart";
import "../../presentation/viewmodels/habit_viewmodel.dart";
import "../../presentation/viewmodels/schedule_viewmodel.dart";
import "../../presentation/viewmodels/behavior_viewmodel.dart";
import "../../presentation/viewmodels/prediction_viewmodel.dart";
import "../../presentation/viewmodels/memory_viewmodel.dart";

final sl = GetIt.instance;

/// Composition root. Called once in main() after Hive is initialized.
/// Wires: data sources -> repositories -> services/use cases -> view
/// models, each layer only knowing about the abstraction beneath it.
Future<void> initDependencyInjection() async {
  // Data sources
  sl.registerLazySingleton(() => TaskLocalDataSource());
  sl.registerLazySingleton(() => HabitLocalDataSource());
  sl.registerLazySingleton(() => ScheduleLocalDataSource());
  sl.registerLazySingleton(() => BehaviorProfileLocalDataSource());

  // Repositories (registered against their domain interface)
  sl.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(sl()));
  sl.registerLazySingleton<HabitRepository>(() => HabitRepositoryImpl(sl()));
  sl.registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl(sl()));
  sl.registerLazySingleton<BehaviorProfileRepository>(
    () => BehaviorProfileRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => PostponeTaskUseCase(sl()));
  sl.registerLazySingleton(() => DecomposeTaskUseCase(sl()));
  sl.registerLazySingleton(() => LogHabitUseCase(sl()));

  // Smart Messaging Engine — pure-Dart template composer used by both
  // BehaviorEngine (proactive notifications) and PredictionEngine
  // (proactive solutions attached to each forecast).
  sl.registerLazySingleton(() => MessageEngine());

  // Behavior Engine — the local rule-based intelligence core. Depends
  // only on repository interfaces, so it is fully unit-testable with
  // fakes and has zero Flutter/UI coupling.
  sl.registerLazySingleton(() => BehaviorEngine(
        scheduleRepository: sl(),
        profileRepository: sl(),
        habitRepository: sl(),
        messageEngine: sl(),
      ));

  // Prediction Engine — forward-looking probabilities (today's
  // outcome, habit-drop risk, return-after-absence, fatigue, burnout)
  // plus proactive solutions, all derived from BehaviorEngine's
  // primitives. Zero network, zero external AI.
  sl.registerLazySingleton(() => PredictionEngine(
        behaviorEngine: sl(),
        profileRepository: sl(),
        habitRepository: sl(),
        messageEngine: sl(),
      ));

  // Behavior Memory — periodic checkpoints + past-vs-present
  // comparison ("قبل شهر / ستة أشهر / سنة").
  sl.registerLazySingleton(() => BehaviorMemoryEngine(
        scheduleRepository: sl(),
        profileRepository: sl(),
        messageEngine: sl(),
      ));

  // Notification Intelligence — the real on-device delivery channel.
  // NotificationService wraps flutter_local_notifications/
  // permission_handler/timezone; bound against the domain-layer
  // NotificationDispatcher interface so the engine above it stays
  // Flutter-free and testable.
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<NotificationDispatcher>(() => sl<NotificationService>());
  sl.registerLazySingleton(() => NotificationIntelligenceEngine(
        profileRepository: sl(),
        behaviorEngine: sl(),
        predictionEngine: sl(),
        memoryEngine: sl(),
        dispatcher: sl(),
        messageEngine: sl(),
      ));

  // View models (MVVM) — factories so each screen gets a fresh instance
  sl.registerFactory(() => TaskViewModel(
        taskRepository: sl(),
        createTaskUseCase: sl(),
        postponeTaskUseCase: sl(),
        decomposeTaskUseCase: sl(),
      ));
  sl.registerFactory(() => HabitViewModel(
        habitRepository: sl(),
        logHabitUseCase: sl(),
      ));
  sl.registerFactory(() => ScheduleViewModel(
        scheduleRepository: sl(),
        behaviorEngine: sl(),
      ));
  sl.registerFactory(() => BehaviorViewModel(behaviorEngine: sl()));
  sl.registerFactory(() => PredictionViewModel(predictionEngine: sl()));
  sl.registerFactory(() => MemoryViewModel(memoryEngine: sl()));
}
