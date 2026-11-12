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

  /// Persists cognitive & physical capability fields onto the resident profile.
  Future<Resident> updateCapabilities({
    required String cognitiveCapability,
    required String physicalCapability,
    String? cognitiveStage,
    List<String>? motorLimitations,
  }) async {
    final updated = state.copyWith(
      cognitiveCapability: cognitiveCapability.trim(),
      physicalCapability: physicalCapability.trim(),
      cognitiveStage: cognitiveStage,
      motorLimitations: motorLimitations ?? state.motorLimitations,
    );
    final repo = _repository;
    if (repo != null) {
      await repo.updateResident(updated);
    }
    if (mounted) {
      state = updated;
    }
    return updated;
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
