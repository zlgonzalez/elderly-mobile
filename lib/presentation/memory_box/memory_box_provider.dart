import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/memory_repository.dart';
import '../../domain/entities/memory_item.dart';
import '../family_portal/resident_provider.dart';

class MemoryBoxState {
  final List<MemoryItem> memories;
  final bool isLoading;
  final String? selectedTag;
  final MemoryFormat? selectedFormat;
  final String searchQuery;

  const MemoryBoxState({
    this.memories = const [],
    this.isLoading = false,
    this.selectedTag,
    this.selectedFormat,
    this.searchQuery = '',
  });

  List<MemoryItem> get filteredMemories {
    return memories.where((item) {
      if (selectedFormat != null && item.format != selectedFormat) {
        return false;
      }
      if (selectedTag != null && !item.tags.contains(selectedTag)) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesContent = item.content?.toLowerCase().contains(query) ?? false;
        final matchesSharedBy = item.sharedBy.toLowerCase().contains(query);
        final matchesTags = item.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchesTitle && !matchesContent && !matchesSharedBy && !matchesTags) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Set<String> get allTags {
    final tags = <String>{};
    for (final memory in memories) {
      tags.addAll(memory.tags);
    }
    return tags;
  }

  MemoryBoxState copyWith({
    List<MemoryItem>? memories,
    bool? isLoading,
    String? selectedTag,
    bool clearSelectedTag = false,
    MemoryFormat? selectedFormat,
    bool clearSelectedFormat = false,
    String? searchQuery,
  }) {
    return MemoryBoxState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      selectedFormat: clearSelectedFormat ? null : (selectedFormat ?? this.selectedFormat),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MemoryBoxNotifier extends StateNotifier<MemoryBoxState> {
  final MemoryRepository _repository;
  final String _residentId;

  MemoryBoxNotifier({
    required MemoryRepository repository,
    required String residentId,
  })  : _repository = repository,
        _residentId = residentId,
        super(const MemoryBoxState(isLoading: true)) {
    loadMemories();
  }

  Future<void> loadMemories() async {
    state = state.copyWith(isLoading: true);
    final items = await _repository.getMemories(_residentId);
    state = state.copyWith(memories: items, isLoading: false);
  }

  void setFormatFilter(MemoryFormat? format) {
    if (state.selectedFormat == format) {
      state = state.copyWith(clearSelectedFormat: true);
    } else {
      state = state.copyWith(selectedFormat: format);
    }
  }

  void setTagFilter(String? tag) {
    if (state.selectedTag == tag) {
      state = state.copyWith(clearSelectedTag: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addMemory(MemoryItem memory) async {
    final created = await _repository.createMemory(_residentId, memory);
    state = state.copyWith(
      memories: [created, ...state.memories],
    );
  }

  Future<void> removeMemory(String memoryId) async {
    final success = await _repository.deleteMemory(_residentId, memoryId);
    if (success) {
      state = state.copyWith(
        memories: state.memories.where((m) => m.id != memoryId).toList(),
      );
    }
  }
}

final memoryBoxProvider = StateNotifierProvider<MemoryBoxNotifier, MemoryBoxState>((ref) {
  final repo = ref.watch(memoryRepositoryProvider);
  final resident = ref.watch(residentProvider);
  return MemoryBoxNotifier(repository: repo, residentId: resident.id);
});
