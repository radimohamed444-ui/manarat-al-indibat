import "package:hive/hive.dart";
import "../../models/task_model.dart";
import "../../../core/constants/app_constants.dart";

/// Thin wrapper around the Hive box. Keeping this separate from the
/// repository implementation makes it trivial to add a remote/cache
/// data source later without touching TaskRepositoryImpl's logic.
class TaskLocalDataSource {
  Box<TaskModel> get _box => Hive.box<TaskModel>(AppConstants.boxTasks);

  List<TaskModel> getAll() => _box.values.toList();

  TaskModel? getById(String id) =>
      _box.values.where((t) => t.id == id).cast<TaskModel?>().firstOrNull;

  Future<void> put(TaskModel model) => _box.put(model.id, model);

  Future<void> delete(String id) => _box.delete(id);

  Stream<List<TaskModel>> watchAll() async* {
    yield _box.values.toList(); // emit current state immediately
    yield* _box.watch().map((_) => _box.values.toList());
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
