import "package:equatable/equatable.dart";

enum SchedPriority { low, medium, high }

/// A recurring daily-schedule item, ported 1:1 from the HTML app's
/// `S.sched.base` / `S.sched.overrides` task shape ({id, title, hour,
/// priority, note, cat}). This is NOT a one-off to-do: it is a template
/// that recurs every day at a fixed hour unless a weekday override
/// replaces it — the same "daily schedule" concept as the original.
class ScheduledTaskEntity extends Equatable {
  final String id;
  final String title;
  final int hour; // 0-23, the slot this task is anchored to
  final SchedPriority priority;
  final String note;
  final String category;

  const ScheduledTaskEntity({
    required this.id,
    required this.title,
    required this.hour,
    this.priority = SchedPriority.medium,
    this.note = "",
    this.category = "عام",
  });

  ScheduledTaskEntity copyWith({
    String? title,
    int? hour,
    SchedPriority? priority,
    String? note,
    String? category,
  }) {
    return ScheduledTaskEntity(
      id: id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      priority: priority ?? this.priority,
      note: note ?? this.note,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [id, title, hour, priority, note, category];
}
