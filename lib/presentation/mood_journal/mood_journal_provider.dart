import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/mood_repository.dart';
import '../../domain/entities/mood_entry.dart';
import '../family_portal/resident_provider.dart';

class MoodJournalState {
  final List<MoodEntry> moods;
  final bool isLoading;

  const MoodJournalState({
    this.moods = const [],
    this.isLoading = false,
  });

  MoodEntry? get latest => moods.isNotEmpty ? moods.first : null;

  MoodJournalState copyWith({
    List<MoodEntry>? moods,
    bool? isLoading,
  }) {
    return MoodJournalState(
      moods: moods ?? this.moods,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MoodJournalNotifier extends StateNotifier<MoodJournalState> {
  final MoodRepository _repository;
  final String _residentId;

  MoodJournalNotifier({
    required MoodRepository repository,
    required String residentId,
  })  : _repository = repository,
        _residentId = residentId,
        super(const MoodJournalState(isLoading: true)) {
    loadMoods();
  }

  Future<void> loadMoods() async {
    state = state.copyWith(isLoading: true);
    final items = await _repository.getMoods(_residentId);
    state = state.copyWith(moods: items, isLoading: false);
  }

  Future<void> logMood(MoodEntry mood) async {
    final created = await _repository.logMood(_residentId, mood);
    state = state.copyWith(moods: [created, ...state.moods]);
  }
}

final moodJournalProvider = StateNotifierProvider<MoodJournalNotifier, MoodJournalState>((ref) {
  final repo = ref.watch(moodRepositoryProvider);
  final resident = ref.watch(residentProvider);
  return MoodJournalNotifier(repository: repo, residentId: resident.id);
});
