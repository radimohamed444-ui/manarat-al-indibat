import 'package:dartz/dartz.dart';
import '../entities/task_entity.dart';

class Failure {
  final String message;
  const Failure(this.message);
}

/// Abstract contract. The presentation layer depends only on this
/// interface; lib/data/repositories/task_repository_impl.dart provides
/// the concrete Hive-backed implementation. This inversion is what lets
/// the storage engine be swapped later (e.g. Hive -> Isar) without
/// touching any UI or use-case code.
abstract class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getAllTasks();
  Future<Either<Failure, List<TaskEntity>>> getTasksForDate(DateTime date);
  Future<Either<Failure, TaskEntity>> getTaskById(String id);
  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task);
  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task);
  Future<Either<Failure, void>> deleteTask(String id);
  Future<Either<Failure, TaskEntity>> markCompleted(String id);
  Future<Either<Failure, TaskEntity>> postpone(String id, DateTime newDeadline);
  Stream<List<TaskEntity>> watchAllTasks();
}
