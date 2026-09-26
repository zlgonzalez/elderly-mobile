import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/data/fixtures/food_fixtures.dart';
import 'package:elderly_mobile/data/repositories/mock_meal_repository.dart';
import 'package:elderly_mobile/domain/entities/meal_log.dart';

void main() {
  group('Nutrient Calculation & Intake Scaling Tests', () {
    final oatmeal = FoodFixtures.library.firstWhere((f) => f.name == 'Oatmeal');
    final banana = FoodFixtures.library.firstWhere((f) => f.name == 'Banana');

    test('100% intake yields full calories and macros', () {
      final meal = MealLog(
        id: '1',
        residentId: 'res_margaret',
        mealType: MealType.breakfast,
        timestamp: DateTime.now(),
        items: [oatmeal, banana],
        expectedIntakePercent: 100,
        actualIntakePercent: 100,
        recordedBy: 'Nurse Jane',
      );

      final expectedCals = oatmeal.calories + banana.calories; // 158 + 105 = 263
      expect(meal.consumedCalories, expectedCals);
      expect(meal.isLowIntake, isFalse);
    });

    test('75% intake scales calories and macros accurately', () {
      final meal = MealLog(
        id: '2',
        residentId: 'res_margaret',
        mealType: MealType.breakfast,
        timestamp: DateTime.now(),
        items: [oatmeal, banana],
        expectedIntakePercent: 100,
        actualIntakePercent: 75,
        recordedBy: 'Nurse Jane',
      );

      final totalCals = oatmeal.calories + banana.calories; // 263
      final expectedConsumed = (totalCals * 0.75).round(); // 197
      expect(meal.consumedCalories, expectedConsumed);
      expect(meal.isLowIntake, isFalse);
    });

    test('50% intake flags isLowIntake as true for wellbeing alerts', () {
      final meal = MealLog(
        id: '3',
        residentId: 'res_margaret',
        mealType: MealType.lunch,
        timestamp: DateTime.now(),
        items: [oatmeal],
        expectedIntakePercent: 100,
        actualIntakePercent: 50,
        recordedBy: 'Nurse Jane',
      );

      expect(meal.isLowIntake, isTrue);
    });
  });

  group('MockMealRepository Tests', () {
    late MockMealRepository repository;

    setUp(() {
      repository = MockMealRepository();
    });

    test('getFoodLibrary contains 35+ items', () async {
      final library = await repository.getFoodLibrary();
      expect(library.length, greaterThanOrEqualTo(35));
      expect(library.any((f) => f.name == 'Oatmeal'), isTrue);
      expect(library.any((f) => f.name == 'Baked Salmon Fillet'), isTrue);
      expect(library.any((f) => f.name == 'Fresh Strawberries'), isTrue);
    });

    test('getTodayMeals returns breakfast and lunch for Margaret', () async {
      final meals = await repository.getTodayMeals('res_margaret');
      expect(meals.length, 2);
      expect(meals.any((m) => m.mealType == MealType.breakfast), isTrue);
      expect(meals.any((m) => m.mealType == MealType.lunch), isTrue);
    });

    test('logMeal records new meal and updates store', () async {
      final soup = FoodFixtures.library.firstWhere((f) => f.name == 'Chicken Noodle Soup');
      final newMeal = MealLog(
        id: 'meal_test',
        residentId: 'res_margaret',
        mealType: MealType.dinner,
        timestamp: DateTime.now(),
        items: [soup],
        actualIntakePercent: 100,
        recordedBy: 'Sarah Thompson',
      );

      final saved = await repository.logMeal('res_margaret', newMeal);
      expect(saved.mealType, MealType.dinner);

      final list = await repository.getTodayMeals('res_margaret');
      expect(list.any((m) => m.mealType == MealType.dinner), isTrue);
    });
  });
}
