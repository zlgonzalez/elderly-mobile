import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/meal_log.dart';
import 'mock_meal_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: NutritionService - Meal API
// Contract: GET /api/v1/foods/library
// Contract: GET /api/v1/residents/{residentId}/meals/today
// Contract: POST /api/v1/residents/{residentId}/meals
abstract class MealRepository {
  Future<List<FoodItem>> getFoodLibrary();
  Future<List<MealLog>> getTodayMeals(String residentId);
  Future<MealLog> logMeal(String residentId, MealLog meal);
}

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  // In production, when USE_MOCK_DATA is false, connect to real microservice
  return MockMealRepository();
});
