import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/resident.dart';
import '../../data/fixtures/resident_fixtures.dart';
import '../../data/repositories/resident_repository.dart';

class ResidentNotifier extends StateNotifier<Resident> {
  final ResidentRepository? _repository;

  ResidentNotifier([dynamic firstParam, Resident? initialResident])
      : _repository = firstParam is ResidentRepository ? firstParam : null,
        super(firstParam is Resident
            ? firstParam
            : (initialResident ?? ResidentFixtures.margaretThompson));

  void selectResident(Resident resident) {
    state = resident;
  }

  Future<void> selectById(String id) async {
    final repo = _repository;
    if (repo != null) {
      try {
        final resident = await repo.getResident(id);
        if (resident != null) {
          state = resident;
          return;
        }
      } catch (_) {}
    }
    state = ResidentFixtures.findById(id);
  }

  void resetToDemo() {
    state = ResidentFixtures.margaretThompson;
  }
}

final residentProvider = StateNotifierProvider<ResidentNotifier, Resident>((ref) {
  final repo = ref.watch(residentRepositoryProvider);
  return ResidentNotifier(repo);
});
