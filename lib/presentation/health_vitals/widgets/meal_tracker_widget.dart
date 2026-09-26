import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/meal_log.dart';
import '../../auth/auth_provider.dart';
import '../../family_portal/resident_provider.dart';
import '../meal_tracker_provider.dart';
import 'custom_food_sheet.dart';
import 'food_library_sheet.dart';

class MealTrackerWidget extends ConsumerStatefulWidget {
  const MealTrackerWidget({super.key});

  @override
  ConsumerState<MealTrackerWidget> createState() => _MealTrackerWidgetState();
}

class _MealTrackerWidgetState extends ConsumerState<MealTrackerWidget> {
  final List<FoodItem> _selectedDishes = [];
  int _actualIntakePercent = 75;
  final _observationsController = TextEditingController();

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  void _openFoodLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoodLibrarySheet(
        onSelectFood: (food) {
          setState(() => _selectedDishes.add(food));
        },
      ),
    );
  }

  void _openCustomFood() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomFoodSheet(
        onAddCustomFood: (food) {
          setState(() => _selectedDishes.add(food));
        },
      ),
    );
  }

  void _submitMeal() {
    if (_selectedDishes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one food dish.')),
      );
      return;
    }

    final resident = ref.read(residentProvider);
    final user = ref.read(authProvider).user;
    final state = ref.read(mealTrackerProvider);

    final meal = MealLog(
      id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
      residentId: resident.id,
      mealType: state.selectedMealType,
      timestamp: DateTime.now(),
      items: List.from(_selectedDishes),
      expectedIntakePercent: 100,
      actualIntakePercent: _actualIntakePercent,
      observations: _observationsController.text.trim().isEmpty ? null : _observationsController.text.trim(),
      recordedBy: user?.fullName ?? 'Nurse Jane',
    );

    ref.read(mealTrackerProvider.notifier).logMeal(meal);

    setState(() {
      _selectedDishes.clear();
      _observationsController.clear();
      _actualIntakePercent = 100;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${meal.mealType.displayName} logged (${meal.consumedCalories} kcal consumed)'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealTrackerProvider);
    final notifier = ref.read(mealTrackerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.restaurant, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                "Today's Nutrition & Meals",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Macro Progress Bars
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _buildMacroBar(
                  'Calories',
                  '${state.totalConsumedCalories} / ${state.targets.calories} kcal',
                  state.calorieProgress,
                  AppColors.primary,
                ),
                const SizedBox(height: 10),
                _buildMacroBar(
                  'Protein',
                  '${state.totalConsumedProtein} / ${state.targets.protein} g',
                  state.proteinProgress,
                  const Color(0xFF385723),
                ),
                const SizedBox(height: 10),
                _buildMacroBar(
                  'Carbs',
                  '${state.totalConsumedCarbs} / ${state.targets.carbs} g',
                  state.carbsProgress,
                  const Color(0xFFC77700),
                ),
                const SizedBox(height: 10),
                _buildMacroBar(
                  'Fat',
                  '${state.totalConsumedFat} / ${state.targets.fat} g',
                  state.fatProgress,
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log Meal Section
          Text(
            'Log Meal Intake',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),

          // Meal Type Selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MealType.values.map((type) {
              final isSelected = state.selectedMealType == type;
              return ChoiceChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) notifier.setSelectedMealType(type);
                },
                selectedColor: AppColors.surfaceVariant,
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Dishes selection buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _openFoodLibrary,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Food Library (35+)'),
              ),
              OutlinedButton.icon(
                onPressed: _openCustomFood,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Custom Food'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Selected dishes chips
          if (_selectedDishes.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedDishes.map((dish) {
                return Chip(
                  label: Text('${dish.name} (${dish.portion})'),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _selectedDishes.remove(dish)),
                  backgroundColor: AppColors.surfaceVariant,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Actual Intake Percentage
          Text(
            'Actual Intake: $_actualIntakePercent%',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [25, 50, 75, 100].map((pct) {
              final isSel = _actualIntakePercent == pct;
              String label;
              if (pct == 25) label = '¼ Eaten (25%)';
              else if (pct == 50) label = '½ Eaten (50%)';
              else if (pct == 75) label = '¾ Eaten (75%)';
              else label = 'All Eaten (100%)';

              return ChoiceChip(
                label: Text(label),
                selected: isSel,
                onSelected: (selected) {
                  if (selected) setState(() => _actualIntakePercent = pct);
                },
                selectedColor: AppColors.surfaceVariant,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? AppColors.primary : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Meal Observations
          TextField(
            controller: _observationsController,
            decoration: const InputDecoration(
              labelText: 'Meal Observations / Notes',
              hintText: 'e.g. Good appetite, drank all water...',
            ),
          ),
          const SizedBox(height: 14),

          // Submit Meal Button
          ElevatedButton.icon(
            onPressed: _submitMeal,
            icon: const Icon(Icons.check),
            label: const Text('Save Meal Log'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 20),

          // Logged Meals History
          Text(
            "Today's Meals",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          if (state.todayMeals.isEmpty)
            const Text('No meals logged yet today.', style: TextStyle(color: AppColors.textSecondary))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.todayMeals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final meal = state.todayMeals[idx];
                return _buildMealCard(context, meal);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, MealLog meal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: meal.isLowIntake ? AppColors.allergyRedBg : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: meal.isLowIntake ? AppColors.allergyRed.withOpacity(0.4) : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                meal.mealType.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${meal.actualIntakePercent}% Eaten',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: meal.isLowIntake ? AppColors.statusRed : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: meal.items.map((i) {
              return Text(
                '${i.name} (${i.portion}) •',
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            '${meal.consumedCalories} kcal • P:${meal.consumedProtein}g C:${meal.consumedCarbs}g F:${meal.consumedFat}g',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          if (meal.observations != null && meal.observations!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${meal.observations}"',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
