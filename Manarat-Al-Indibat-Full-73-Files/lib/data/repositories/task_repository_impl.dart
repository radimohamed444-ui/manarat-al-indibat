import "package:dartz/dartz.dart";
import "../../domain/entities/task_entity.dart";
import "../../domain/repositories/task_repository.dart";
import "../datasources/local/task_local_datasource.dart";
import "../models/task_model.dart";

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  const TaskRepositoryImpl(this.localDataSource);

  List<TaskEntity> _toEntities(List<TaskModel> models) {
    final all = models.map((m) => m.toEntity()).toList();
    // attach sub-steps to their parents
    final roots = <TaskEntity>[];
    for (final t in all.where((t) => t.parentId == null)) {
      final children = all.where((c) => c.parentId == t.id).toList();
      roots.add(t.copyWith(subSteps: children));
    }
    return roots;
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getAllTasks() async {
    try {
      return Right(_toEntities(localDataSource.getAll()));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasksForDate(DateTime date) async {
    try {
      final tasks = _toEntities(localDataSource.getAll()).where((t) {
        if (t.deadline == null) return false;
        return t.deadline!.year == date.year &&
            t.deadline!.month == date.month &&
            t.deadline!.day == date.day;
      }).toList();
      return Right(tasks);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> getTaskById(String id) async {
    final model = localDataSource.getById(id);
    if (model == null) return const Left(Failure("Task not found"));
    return Right(model.toEntity());
  }

  @override
  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task) async {
    try {
      await localDataSource.put(TaskModel.fromEntity(task));
      return Right(task);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task) async {
    try {
      await localDataSource.put(TaskModel.fromEntity(task));
      for (final step in task.subSteps) {
        await localDataSource.put(TaskModel.fromEntity(step));
      }
      return Right(task);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      await localDataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> markCompleted(String id) async {
    final model = localDataSource.getById(id);
    if (model == null) return const Left(Failure("Task not found"));
    model.statusIndex = TaskStatus.completed.index;
    model.completedAt = DateTime.now();
    await localDataSource.put(model);
    return Right(model.toEntity());
  }

  @override
  Future<Either<Failure, TaskEntity>> postpone(
    String id,
    DateTime newDeadline,
  ) async {
    final model = localDataSource.getById(id);
    if (model == null) return const Left(Failure("Task not found"));
    model.statusIndex = TaskStatus.postponed.index;
    model.deadline = newDeadline;
    model.postponeCount += 1;
    await localDataSource.put(model);
    return Right(model.toEntity());
  }

  @override
  Stream<List<TaskEntity>> watchAllTasks() {
    return localDataSource.watchAll().map(_toEntities);
  }
}
