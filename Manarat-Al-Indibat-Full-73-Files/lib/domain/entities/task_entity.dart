import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high, critical }

enum TaskRecurrence { none, daily, weekly, monthly }

enum TaskStatus { pending, inProgress, completed, postponed, missed }

/// Pure domain representation of a task. No Hive/persistence annotations
/// here — that lives in the data layer's TaskModel, keeping domain logic
/// framework-agnostic per Clean Architecture.
class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String? notes;
  final String category;
  final TaskPriority priority;
  final TaskRecurrence recurrence;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? deadline;
  final DateTime? completedAt;
  final int postponeCount;
  final List<TaskEntity> subSteps;
  final String? parentId;

  const TaskEntity({
    required this.id,
    required this.title,
    this.notes,
    this.category = 'عام',
    this.priority = TaskPriority.medium,
    this.recurrence = TaskRecurrence.none,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.deadline,
    this.completedAt,
    this.postponeCount = 0,
    this.subSteps = const [],
    this.parentId,
  });

  bool get isOverdue =>
      deadline != null &&
      status != TaskStatus.completed &&
      DateTime.now().isAfter(deadline!);

  /// Behavior Engine signal: repeated postponement suggests the task
  /// should be auto-decomposed into smaller steps.
  bool get shouldSuggestDecomposition => postponeCount >= 3 && subSteps.isEmpty;

  TaskEntity copyWith({
    String? title,
    String? notes,
    String? category,
    TaskPriority? priority,
    TaskRecurrence? recurrence,
    TaskStatus? status,
    DateTime? deadline,
    DateTime? completedAt,
    int? postponeCount,
    List<TaskEntity>? subSteps,
  }) {
    return TaskEntity(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      status: status ?? this.status,
      createdAt: createdAt,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      postponeCount: postponeCount ?? this.postponeCount,
      subSteps: subSteps ?? this.subSteps,
      parentId: parentId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        notes,
        category,
        priority,
        recurrence,
        status,
        createdAt,
        deadline,
        completedAt,
        postponeCount,
        subSteps,
        parentId,
      ];
}
