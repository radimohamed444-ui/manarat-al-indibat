import "package:hive/hive.dart";
import "../../domain/entities/task_log_entry.dart";

part "task_log_entry_model.g.dart";

@HiveType(typeId: 4)
class TaskLogEntryModel {
  @HiveField(0)
  int statusIndex;
  @HiveField(1)
  DateTime? startedAt;
  @HiveField(2)
  DateTime? completedAt;
  @HiveField(3)
  int escapeAttempts;
  @HiveField(4)
  DateTime? failedAt;
  @HiveField(5)
  int? plannedDurationSec;

  TaskLogEntryModel({
    required this.statusIndex,
    this.startedAt,
    this.completedAt,
    required this.escapeAttempts,
    this.failedAt,
    this.plannedDurationSec,
  });

  factory TaskLogEntryModel.fromEntity(TaskLogEntry e) => TaskLogEntryModel(
        statusIndex: e.status.index,
        startedAt: e.startedAt,
        completedAt: e.completedAt,
        escapeAttempts: e.escapeAttempts,
        failedAt: e.failedAt,
        plannedDurationSec: e.plannedDurationSec,
      );

  TaskLogEntry toEntity() => TaskLogEntry(
        status: DayTaskStatus.values[statusIndex],
        startedAt: startedAt,
        completedAt: completedAt,
        escapeAttempts: escapeAttempts,
        failedAt: failedAt,
        plannedDurationSec: plannedDurationSec,
      );
}

/// One day's worth of task logs — taskId -> TaskLogEntryModel.
/// Stored as a single Hive value keyed by dayKey (yyyy-MM-dd), matching
/// `S.log[dayKey]` in the original, and keeping writes cheap (one box
/// entry per day instead of one per task-completion).
@HiveType(typeId: 5)
class DayLogModel {
  @HiveField(0)
  String dayKey;
  @HiveField(1)
  Map<String, TaskLogEntryModel> entries;

  DayLogModel({required this.dayKey, required this.entries});
}
