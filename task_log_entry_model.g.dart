part of "task_log_entry_model.dart";

class TaskLogEntryModelAdapter extends TypeAdapter<TaskLogEntryModel> {
  @override
  final int typeId = 4;

  @override
  TaskLogEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskLogEntryModel(
      statusIndex: fields[0] as int,
      startedAt: fields[1] as DateTime?,
      completedAt: fields[2] as DateTime?,
      escapeAttempts: fields[3] as int,
      failedAt: fields[4] as DateTime?,
      plannedDurationSec: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskLogEntryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.statusIndex)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.completedAt)
      ..writeByte(3)
      ..write(obj.escapeAttempts)
      ..writeByte(4)
      ..write(obj.failedAt)
      ..writeByte(5)
      ..write(obj.plannedDurationSec);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskLogEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DayLogModelAdapter extends TypeAdapter<DayLogModel> {
  @override
  final int typeId = 5;

  @override
  DayLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayLogModel(
      dayKey: fields[0] as String,
      entries: (fields[1] as Map).cast<String, TaskLogEntryModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, DayLogModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dayKey)
      ..writeByte(1)
      ..write(obj.entries);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
