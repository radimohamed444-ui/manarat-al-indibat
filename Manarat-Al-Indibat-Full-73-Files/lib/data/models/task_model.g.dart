// GENERATED-STYLE ADAPTER — hand-written because this sandbox has no
// access to pub.dev to run build_runner. Regenerate anytime with:
//   flutter pub run build_runner build --delete-conflicting-outputs
part of "task_model.dart";

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      notes: fields[2] as String?,
      category: fields[3] as String,
      priorityIndex: fields[4] as int,
      recurrenceIndex: fields[5] as int,
      statusIndex: fields[6] as int,
      createdAt: fields[7] as DateTime,
      deadline: fields[8] as DateTime?,
      completedAt: fields[9] as DateTime?,
      postponeCount: fields[10] as int,
      parentId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.priorityIndex)
      ..writeByte(5)
      ..write(obj.recurrenceIndex)
      ..writeByte(6)
      ..write(obj.statusIndex)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.deadline)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.postponeCount)
      ..writeByte(11)
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
