import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../fixtures/resident_fixtures.dart';
import 'ai_assistant_repository.dart';
import 'mock_ai_assistant_repository.dart';

class HttpAiAssistantRepository implements AiAssistantRepository {
  final ApiClient _apiClient;
  final MockAiAssistantRepository _fallback = MockAiAssistantRepository();

  HttpAiAssistantRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Stream<String> streamResponse(
    String prompt, {
    String? residentContext,
    String? screenContext,
  }) async* {
    final fullAnswer = await getResponse(
      prompt,
      residentContext: residentContext,
      screenContext: screenContext,
    );

    final words = fullAnswer.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield '${words[i]}${i == words.length - 1 ? '' : ' '}';
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  @override
  Future<String> getResponse(
    String prompt, {
    String? residentContext,
    String? screenContext,
  }) async {
    final residentId = residentContext ?? 'res_margaret';
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);

    try {
      final res = await _apiClient.post('/ai/chat', body: {
        'patient_id': patientUuid,
        'message': prompt,
      });

      if (res is Map<String, dynamic> && res['reply'] != null) {
        return res['reply'].toString();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpAiAssistantRepository] getResponse network error: $e, using fallback');
      }
    }

    return _fallback.getResponse(
      prompt,
      residentContext: residentContext,
      screenContext: screenContext,
    );
  }
}
