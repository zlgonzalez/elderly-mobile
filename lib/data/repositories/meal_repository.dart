import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/meal_log.dart';
import '../../core/network/api_client.dart';
import 'http_meal_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: NutritionService - Meal API
// Contract: GET /api/v1/nutrition/foods
// Contract: GET /api/v1/nutrition/summary?patient_id={uuid}&date=YYYY-MM-DD
// Contract: POST /api/v1/nutrition/meals
abstract class MealRepository {
  Future<List<FoodItem>> getFoodLibrary();
  Future<List<MealLog>> getTodayMeals(String residentId);
  Future<MealLog> logMeal(String residentId, MealLog meal);
  Future<NutritionTargets> getNutritionTargets(String residentId);
}

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HttpMealRepository(apiClient: apiClient);
});
