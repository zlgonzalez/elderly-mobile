import 'package:hive/hive.dart';

part 'care_log_entity.g.dart';

@HiveType(typeId: 2)
class CareLogEntity extends HiveObject {
  @HiveField(0)
  String? remoteId; // null if not yet synced

  @HiveField(1)
  late String residentId; // Matches ResidentEntity.remoteId

  @HiveField(2)
  late String caregiverId; // Matches UserEntity.remoteId

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  late String category; // e.g. "Meaningful Work", "Medical"

  @HiveField(5)
  late String notes;

  @HiveField(6)
  bool isSynced = false;
}
