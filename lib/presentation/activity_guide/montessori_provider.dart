import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/montessori_repository.dart';
import '../../domain/entities/care_task.dart';
import '../../domain/entities/montessori_activity.dart';
import '../../domain/entities/regimen_plan.dart';
import '../care_tasks/care_tasks_provider.dart';

class MontessoriState {
  final List<MontessoriActivity> allActivities;
  final List<MontessoriActivity> filteredActivities;
  final MontessoriCategory? selectedCategory;
  final String searchQuery;
  final bool isLoading;

  const MontessoriState({
    this.allActivities = const [],
    this.filteredActivities = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.isLoading = false,
  });

  int getCountForCategory(MontessoriCategory? cat) {
    if (cat == null) return allActivities.length;
    return allActivities.where((a) => a.category == cat).length;
  }

  MontessoriState copyWith({
    List<MontessoriActivity>? allActivities,
    List<MontessoriActivity>? filteredActivities,
    MontessoriCategory? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    bool? isLoading,
  }) {
    return MontessoriState(
      allActivities: allActivities ?? this.allActivities,
      filteredActivities: filteredActivities ?? this.filteredActivities,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MontessoriNotifier extends StateNotifier<MontessoriState> {
  final MontessoriRepository _repository;
  List<CareTask> _personalizedTasks = const [];
  int _loadToken = 0;

  MontessoriNotifier(this._repository, [List<CareTask>? initialTasks])
      : _personalizedTasks = initialTasks ?? const [],
        super(const MontessoriState(isLoading: true)) {
    loadActivities();
  }

  Future<void> loadActivities() async {
    final loadToken = ++_loadToken;
    state = state.copyWith(isLoading: true);
    try {
      final curated = await _repository.getActivities();
      if (!mounted || loadToken != _loadToken) return;
      final personalized = _personalizedTasks
          .where((t) =>
              t.materials.isNotEmpty ||
              t.steps.isNotEmpty ||
              (t.historicalConnection?.isNotEmpty ?? false))
          .map((t) => MontessoriActivity(
                id: 'personalized_${t.id}',
                title: t.title,
                category: MontessoriTaxonomyMapper.toMontessoriCategory(
                    t.montessoriDomain ?? t.category.displayName),
                summary: t.description,
                durationMinutes: 25,
                materials: t.materials,
                whyItMatters: t.historicalConnection ??
                    t.completionNote ??
                    'Personalized to resident capability & history.',
                steps: t.steps,
                dignityTip: t.dignityTip,
                historicalConnection: t.historicalConnection,
                safetyComfort: t.safetyComfort,
                scriptPrompt: t.scriptPrompt,
                materialsTraySetup: t.materialsTraySetup,
                isPersonalized: true,
              ))
          .toList();

      final seenTitles = personalized.map((a) => a.title.toLowerCase()).toSet();
      final combined = [
        ...personalized,
        ...curated.where((c) => !seenTitles.contains(c.title.toLowerCase())),
      ];
      _applyFilter(
        all: combined,
        category: state.selectedCategory,
        query: state.searchQuery,
      );
    } catch (_) {
      if (!mounted || loadToken != _loadToken) return;
      state = state.copyWith(isLoading: false);
    }
  }

  void syncPersonalizedTasks(List<CareTask> tasks) {
    _personalizedTasks = tasks;
    loadActivities();
  }

  void selectCategory(MontessoriCategory? category) {
    _applyFilter(
        all: state.allActivities,
        category: category,
        query: state.searchQuery);
  }

  void setSearchQuery(String query) {
    _applyFilter(
        all: state.allActivities,
        category: state.selectedCategory,
        query: query);
  }

  void _applyFilter({
    required List<MontessoriActivity> all,
    MontessoriCategory? category,
    String query = '',
  }) {
    var filtered = List<MontessoriActivity>.from(all);
    if (category != null) {
      filtered = filtered.where((a) => a.category == category).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.summary.toLowerCase().contains(q) ||
            a.materials.any((m) => m.toLowerCase().contains(q));
      }).toList();
    }
    state = MontessoriState(
      allActivities: all,
      filteredActivities: filtered,
      selectedCategory: category,
      searchQuery: query,
      isLoading: false,
    );
  }
}

final montessoriProvider =
    StateNotifierProvider<MontessoriNotifier, MontessoriState>((ref) {
  final repo = ref.watch(montessoriRepositoryProvider);
  final initialTasks = ref.read(careTasksProvider).tasks;
  final notifier = MontessoriNotifier(repo, initialTasks);
  ref.listen<List<CareTask>>(
    careTasksProvider.select((s) => s.tasks),
    (_, next) => notifier.syncPersonalizedTasks(next),
  );
  return notifier;
});
