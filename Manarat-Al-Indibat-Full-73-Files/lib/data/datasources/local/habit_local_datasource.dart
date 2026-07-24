import "package:hive/hive.dart";
import "../../models/habit_model.dart";
import "../../../core/constants/app_constants.dart";

class HabitLocalDataSource {
  Box<HabitModel> get _box => Hive.box<HabitModel>(AppConstants.boxHabits);

  List<HabitModel> getAll() => _box.values.toList();

  Future<void> put(HabitModel model) => _box.put(model.id, model);

  Future<void> delete(String id) => _box.delete(id);

  Stream<List<HabitModel>> watchAll() async* {
    yield _box.values.toList();
    yield* _box.watch().map((_) => _box.values.toList());
  }
}
