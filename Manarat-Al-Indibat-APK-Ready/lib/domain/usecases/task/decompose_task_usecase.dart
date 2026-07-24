import "package:dartz/dartz.dart";
import "package:uuid/uuid.dart";
import "../../entities/task_entity.dart";
import "../../repositories/task_repository.dart";

/// Splits a large or repeatedly-postponed task into smaller sub-steps.
class DecomposeTaskUseCase {
  final TaskRepository repository;
  const DecomposeTaskUseCase(this.repository);

  Future<Either<Failure, TaskEntity>> call(
    TaskEntity parent,
    List<String> stepTitles,
  ) async {
    final subSteps = stepTitles
        .map((title) => TaskEntity(
              id: const Uuid().v4(),
              title: title,
              category: parent.category,
              priority: parent.priority,
              createdAt: DateTime.now(),
              deadline: parent.deadline,
              parentId: parent.id,
            ))
        .toList();
    final updated = parent.copyWith(subSteps: subSteps);
    return repository.updateTask(updated);
  }
}
