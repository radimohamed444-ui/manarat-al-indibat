import "package:flutter/foundation.dart";
import "dart:async";
import "../../domain/entities/habit_entity.dart";
import "../../domain/repositories/habit_repository.dart";
import "../../domain/usecases/habit/log_habit_usecase.dart";

class HabitViewModel extends ChangeNotifier {
  final HabitRepository habitRepository;
  final LogHabitUseCase logHabitUseCase;

  HabitViewModel({
    required this.habitRepository,
    required this.logHabitUseCase,
  }) {
    _subscribe();
  }

  List<HabitEntity> habits = [];
  bool isLoading = true;
  StreamSubscription? _sub;

  void _subscribe() {
    _sub = habitRepository.watchAllHabits().listen((updated) {
      habits = updated;
      isLoading = false;
      notifyListeners();
    });
  }

  List<HabitEntity> get positiveHabits =>
      habits.where((h) => h.type == HabitType.positive).toList();

  List<HabitEntity> get negativeHabits =>
      habits.where((h) => h.type == HabitType.negative).toList();

  Future<void> createHabit(HabitEntity habit) async {
    await habitRepository.createHabit(habit);
  }

  Future<void> logToday(String habitId, bool success, {String? triggerNote}) async {
    await logHabitUseCase(
      habitId: habitId,
      success: success,
      triggerNote: triggerNote,
    );
  }

  Future<void> deleteHabit(String id) async {
    await habitRepository.deleteHabit(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
