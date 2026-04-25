import 'package:hive/hive.dart';

part 'resident_entity.g.dart';

@HiveType(typeId: 1)
class ResidentEntity extends HiveObject {
  @HiveField(0)
  late String remoteId; // Primary key from backend

  @HiveField(1)
  late String firstName;

  @HiveField(2)
  late String lastName;

  @HiveField(3)
  late String roomNumber;

  @HiveField(4)
  late String careLevel;

  // Quick summary fields for dashboard
  @HiveField(5)
  String? lastCareLogSummary;

  @HiveField(6)
  DateTime? lastCareLogTime;
}
