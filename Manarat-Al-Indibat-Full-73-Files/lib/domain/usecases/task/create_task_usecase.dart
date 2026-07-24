import "package:dartz/dartz.dart";
import "package:uuid/uuid.dart";
import "../../entities/task_entity.dart";
import "../../repositories/task_repository.dart";

/// Encapsulates the rule: new tasks are created with status=pending
/// and a generated id, regardless of who calls it (UI, quick-add
/// widget, or a future voice-input feature).
class CreateTaskUseCase {
  final TaskRepository repository;
  const CreateTaskUseCase(this.repository);

  Future<Either<Failure, TaskEntity>> call({
    required String title,
    String? notes,
    String category = "عام",
    TaskPriority priority = TaskPriority.medium,
    TaskRecurrence recurrence = TaskRecurrence.none,
    DateTime? deadline,
  }) {
    final task = TaskEntity(
      id: const Uuid().v4(),
      title: title,
      notes: notes,
      category: category,
      priority: priority,
      recurrence: recurrence,
      createdAt: DateTime.now(),
      deadline: deadline,
    );
    return repository.createTask(task);
  }
}
