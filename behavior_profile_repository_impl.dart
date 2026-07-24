import "../../domain/entities/behavior_profile_entity.dart";
import "../../domain/repositories/behavior_profile_repository.dart";
import "../datasources/local/behavior_profile_local_datasource.dart";
import "../models/behavior_profile_mapper.dart";

class BehaviorProfileRepositoryImpl implements BehaviorProfileRepository {
  final BehaviorProfileLocalDataSource localDataSource;
  const BehaviorProfileRepositoryImpl(this.localDataSource);

  @override
  Future<BehaviorProfileEntity> get() async => localDataSource.get().toEntity();

  @override
  Future<void> save(BehaviorProfileEntity profile) async {
    await localDataSource.put(profile.toModel());
  }

  @override
  Stream<BehaviorProfileEntity> watch() => localDataSource.watch().map((m) => m.toEntity());
}
