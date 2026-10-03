import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/core/network/api_client.dart';
import 'package:elderly_mobile/data/repositories/http_resident_repository.dart';
import 'package:elderly_mobile/data/repositories/http_meal_repository.dart';
import 'package:elderly_mobile/data/repositories/http_mood_repository.dart';
import 'package:elderly_mobile/data/repositories/http_memory_repository.dart';
import 'package:elderly_mobile/data/repositories/http_ai_assistant_repository.dart';
import 'package:elderly_mobile/domain/entities/meal_log.dart';
import 'package:elderly_mobile/domain/entities/mood_entry.dart';
import 'package:elderly_mobile/domain/entities/memory_item.dart';

void main() {
  group('HTTP Repositories Fallback & Contract Tests', () {
    late ApiClient apiClient;

    setUp(() {
      // Use an unroutable port so network calls immediately fail and trigger fallback
      apiClient = ApiClient(baseUrl: 'http://127.0.0.1:59999/api/v1');
    });

    test('HttpResidentRepository falls back cleanly when offline', () async {
      final repo = HttpResidentRepository(apiClient: apiClient);
      final resident = await repo.getResident('res_margaret');
      expect(resident, isNotNull);
      expect(resident!.name, contains('Margaret'));
      expect(resident.milestones.isNotEmpty, isTrue);

      final all = await repo.listResidents();
      expect(all.length, greaterThanOrEqualTo(3));
    });

    test('HttpMealRepository falls back cleanly when offline', () async {
      final repo = HttpMealRepository(apiClient: apiClient);
      final library = await repo.getFoodLibrary();
      expect(library.isNotEmpty, isTrue);

      final meals = await repo.getTodayMeals('res_margaret');
      expect(meals.isNotEmpty, isTrue);

      final logged = await repo.logMeal(
        'res_margaret',
        MealLog(
          id: 'test_meal',
          residentId: 'res_margaret',
          mealType: MealType.dinner,
          timestamp: DateTime.now(),
          items: [library.first],
          actualIntakePercent: 80,
          recordedBy: 'Nurse',
        ),
      );
      expect(logged.actualIntakePercent, 80);
    });

    test('HttpMoodRepository falls back cleanly when offline', () async {
      final repo = HttpMoodRepository(apiClient: apiClient);
      final moods = await repo.getMoods('res_margaret');
      expect(moods.isNotEmpty, isTrue);

      final logged = await repo.logMood(
        'res_margaret',
        MoodEntry(
          id: 'test_mood',
          residentId: 'res_margaret',
          mood: MoodType.happy,
          timestamp: DateTime.now(),
          recordedBy: 'Nurse',
          notes: 'Feeling great',
        ),
      );
      expect(logged.mood, MoodType.happy);
    });

    test('HttpMemoryRepository falls back cleanly when offline', () async {
      final repo = HttpMemoryRepository(apiClient: apiClient);
      final memories = await repo.getMemories('res_margaret');
      expect(memories.isNotEmpty, isTrue);

      final created = await repo.createMemory(
        'res_margaret',
        MemoryItem(
          id: 'test_mem',
          residentId: 'res_margaret',
          format: MemoryFormat.photo,
          title: 'Special Memory',
          date: DateTime.now(),
          sharedBy: 'Daughter',
        ),
      );
      expect(created.title, 'Special Memory');

      final deleted = await repo.deleteMemory('res_margaret', created.id);
      expect(deleted, isTrue);
    });

    test('HttpAiAssistantRepository falls back cleanly when offline', () async {
      final repo = HttpAiAssistantRepository(apiClient: apiClient);
      final reply = await repo.getResponse('What should I bring to visit Margaret?');
      expect(reply.isNotEmpty, isTrue);
      expect(reply.toLowerCase(), contains('visit'));

      final stream = repo.streamResponse('Hello');
      final chunks = await stream.toList();
      expect(chunks.isNotEmpty, isTrue);
    });
  });
}
