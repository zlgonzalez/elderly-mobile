import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/resident.dart';
import '../../data/fixtures/resident_fixtures.dart';
import '../../data/repositories/resident_repository.dart';

class ResidentNotifier extends StateNotifier<Resident> {
  static String _lastSelectedResidentId = ResidentFixtures.margaretThompson.id;

  final ResidentRepository? _repository;

  ResidentNotifier([dynamic firstParam, Resident? initialResident])
      : _repository = firstParam is ResidentRepository ? firstParam : null,
        super(firstParam is Resident
            ? firstParam
            : (initialResident ??
                ResidentFixtures.findById(_lastSelectedResidentId)));

  void selectResident(Resident resident) {
    final normalizedId = ResidentFixtures.toFixtureId(resident.id);
    _lastSelectedResidentId = normalizedId;
    state = resident.copyWith(id: normalizedId);
  }

  Future<void> selectById(String id) async {
    final normalizedId = ResidentFixtures.toFixtureId(id);
    _lastSelectedResidentId = normalizedId;
    if (mounted) {
      state = ResidentFixtures.findById(normalizedId);
    }
    final repo = _repository;
    if (repo != null) {
      try {
        final resident = await repo.getResident(normalizedId);
        if (resident != null && mounted && _lastSelectedResidentId == normalizedId) {
          state = resident.copyWith(id: normalizedId);
          return;
        }
      } catch (_) {}
    }
  }

  /// Refreshes the currently active resident in-place from the active repository.
  Future<void> refreshCurrentResident() async {
    await selectById(state.id);
  }

  void resetToDemo() {
    _lastSelectedResidentId = ResidentFixtures.margaretThompson.id;
    state = ResidentFixtures.margaretThompson;
  }
}

final residentProvider =
    StateNotifierProvider<ResidentNotifier, Resident>((ref) {
  final repo = ref.watch(residentRepositoryProvider);
  return ResidentNotifier(repo);
});
