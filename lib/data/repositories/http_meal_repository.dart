import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/meal_log.dart';
import '../fixtures/resident_fixtures.dart';
import 'meal_repository.dart';
import 'mock_meal_repository.dart';

class HttpMealRepository implements MealRepository {
  final ApiClient _apiClient;
  final MockMealRepository _fallback = MockMealRepository();

  HttpMealRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<FoodItem>> getFoodLibrary() async {
    try {
      final res = await _apiClient.get('/nutrition/foods');
      if (res is List && res.isNotEmpty) {
        return res.map((item) {
          final m = item as Map<String, dynamic>;
          return FoodItem(
            id: m['id']?.toString() ?? '',
            name: m['name']?.toString() ?? '',
            portion: '${m['serving_size'] ?? 1} ${m['serving_unit'] ?? 'serving'}',
            category: m['category']?.toString() ?? 'General',
            calories: (m['calories'] as num?)?.toInt() ?? 0,
            protein: (m['protein_g'] as num?)?.toInt() ?? 0,
            carbs: (m['carbs_g'] as num?)?.toInt() ?? 0,
            fat: (m['fat_g'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMealRepository] getFoodLibrary network error: $e, using fallback');
      }
    }
    return _fallback.getFoodLibrary();
  }

  @override
  Future<List<MealLog>> getTodayMeals(String residentId) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final res = await _apiClient.get('/nutrition/summary', queryParameters: {
        'patient_id': patientUuid,
        'date': dateStr,
      });

      if (res is Map<String, dynamic> && res['meals'] is List) {
        final mealsList = res['meals'] as List;
        return mealsList.map((m) {
          final map = m as Map<String, dynamic>;
          final itemsList = (map['items'] as List?) ?? [];
          final foodItems = itemsList.map((fi) {
            final fMap = (fi['food'] as Map<String, dynamic>?) ?? {};
            return FoodItem(
              id: fMap['id']?.toString() ?? '',
              name: fMap['name']?.toString() ?? '',
              portion: '${fMap['serving_size'] ?? 1} ${fMap['serving_unit'] ?? 'serving'}',
              category: fMap['category']?.toString() ?? 'General',
              calories: (fMap['calories'] as num?)?.toInt() ?? 0,
              protein: (fMap['protein_g'] as num?)?.toInt() ?? 0,
              carbs: (fMap['carbs_g'] as num?)?.toInt() ?? 0,
              fat: (fMap['fat_g'] as num?)?.toInt() ?? 0,
            );
          }).toList();

          return MealLog(
            id: map['id']?.toString() ?? '',
            residentId: residentId,
            mealType: MealType.fromString(map['meal_type']?.toString() ?? 'breakfast'),
            timestamp: map['timestamp'] != null
                ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
                : DateTime.now(),
            items: foodItems,
            actualIntakePercent: (map['intake_percentage'] as num?)?.toInt() ?? 100,
            observations: map['notes']?.toString(),
            recordedBy: map['recorded_by']?.toString() ?? 'Nurse Jane',
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMealRepository] getTodayMeals network error: $e, using fallback');
      }
    }
    return _fallback.getTodayMeals(residentId);
  }

  @override
  Future<MealLog> logMeal(String residentId, MealLog meal) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final body = {
        'patient_id': patientUuid,
        'recorded_by': meal.recordedBy,
        'meal_type': meal.mealType.name,
        'intake_percentage': meal.actualIntakePercent,
        'items': meal.items.map((i) => {
          'food': {
            'id': i.id.contains('-') ? i.id : '00000000-0000-0000-0000-000000000000',
            'name': i.name,
            'category': i.category,
            'calories': i.calories,
            'carbs_g': i.carbs.toDouble(),
            'protein_g': i.protein.toDouble(),
            'fat_g': i.fat.toDouble(),
            'serving_size': 1.0,
            'serving_unit': i.portion,
          },
          'servings': 1.0,
        }).toList(),
        'notes': meal.observations ?? '',
        'timestamp': meal.timestamp.toIso8601String(),
      };

      final res = await _apiClient.post('/nutrition/meals', body: body);
      if (res is Map<String, dynamic>) {
        final id = res['id']?.toString() ?? meal.id;
        return meal.copyWith(id: id);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMealRepository] logMeal network error: $e, using fallback');
      }
    }
    return _fallback.logMeal(residentId, meal);
  }

  @override
  Future<NutritionTargets> getNutritionTargets(String residentId) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final res = await _apiClient.get('/nutrition/targets', queryParameters: {
        'patient_id': patientUuid,
      });
      if (res is Map<String, dynamic>) {
        return NutritionTargets.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMealRepository] getNutritionTargets network error: $e, trying summary endpoint');
      }
      try {
        final res = await _apiClient.get('/nutrition/summary', queryParameters: {
          'patient_id': patientUuid,
        });
        if (res is Map<String, dynamic>) {
          if (res['targets'] is Map<String, dynamic>) {
            return NutritionTargets.fromJson(res['targets'] as Map<String, dynamic>);
          }
          return NutritionTargets.fromJson(res);
        }
      } catch (_) {}
    }
    return _fallback.getNutritionTargets(residentId);
  }
}
