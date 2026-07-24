import "package:dartz/dartz.dart";
import "../../entities/habit_entity.dart";
import "../../repositories/habit_repository.dart";
import "../../repositories/task_repository.dart" show Failure;

/// Records a single day's outcome for a habit. For negative habits,
/// "success" means the user avoided the behavior; a failure can carry
/// a trigger note and hour-of-day, which the Behavior Engine later
/// mines to find patterns (see HabitEntity.mostFrequentTriggerHour).
class LogHabitUseCase {
  final HabitRepository repository;
  const LogHabitUseCase(this.repository);

  Future<Either<Failure, HabitEntity>> call({
    required String habitId,
    required bool success,
    String? triggerNote,
  }) {
    final log = HabitLogEntity(
      date: DateTime.now(),
      success: success,
      triggerNote: triggerNote,
      hourOfDay: DateTime.now().hour,
    );
    return repository.logHabit(habitId, log);
  }
}
