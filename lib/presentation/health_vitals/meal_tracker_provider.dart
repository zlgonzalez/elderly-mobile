import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/mock_meal_repository.dart';
import '../../domain/entities/meal_log.dart';
import '../family_portal/resident_provider.dart';

class MealTrackerState {
  final List<MealLog> todayMeals;
  final List<FoodItem> foodLibrary;
  final bool isLoading;
  final MealType selectedMealType;
  final NutritionTargets targets;

  const MealTrackerState({
    this.todayMeals = const [],
    this.foodLibrary = const [],
    this.isLoading = false,
    this.selectedMealType = MealType.breakfast,
    this.targets = const NutritionTargets(),
  });

  int get totalConsumedCalories => todayMeals.fold(0, (sum, m) => sum + m.consumedCalories);
  int get totalConsumedProtein => todayMeals.fold(0, (sum, m) => sum + m.consumedProtein);
  int get totalConsumedCarbs => todayMeals.fold(0, (sum, m) => sum + m.consumedCarbs);
  int get totalConsumedFat => todayMeals.fold(0, (sum, m) => sum + m.consumedFat);

  double get calorieProgress => (totalConsumedCalories / targets.calories).clamp(0.0, 1.0);
  double get proteinProgress => (totalConsumedProtein / targets.protein).clamp(0.0, 1.0);
  double get carbsProgress => (totalConsumedCarbs / targets.carbs).clamp(0.0, 1.0);
  double get fatProgress => (totalConsumedFat / targets.fat).clamp(0.0, 1.0);

  bool get hasLowIntakeMeal => todayMeals.any((m) => m.isLowIntake);

  MealTrackerState copyWith({
    List<MealLog>? todayMeals,
    List<FoodItem>? foodLibrary,
    bool? isLoading,
    MealType? selectedMealType,
    NutritionTargets? targets,
  }) {
    return MealTrackerState(
      todayMeals: todayMeals ?? this.todayMeals,
      foodLibrary: foodLibrary ?? this.foodLibrary,
      isLoading: isLoading ?? this.isLoading,
      selectedMealType: selectedMealType ?? this.selectedMealType,
      targets: targets ?? this.targets,
    );
  }
}

class MealTrackerNotifier extends StateNotifier<MealTrackerState> {
  final MealRepository _repository;
  final String _residentId;

  MealTrackerNotifier({
    required MealRepository repository,
    required String residentId,
  })  : _repository = repository,
        _residentId = residentId,
        super(const MealTrackerState(isLoading: true)) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    final library = await _repository.getFoodLibrary();
    final meals = await _repository.getTodayMeals(_residentId);
    final targets = await _repository.getNutritionTargets(_residentId);
    state = state.copyWith(
      foodLibrary: library,
      todayMeals: meals,
      targets: targets,
      isLoading: false,
    );
  }

  void setSelectedMealType(MealType type) {
    state = state.copyWith(selectedMealType: type);
  }

  Future<void> logMeal(MealLog meal) async {
    final created = await _repository.logMeal(_residentId, meal);
    state = state.copyWith(todayMeals: [created, ...state.todayMeals]);
  }

  void addCustomFood(FoodItem food) {
    final repo = _repository;
    if (repo is MockMealRepository) {
      repo.addCustomFood(food);
    }
    state = state.copyWith(foodLibrary: [...state.foodLibrary, food]);
  }
}

final mealTrackerProvider = StateNotifierProvider<MealTrackerNotifier, MealTrackerState>((ref) {
  final repo = ref.watch(mealRepositoryProvider);
  final resident = ref.watch(residentProvider);
  return MealTrackerNotifier(repository: repo, residentId: resident.id);
});
