import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/mood_entry.dart';
import '../fixtures/resident_fixtures.dart';
import 'mock_mood_repository.dart';
import 'mood_repository.dart';

class HttpMoodRepository implements MoodRepository {
  final ApiClient _apiClient;
  final MockMoodRepository _fallback = MockMoodRepository();

  HttpMoodRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<MoodEntry>> getMoods(String residentId) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final res = await _apiClient.get('/moods', queryParameters: {'patient_id': patientUuid});
      if (res is List && res.isNotEmpty) {
        return res.map((item) {
          final m = item as Map<String, dynamic>;
          return MoodEntry(
            id: m['id']?.toString() ?? '',
            residentId: residentId,
            mood: MoodType.fromString(m['mood_type']?.toString() ?? 'happy'),
            timestamp: m['timestamp'] != null
                ? DateTime.tryParse(m['timestamp'].toString()) ?? DateTime.now()
                : DateTime.now(),
            recordedBy: m['recorded_by']?.toString() ?? 'Family Member',
            notes: m['note']?.toString(),
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMoodRepository] getMoods network error: $e, using fallback');
      }
    }
    return _fallback.getMoods(residentId);
  }

  @override
  Future<MoodEntry> logMood(String residentId, MoodEntry mood) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      int score;
      switch (mood.mood) {
        case MoodType.happy:
          score = 5;
          break;
        case MoodType.content:
          score = 4;
          break;
        case MoodType.neutral:
          score = 3;
          break;
        case MoodType.sad:
        case MoodType.anxious:
          score = 2;
          break;
        case MoodType.upset:
          score = 1;
          break;
      }

      final body = {
        'patient_id': patientUuid,
        'recorded_by': mood.recordedBy,
        'mood_type': mood.mood.name,
        'score': score,
        'note': mood.notes ?? '',
        'triggers': <String>[],
        'timestamp': mood.timestamp.toIso8601String(),
      };

      final res = await _apiClient.post('/moods', body: body);
      if (res is Map<String, dynamic>) {
        final id = res['id']?.toString() ?? mood.id;
        return MoodEntry(
          id: id,
          residentId: residentId,
          mood: mood.mood,
          timestamp: mood.timestamp,
          recordedBy: mood.recordedBy,
          notes: mood.notes,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMoodRepository] logMood network error: $e, using fallback');
      }
    }
    return _fallback.logMood(residentId, mood);
  }
}
