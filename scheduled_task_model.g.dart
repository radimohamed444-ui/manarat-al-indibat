// Hand-written Hive adapter (no pub.dev access in the build sandbox).
// Regenerate with build_runner if fields change.
part of "scheduled_task_model.dart";

class ScheduledTaskModelAdapter extends TypeAdapter<ScheduledTaskModel> {
  @override
  final int typeId = 3;

  @override
  ScheduledTaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduledTaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      hour: fields[2] as int,
      priorityIndex: fields[3] as int,
      note: fields[4] as String,
      category: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledTaskModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.priorityIndex)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledTaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
