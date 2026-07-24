import "package:dartz/dartz.dart";
import "../../repositories/task_repository.dart";
import "../../entities/task_entity.dart";

/// Business rule for the Behavior Engine: postponing a task increments
/// its postpone counter. After 3 postponements TaskEntity.shouldSuggestDecomposition
/// flips true, so the UI can prompt the user to break the task into
/// smaller steps -- the concrete implementation of the spec's
/// "repeated postponement" rule.
class PostponeTaskUseCase {
  final TaskRepository repository;
  const PostponeTaskUseCase(this.repository);

  Future<Either<Failure, TaskEntity>> call(
    String taskId,
    DateTime newDeadline,
  ) {
    return repository.postpone(taskId, newDeadline);
  }
}
