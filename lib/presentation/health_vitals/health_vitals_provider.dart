import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/health_vitals_repository.dart';
import '../../domain/entities/vital_sign.dart';
import '../family_portal/resident_provider.dart';

class HealthVitalsState {
  final List<VitalSign> vitals;
  final bool isLoading;

  const HealthVitalsState({
    this.vitals = const [],
    this.isLoading = false,
  });

  VitalSign? get latest => vitals.isNotEmpty ? vitals.first : null;
  bool get hasAbnormalVital => latest?.isAbnormal ?? false;

  HealthVitalsState copyWith({
    List<VitalSign>? vitals,
    bool? isLoading,
  }) {
    return HealthVitalsState(
      vitals: vitals ?? this.vitals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HealthVitalsNotifier extends StateNotifier<HealthVitalsState> {
  final HealthVitalsRepository _repository;
  final String _residentId;

  HealthVitalsNotifier({
    required HealthVitalsRepository repository,
    required String residentId,
  })  : _repository = repository,
        _residentId = residentId,
        super(const HealthVitalsState(isLoading: true)) {
    loadVitals();
  }

  Future<void> loadVitals() async {
    state = state.copyWith(isLoading: true);
    final items = await _repository.getVitals(_residentId);
    state = state.copyWith(vitals: items, isLoading: false);
  }

  Future<void> recordVitals(VitalSign entry) async {
    final created = await _repository.recordVitals(_residentId, entry);
    state = state.copyWith(vitals: [created, ...state.vitals]);
  }
}

final healthVitalsProvider = StateNotifierProvider<HealthVitalsNotifier, HealthVitalsState>((ref) {
  final repo = ref.watch(healthVitalsRepositoryProvider);
  final resident = ref.watch(residentProvider);
  return HealthVitalsNotifier(repository: repo, residentId: resident.id);
});
