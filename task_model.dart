import "package:hive/hive.dart";
import "../../domain/entities/task_entity.dart";

part "task_model.g.dart";

/// Hive persistence model. Kept separate from TaskEntity so the domain
/// layer never depends on a storage annotation -- if we swap Hive for
/// Isar or SQLite later, only this file and task_repository_impl.dart
/// need to change.
@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String? notes;
  @HiveField(3)
  String category;
  @HiveField(4)
  int priorityIndex;
  @HiveField(5)
  int recurrenceIndex;
  @HiveField(6)
  int statusIndex;
  @HiveField(7)
  DateTime createdAt;
  @HiveField(8)
  DateTime? deadline;
  @HiveField(9)
  DateTime? completedAt;
  @HiveField(10)
  int postponeCount;
  @HiveField(11)
  String? parentId;

  TaskModel({
    required this.id,
    required this.title,
    this.notes,
    required this.category,
    required this.priorityIndex,
    required this.recurrenceIndex,
    required this.statusIndex,
    required this.createdAt,
    this.deadline,
    this.completedAt,
    required this.postponeCount,
    this.parentId,
  });

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
        id: e.id,
        title: e.title,
        notes: e.notes,
        category: e.category,
        priorityIndex: e.priority.index,
        recurrenceIndex: e.recurrence.index,
        statusIndex: e.status.index,
        createdAt: e.createdAt,
        deadline: e.deadline,
        completedAt: e.completedAt,
        postponeCount: e.postponeCount,
        parentId: e.parentId,
      );

  TaskEntity toEntity({List<TaskEntity> subSteps = const []}) => TaskEntity(
        id: id,
        title: title,
        notes: notes,
        category: category,
        priority: TaskPriority.values[priorityIndex],
        recurrence: TaskRecurrence.values[recurrenceIndex],
        status: TaskStatus.values[statusIndex],
        createdAt: createdAt,
        deadline: deadline,
        completedAt: completedAt,
        postponeCount: postponeCount,
        subSteps: subSteps,
        parentId: parentId,
      );
}
