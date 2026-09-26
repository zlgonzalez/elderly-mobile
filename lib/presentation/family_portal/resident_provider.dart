import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/resident.dart';
import '../../data/fixtures/resident_fixtures.dart';
class ResidentNotifier extends StateNotifier<Resident> {
  ResidentNotifier([Resident? initialResident]) : super(initialResident ?? ResidentFixtures.margaretThompson);

  void selectResident(Resident resident) {
    state = resident;
  }

  void selectById(String id) {
    state = ResidentFixtures.findById(id);
  }

  void resetToDemo() {
    state = ResidentFixtures.margaretThompson;
  }
}

final residentProvider = StateNotifierProvider<ResidentNotifier, Resident>((ref) {
  return ResidentNotifier();
});
