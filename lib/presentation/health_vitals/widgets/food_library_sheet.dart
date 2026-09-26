import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/meal_log.dart';
import '../meal_tracker_provider.dart';

class FoodLibrarySheet extends ConsumerStatefulWidget {
  final ValueChanged<FoodItem> onSelectFood;

  const FoodLibrarySheet({super.key, required this.onSelectFood});

  @override
  ConsumerState<FoodLibrarySheet> createState() => _FoodLibrarySheetState();
}

class _FoodLibrarySheetState extends ConsumerState<FoodLibrarySheet> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealTrackerProvider);
    final foods = state.foodLibrary;

    final categories = <String>{};
    for (final f in foods) {
      categories.add(f.category);
    }

    final filtered = foods.where((f) {
      if (_selectedCategory != null && f.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = f.name.toLowerCase().contains(q);
        final matchesCat = f.category.toLowerCase().contains(q);
        if (!matchesName && !matchesCat) return false;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Food Library',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search foods (e.g. Oatmeal, Soup)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
          const SizedBox(height: 12),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                  selectedColor: AppColors.surfaceVariant,
                ),
                const SizedBox(width: 8),
                ...categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        _selectedCategory = isSelected ? null : cat;
                      }),
                      selectedColor: AppColors.surfaceVariant,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Food List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No food items found matching your search.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item.portion} • ${item.calories} kcal • P:${item.protein}g C:${item.carbs}g F:${item.fat}g',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            widget.onSelectFood(item);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: const Size(60, 36),
                          ),
                          child: const Text('Add'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
