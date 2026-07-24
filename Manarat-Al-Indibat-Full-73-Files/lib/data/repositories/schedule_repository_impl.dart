import "package:dartz/dartz.dart";
import "../../core/utils/day_key.dart";
import "../../domain/entities/scheduled_task_entity.dart";
import "../../domain/entities/task_log_entry.dart";
import "../../domain/entities/day_stat.dart";
import "../../domain/repositories/schedule_repository.dart";
import "../../domain/repositories/task_repository.dart" show Failure;
import "../datasources/local/schedule_local_datasource.dart";
import "../models/scheduled_task_model.dart";
import "../models/task_log_entry_model.dart";

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleLocalDataSource localDataSource;
  const ScheduleRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<ScheduledTaskEntity>>> getBaseSchedule() async {
    try {
      return Right(localDataSource.getBase().map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduledTaskEntity>>> getScheduleForDay(int weekday) async {
    try {
      return Right(
        localDataSource.getScheduleForDay(weekday).map((m) => m.toEntity()).toList(),
      );
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setBaseSchedule(List<ScheduledTaskEntity> tasks) async {
    try {
      await localDataSource.setBase(tasks.map(ScheduledTaskModel.fromEntity).toList());
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setOverrideForDay(
    int weekday,
    List<ScheduledTaskEntity> tasks,
  ) async {
    try {
      await localDataSource.setOverride(
        weekday,
        tasks.map(ScheduledTaskModel.fromEntity).toList(),
      );
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearOverrideForDay(int weekday) async {
    try {
      await localDataSource.clearOverride(weekday);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, TaskLogEntry>>> getDayLog(String dayKey) async {
    try {
      final raw = localDataSource.getDayLog(dayKey);
      return Right(raw.map((k, v) => MapEntry(k, v.toEntity())));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskLogEntry>> getTaskStatus(String dayKey, String taskId) async {
    final raw = localDataSource.getDayLog(dayKey)[taskId];
    return Right(raw?.toEntity() ?? const TaskLogEntry());
  }

  @override
  Future<Either<Failure, void>> setTaskStatus(
    String dayKey,
    String taskId,
    TaskLogEntry entry,
  ) async {
    try {
      await localDataSource.setTaskStatus(dayKey, taskId, TaskLogEntryModel.fromEntity(entry));
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Faithful port of computeStats(n): walks the last n days (including
  /// today), and for each day counts done/failed against that
  /// weekday's effective schedule size.
  @override
  Future<Either<Failure, List<DayStat>>> computeStats(int n) async {
    try {
      final days = <DayStat>[];
      final now = DateTime.now();
      for (int i = n - 1; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final key = dayKey(d);
        final log = localDataSource.getDayLog(key);
        final sched = localDataSource.getScheduleForDay(d.weekday % 7);
        int done = 0, failed = 0;
        for (final entry in log.values) {
          if (entry.statusIndex == 1) done++; // DayTaskStatus.done
          if (entry.statusIndex == 2) failed++; // DayTaskStatus.failed
        }
        days.add(DayStat(
          key: key,
          date: d,
          done: done,
          failed: failed,
          total: sched.length,
          rate: sched.isNotEmpty ? done / sched.length : 0,
        ));
      }
      return Right(days);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, Map<String, TaskLogEntry>>>> getAllLogs() async {
    try {
      final raw = localDataSource.getAllDayLogs();
      final result = <String, Map<String, TaskLogEntry>>{};
      raw.forEach((day, model) {
        result[day] = model.entries.map((k, v) => MapEntry(k, v.toEntity()));
      });
      return Right(result);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Stream<Map<String, TaskLogEntry>> watchDayLog(String dayKey) {
    return localDataSource
        .watchDayLog(dayKey)
        .map((raw) => raw.map((k, v) => MapEntry(k, v.toEntity())));
  }
}
