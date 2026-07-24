import "package:dartz/dartz.dart";
import "../../domain/entities/habit_entity.dart";
import "../../domain/repositories/habit_repository.dart";
import "../../domain/repositories/task_repository.dart" show Failure;
import "../datasources/local/habit_local_datasource.dart";
import "../models/habit_model.dart";

class HabitRepositoryImpl implements HabitRepository {
  final HabitLocalDataSource localDataSource;
  const HabitRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<HabitEntity>>> getAllHabits() async {
    try {
      final entities = localDataSource.getAll().map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HabitEntity>> createHabit(HabitEntity habit) async {
    try {
      await localDataSource.put(HabitModel.fromEntity(habit));
      return Right(habit);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HabitEntity>> updateHabit(HabitEntity habit) async {
    try {
      await localDataSource.put(HabitModel.fromEntity(habit));
      return Right(habit);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHabit(String id) async {
    try {
      await localDataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HabitEntity>> logHabit(
    String habitId,
    HabitLogEntity log,
  ) async {
    final models = localDataSource.getAll();
    final model = models.where((m) => m.id == habitId).firstOrNull;
    if (model == null) return const Left(Failure("Habit not found"));
    model.logs.add(HabitLogModel.fromEntity(log));
    await localDataSource.put(model);
    return Right(model.toEntity());
  }

  @override
  Stream<List<HabitEntity>> watchAllHabits() {
    return localDataSource.watchAll().map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
