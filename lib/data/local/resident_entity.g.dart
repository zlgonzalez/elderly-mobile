// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resident_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResidentEntityAdapter extends TypeAdapter<ResidentEntity> {
  @override
  final int typeId = 1;

  @override
  ResidentEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResidentEntity()
      ..remoteId = fields[0] as String
      ..firstName = fields[1] as String
      ..lastName = fields[2] as String
      ..roomNumber = fields[3] as String
      ..careLevel = fields[4] as String
      ..lastCareLogSummary = fields[5] as String?
      ..lastCareLogTime = fields[6] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, ResidentEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.remoteId)
      ..writeByte(1)
      ..write(obj.firstName)
      ..writeByte(2)
      ..write(obj.lastName)
      ..writeByte(3)
      ..write(obj.roomNumber)
      ..writeByte(4)
      ..write(obj.careLevel)
      ..writeByte(5)
      ..write(obj.lastCareLogSummary)
      ..writeByte(6)
      ..write(obj.lastCareLogTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResidentEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
