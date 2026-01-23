// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'full_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FullScheduleAdapter extends TypeAdapter<FullSchedule> {
  @override
  final int typeId = 2;

  @override
  FullSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FullSchedule(
      group: fields[0] as String,
      days: (fields[1] as List).cast<DaySchedule>(),
      lastUpdated: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FullSchedule obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.group)
      ..writeByte(1)
      ..write(obj.days)
      ..writeByte(2)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
