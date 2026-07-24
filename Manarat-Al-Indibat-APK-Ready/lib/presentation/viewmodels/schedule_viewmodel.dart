import "package:flutter/foundation.dart";
import "dart:async";
import "package:uuid/uuid.dart";
import "../../domain/entities/scheduled_task_entity.dart";
import "../../domain/entities/task_log_entry.dart";
import "../../domain/repositories/schedule_repository.dart";
import "../../domain/services/behavior_engine.dart";
import "../../core/utils/day_key.dart";

/// Drives the Today screen — today's effective schedule (base or
/// weekday override) joined with today's log, plus complete/fail/skip
/// actions that also feed the Behavior Engine's XP/streak bookkeeping.
class ScheduleViewModel extends ChangeNotifier {
  final ScheduleRepository scheduleRepository;
  final BehaviorEngine behaviorEngine;

  ScheduleViewModel({required this.scheduleRepository, required this.behaviorEngine}) {
    _load();
    _touchOnOpen();
  }

  List<ScheduledTaskEntity> todaySchedule = [];
  Map<String, TaskLogEntry> todayLog = {};
  bool isLoading = true;
  StreamSubscription? _sub;

  String get _todayKey => dayKey();

  Future<void> _load() async {
    final weekday = jsWeekday(DateTime.now());
    final schedResult = await scheduleRepository.getScheduleForDay(weekday);
    todaySchedule = schedResult.fold((_) => [], (s) => s);
    await _sub?.cancel();
    _sub = scheduleRepository.watchDayLog(_todayKey).listen((log) {
      todayLog = log;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _touchOnOpen() async {
    await behaviorEngine.recordOpenEvent();
    await behaviorEngine.touchStreak();
  }

  TaskLogEntry statusFor(String taskId) => todayLog[taskId] ?? const TaskLogEntry();

  double get completionRate {
    if (todaySchedule.isEmpty) return 0;
    final done = todaySchedule.where((t) => statusFor(t.id).status == DayTaskStatus.done).length;
    return done / todaySchedule.length;
  }

  Future<void> completeTask(ScheduledTaskEntity task, {bool perfect = false}) async {
    final entry = TaskLogEntry(status: DayTaskStatus.done, completedAt: DateTime.now());
    await scheduleRepository.setTaskStatus(_todayKey, task.id, entry);
    await behaviorEngine.registerCompletion(task, perfect: perfect);
  }

  Future<void> failTask(ScheduledTaskEntity task, {String kind = "normal"}) async {
    final entry = TaskLogEntry(status: DayTaskStatus.failed, failedAt: DateTime.now());
    await scheduleRepository.setTaskStatus(_todayKey, task.id, entry);
    await behaviorEngine.registerFail(kind);
  }

  Future<void> skipTask(ScheduledTaskEntity task) async {
    final entry = TaskLogEntry(status: DayTaskStatus.skipped);
    await scheduleRepository.setTaskStatus(_todayKey, task.id, entry);
  }

  Future<void> addTask({
    required String title,
    required int hour,
    SchedPriority priority = SchedPriority.medium,
    String note = "",
    String category = "عام",
  }) async {
    final task = ScheduledTaskEntity(
      id: const Uuid().v4(),
      title: title,
      hour: hour,
      priority: priority,
      note: note,
      category: category,
    );
    final base = await scheduleRepository.getBaseSchedule();
    final list = base.fold((_) => <ScheduledTaskEntity>[], (s) => s);
    await scheduleRepository.setBaseSchedule([...list, task]);
    await _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
