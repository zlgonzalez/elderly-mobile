import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/montessori_repository.dart';
import '../../domain/entities/montessori_activity.dart';

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
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MontessoriNotifier extends StateNotifier<MontessoriState> {
  final MontessoriRepository _repository;

  MontessoriNotifier(this._repository) : super(const MontessoriState(isLoading: true)) {
    loadActivities();
  }

  Future<void> loadActivities() async {
    state = state.copyWith(isLoading: true);
    final all = await _repository.getActivities();
    _applyFilter(all: all, category: state.selectedCategory, query: state.searchQuery);
  }

  void selectCategory(MontessoriCategory? category) {
    _applyFilter(all: state.allActivities, category: category, query: state.searchQuery);
  }

  void setSearchQuery(String query) {
    _applyFilter(all: state.allActivities, category: state.selectedCategory, query: query);
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

final montessoriProvider = StateNotifierProvider<MontessoriNotifier, MontessoriState>((ref) {
  final repo = ref.watch(montessoriRepositoryProvider);
  return MontessoriNotifier(repo);
});
