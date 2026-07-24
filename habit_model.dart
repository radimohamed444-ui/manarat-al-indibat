import "package:hive/hive.dart";
import "../../domain/entities/habit_entity.dart";

part "habit_model.g.dart";

@HiveType(typeId: 2)
class HabitLogModel {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  bool success;
  @HiveField(2)
  String? triggerNote;
  @HiveField(3)
  int? hourOfDay;

  HabitLogModel({
    required this.date,
    required this.success,
    this.triggerNote,
    this.hourOfDay,
  });

  factory HabitLogModel.fromEntity(HabitLogEntity e) => HabitLogModel(
        date: e.date,
        success: e.success,
        triggerNote: e.triggerNote,
        hourOfDay: e.hourOfDay,
      );

  HabitLogEntity toEntity() => HabitLogEntity(
        date: date,
        success: success,
        triggerNote: triggerNote,
        hourOfDay: hourOfDay,
      );
}

@HiveType(typeId: 1)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String? description;
  @HiveField(3)
  int typeIndex;
  @HiveField(4)
  int difficultyIndex;
  @HiveField(5)
  String? reminderTime;
  @HiveField(6)
  DateTime createdAt;
  @HiveField(7)
  List<HabitLogModel> logs;

  HabitModel({
    required this.id,
    required this.title,
    this.description,
    required this.typeIndex,
    required this.difficultyIndex,
    this.reminderTime,
    required this.createdAt,
    required this.logs,
  });

  factory HabitModel.fromEntity(HabitEntity e) => HabitModel(
        id: e.id,
        title: e.title,
        description: e.description,
        typeIndex: e.type.index,
        difficultyIndex: e.difficulty.index,
        reminderTime: e.reminderTime,
        createdAt: e.createdAt,
        logs: e.logs.map(HabitLogModel.fromEntity).toList(),
      );

  HabitEntity toEntity() => HabitEntity(
        id: id,
        title: title,
        description: description,
        type: HabitType.values[typeIndex],
        difficulty: HabitDifficulty.values[difficultyIndex],
        reminderTime: reminderTime,
        createdAt: createdAt,
        logs: logs.map((l) => l.toEntity()).toList(),
      );
}
