import "package:flutter/foundation.dart";
import "dart:async";
import "../../domain/entities/task_entity.dart";
import "../../domain/repositories/task_repository.dart";
import "../../domain/usecases/task/create_task_usecase.dart";
import "../../domain/usecases/task/postpone_task_usecase.dart";
import "../../domain/usecases/task/decompose_task_usecase.dart";

/// MVVM ViewModel: exposes state + intents to the Tasks screen, holds
/// no Flutter widget references, and talks only to use cases/repos.
class TaskViewModel extends ChangeNotifier {
  final TaskRepository taskRepository;
  final CreateTaskUseCase createTaskUseCase;
  final PostponeTaskUseCase postponeTaskUseCase;
  final DecomposeTaskUseCase decomposeTaskUseCase;

  TaskViewModel({
    required this.taskRepository,
    required this.createTaskUseCase,
    required this.postponeTaskUseCase,
    required this.decomposeTaskUseCase,
  }) {
    _subscribe();
  }

  List<TaskEntity> tasks = [];
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription? _sub;

  void _subscribe() {
    _sub = taskRepository.watchAllTasks().listen((updated) {
      tasks = updated;
      isLoading = false;
      notifyListeners();
    });
  }

  List<TaskEntity> get pendingTasks =>
      tasks.where((t) => t.status == TaskStatus.pending).toList();

  List<TaskEntity> get completedTasks =>
      tasks.where((t) => t.status == TaskStatus.completed).toList();

  double get todayCompletionRate {
    final today = tasks.where((t) {
      if (t.deadline == null) return false;
      final now = DateTime.now();
      return t.deadline!.year == now.year &&
          t.deadline!.month == now.month &&
          t.deadline!.day == now.day;
    }).toList();
    if (today.isEmpty) return 0;
    final done = today.where((t) => t.status == TaskStatus.completed).length;
    return done / today.length;
  }

  Future<void> addTask({
    required String title,
    String? notes,
    String category = "عام",
    TaskPriority priority = TaskPriority.medium,
    TaskRecurrence recurrence = TaskRecurrence.none,
    DateTime? deadline,
  }) async {
    final result = await createTaskUseCase(
      title: title,
      notes: notes,
      category: category,
      priority: priority,
      recurrence: recurrence,
      deadline: deadline,
    );
    result.fold(
      (failure) => errorMessage = failure.message,
      (_) => errorMessage = null,
    );
    notifyListeners();
  }

  Future<void> completeTask(String id) async {
    await taskRepository.markCompleted(id);
  }

  Future<void> postponeTask(String id, DateTime newDeadline) async {
    await postponeTaskUseCase(id, newDeadline);
  }

  Future<void> deleteTask(String id) async {
    await taskRepository.deleteTask(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
