import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../domain/entities/mood_entry.dart';
import '../../core/network/api_client.dart';
import 'http_mood_repository.dart';
import 'mock_mood_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: MoodService - History API
// Contract: GET /api/v1/moods?patient_id={uuid}
// Contract: POST /api/v1/moods
abstract class MoodRepository {
  Future<List<MoodEntry>> getMoods(String residentId);
  Future<MoodEntry> logMood(String residentId, MoodEntry mood);
}

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockMoodRepository();
  }
  final apiClient = ref.watch(apiClientProvider);
  return HttpMoodRepository(apiClient: apiClient);
});
