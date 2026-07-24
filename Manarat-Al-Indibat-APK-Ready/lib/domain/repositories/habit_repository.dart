import 'package:dartz/dartz.dart';
import '../entities/habit_entity.dart';
import 'task_repository.dart' show Failure;

abstract class HabitRepository {
  Future<Either<Failure, List<HabitEntity>>> getAllHabits();
  Future<Either<Failure, HabitEntity>> createHabit(HabitEntity habit);
  Future<Either<Failure, HabitEntity>> updateHabit(HabitEntity habit);
  Future<Either<Failure, void>> deleteHabit(String id);
  Future<Either<Failure, HabitEntity>> logHabit(
    String habitId,
    HabitLogEntity log,
  );
  Stream<List<HabitEntity>> watchAllHabits();
}
