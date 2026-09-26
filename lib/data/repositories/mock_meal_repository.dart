import '../fixtures/food_fixtures.dart';
import '../../domain/entities/meal_log.dart';
import 'meal_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: NutritionService - Mock Implementation
// Simulates /api/v1/foods/library and /api/v1/residents/{residentId}/meals endpoints
class MockMealRepository implements MealRepository {
  final List<FoodItem> _customFoods = [];
  final Map<String, List<MealLog>> _store = {};

  MockMealRepository() {
    _initDefaultMeals();
  }

  void _initDefaultMeals() {
    _store['res_margaret'] = [
      MealLog(
        id: 'meal_1',
        residentId: 'res_margaret',
        mealType: MealType.breakfast,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        items: [
          FoodFixtures.library.firstWhere((f) => f.name == 'Oatmeal'),
          FoodFixtures.library.firstWhere((f) => f.name == 'Earl Grey Tea'),
          FoodFixtures.library.firstWhere((f) => f.name == 'Banana'),
        ],
        expectedIntakePercent: 100,
        actualIntakePercent: 75,
        observations: 'Ate well with morning tea, enjoyed warm oatmeal.',
        recordedBy: 'Nurse Jane',
      ),
      MealLog(
        id: 'meal_2',
        residentId: 'res_margaret',
        mealType: MealType.lunch,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        items: [
          FoodFixtures.library.firstWhere((f) => f.name == 'Vegetable Minestrone Soup'),
          FoodFixtures.library.firstWhere((f) => f.name == 'Whole Wheat Toast'),
        ],
        expectedIntakePercent: 100,
        actualIntakePercent: 50,
        observations: 'Ate half of the soup bowl; noted reduced appetite.',
        recordedBy: 'Nurse Jane',
      ),
    ];

    _store['res_robert'] = [
      MealLog(
        id: 'meal_rob_1',
        residentId: 'res_robert',
        mealType: MealType.breakfast,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        items: [
          FoodFixtures.library.firstWhere((f) => f.name == 'Scrambled Eggs'),
          FoodFixtures.library.firstWhere((f) => f.name == 'Whole Wheat Toast'),
        ],
        expectedIntakePercent: 100,
        actualIntakePercent: 90,
        recordedBy: 'Visiting Nurse',
      ),
    ];

    _store['res_dorothy'] = [
      MealLog(
        id: 'meal_dor_1',
        residentId: 'res_dorothy',
        mealType: MealType.breakfast,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        items: [
          FoodFixtures.library.firstWhere((f) => f.name == 'Greek Yogurt with Honey'),
          FoodFixtures.library.firstWhere((f) => f.name == 'Fresh Strawberries'),
        ],
        expectedIntakePercent: 100,
        actualIntakePercent: 100,
        recordedBy: 'Nurse Jane',
      ),
    ];
  }

  void resetToDemo(String residentId) {
    _customFoods.clear();
    _initDefaultMeals();
  }

  @override
  Future<List<FoodItem>> getFoodLibrary() async {
    return [...FoodFixtures.library, ..._customFoods];
  }

  void addCustomFood(FoodItem food) {
    _customFoods.add(food);
  }

  @override
  Future<List<MealLog>> getTodayMeals(String residentId) async {
    return List.from(_store[residentId] ?? []);
  }

  @override
  Future<MealLog> logMeal(String residentId, MealLog meal) async {
    final list = _store.putIfAbsent(residentId, () => []);
    final newMeal = meal.copyWith(
      id: meal.id.isEmpty ? 'meal_${DateTime.now().millisecondsSinceEpoch}' : meal.id,
      residentId: residentId,
    );
    list.insert(0, newMeal);
    return newMeal;
  }
}
