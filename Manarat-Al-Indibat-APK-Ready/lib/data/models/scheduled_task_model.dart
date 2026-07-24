import "package:hive/hive.dart";
import "../../domain/entities/scheduled_task_entity.dart";

part "scheduled_task_model.g.dart";

@HiveType(typeId: 3)
class ScheduledTaskModel {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  int hour;
  @HiveField(3)
  int priorityIndex;
  @HiveField(4)
  String note;
  @HiveField(5)
  String category;

  ScheduledTaskModel({
    required this.id,
    required this.title,
    required this.hour,
    required this.priorityIndex,
    required this.note,
    required this.category,
  });

  factory ScheduledTaskModel.fromEntity(ScheduledTaskEntity e) => ScheduledTaskModel(
        id: e.id,
        title: e.title,
        hour: e.hour,
        priorityIndex: e.priority.index,
        note: e.note,
        category: e.category,
      );

  ScheduledTaskEntity toEntity() => ScheduledTaskEntity(
        id: id,
        title: title,
        hour: hour,
        priority: SchedPriority.values[priorityIndex],
        note: note,
        category: category,
      );
}
