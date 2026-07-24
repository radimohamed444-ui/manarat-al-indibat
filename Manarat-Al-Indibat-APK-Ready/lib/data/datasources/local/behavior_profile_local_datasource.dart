import "package:hive/hive.dart";
import "../../models/behavior_profile_model.dart";
import "../../../core/constants/app_constants.dart";

/// Single-record store — mirrors the fact that S.profile is one object
/// per device, not a collection.
class BehaviorProfileLocalDataSource {
  static const _key = "profile";

  Box<BehaviorProfileModel> get _box =>
      Hive.box<BehaviorProfileModel>(AppConstants.boxBehaviorProfile);

  BehaviorProfileModel get() => _box.get(_key) ?? BehaviorProfileModel();

  Future<void> put(BehaviorProfileModel model) => _box.put(_key, model);

  Stream<BehaviorProfileModel> watch() async* {
    yield get();
    yield* _box.watch(key: _key).map((_) => get());
  }
}
