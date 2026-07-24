import 'package:dartz/dartz.dart';
import '../entities/scheduled_task_entity.dart';
import '../entities/task_log_entry.dart';
import '../entities/day_stat.dart';
import 'task_repository.dart' show Failure;

/// Contract for the daily recurring schedule system — ported from the
/// HTML app's `S.sched` (base + weekday overrides) and `S.log`
/// (per-day, per-task execution records). This is the real "tasks"
/// system of منارة الانضباط: fixed-hour daily items, not a generic
/// to-do list.
abstract class ScheduleRepository {
  /// The default/base schedule, used on any weekday without an override.
  Future<Either<Failure, List<ScheduledTaskEntity>>> getBaseSchedule();

  /// Returns the override list for [weekday] (0=Sunday..6=Saturday) if
  /// one exists and is non-empty, otherwise the base schedule —
  /// mirrors `getSchedForDay()`.
  Future<Either<Failure, List<ScheduledTaskEntity>>> getScheduleForDay(int weekday);

  Future<Either<Failure, void>> setBaseSchedule(List<ScheduledTaskEntity> tasks);
  Future<Either<Failure, void>> setOverrideForDay(int weekday, List<ScheduledTaskEntity> tasks);
  Future<Either<Failure, void>> clearOverrideForDay(int weekday);

  /// Full day log for [dayKey] (yyyy-MM-dd), taskId -> TaskLogEntry.
  Future<Either<Failure, Map<String, TaskLogEntry>>> getDayLog(String dayKey);

  Future<Either<Failure, TaskLogEntry>> getTaskStatus(String dayKey, String taskId);
  Future<Either<Failure, void>> setTaskStatus(String dayKey, String taskId, TaskLogEntry entry);

  /// Aggregate stats for the last [n] days — ported from computeStats().
  Future<Either<Failure, List<DayStat>>> computeStats(int n);

  /// All day logs ever recorded, dayKey -> (taskId -> entry). Needed by
  /// the Behavior Engine for full-history pattern scans (weekly mirror,
  /// identity lock) without re-fetching day by day.
  Future<Either<Failure, Map<String, Map<String, TaskLogEntry>>>> getAllLogs();

  Stream<Map<String, TaskLogEntry>> watchDayLog(String dayKey);
}
