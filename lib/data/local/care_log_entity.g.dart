// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_log_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CareLogEntityAdapter extends TypeAdapter<CareLogEntity> {
  @override
  final int typeId = 2;

  @override
  CareLogEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CareLogEntity()
      ..remoteId = fields[0] as String?
      ..residentId = fields[1] as String
      ..caregiverId = fields[2] as String
      ..timestamp = fields[3] as DateTime
      ..category = fields[4] as String
      ..notes = fields[5] as String
      ..isSynced = fields[6] as bool;
  }

  @override
  void write(BinaryWriter writer, CareLogEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.remoteId)
      ..writeByte(1)
      ..write(obj.residentId)
      ..writeByte(2)
      ..write(obj.caregiverId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareLogEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
