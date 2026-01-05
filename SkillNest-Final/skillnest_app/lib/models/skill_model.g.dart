// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SkillModelAdapter extends TypeAdapter<SkillModel> {
  @override
  final int typeId = 1;

  @override
  SkillModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SkillModel(
      name: fields[0] as String,
      category: fields[1] as String,
      description: fields[2] as String,
      progress: fields[3] as int,
      deadline: fields[4] as DateTime,
      totalTasks: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SkillModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.progress)
      ..writeByte(4)
      ..write(obj.deadline)
      ..writeByte(5)
      ..write(obj.totalTasks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
