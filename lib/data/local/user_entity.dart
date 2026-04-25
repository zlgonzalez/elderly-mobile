import 'package:hive/hive.dart';

part 'user_entity.g.dart';

@HiveType(typeId: 0)
class UserEntity extends HiveObject {
  @HiveField(0)
  late String remoteId; // Zitadel ID

  @HiveField(1)
  late String firstName;

  @HiveField(2)
  late String lastName;

  @HiveField(3)
  late String role; // e.g. "admin", "caregiver"

  @HiveField(4)
  late String email;
}
