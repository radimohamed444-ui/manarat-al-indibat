import "package:equatable/equatable.dart";

enum DayTaskStatus { pending, done, failed, skipped }

/// One day's execution record for a scheduled task. Ported 1:1 from
/// the HTML app's `getTS()` shape: {status, startedAt, completedAt,
/// escapeAttempts, failedAt, plannedDuration}. Stored per (dayKey,
/// taskId) pair, exactly mirroring `S.log[dayKey][taskId]`.
class TaskLogEntry extends Equatable {
  final DayTaskStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int escapeAttempts;
  final DateTime? failedAt;
  final int? plannedDurationSec;

  const TaskLogEntry({
    this.status = DayTaskStatus.pending,
    this.startedAt,
    this.completedAt,
    this.escapeAttempts = 0,
    this.failedAt,
    this.plannedDurationSec,
  });

  TaskLogEntry copyWith({
    DayTaskStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? escapeAttempts,
    DateTime? failedAt,
    int? plannedDurationSec,
  }) {
    return TaskLogEntry(
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      escapeAttempts: escapeAttempts ?? this.escapeAttempts,
      failedAt: failedAt ?? this.failedAt,
      plannedDurationSec: plannedDurationSec ?? this.plannedDurationSec,
    );
  }

  @override
  List<Object?> get props =>
      [status, startedAt, completedAt, escapeAttempts, failedAt, plannedDurationSec];
}
