// GENERATED-STYLE ADAPTERS — hand-written, see task_model.g.dart header.
part of "habit_model.dart";

class HabitLogModelAdapter extends TypeAdapter<HabitLogModel> {
  @override
  final int typeId = 2;

  @override
  HabitLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLogModel(
      date: fields[0] as DateTime,
      success: fields[1] as bool,
      triggerNote: fields[2] as String?,
      hourOfDay: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLogModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.success)
      ..writeByte(2)
      ..write(obj.triggerNote)
      ..writeByte(3)
      ..write(obj.hourOfDay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 1;

  @override
  HabitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      typeIndex: fields[3] as int,
      difficultyIndex: fields[4] as int,
      reminderTime: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      logs: (fields[7] as List).cast<HabitLogModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.difficultyIndex)
      ..writeByte(5)
      ..write(obj.reminderTime)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.logs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
