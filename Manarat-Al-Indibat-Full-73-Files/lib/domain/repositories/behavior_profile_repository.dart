import "../entities/behavior_profile_entity.dart";

/// Persists and streams the single behavioral profile record.
abstract class BehaviorProfileRepository {
  Future<BehaviorProfileEntity> get();
  Future<void> save(BehaviorProfileEntity profile);
  Stream<BehaviorProfileEntity> watch();
}
