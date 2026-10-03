import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'http_ai_assistant_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: AiService - Streaming/Query API
// Endpoints:
// - POST /api/v1/ai/chat
// - GET /api/v1/ai/prompt-suggestions
// Contract:
// Request: { "patient_id": uuid, "message": string }
// Response: { "reply": string, "suggestions": string[] }
abstract class AiAssistantRepository {
  Stream<String> streamResponse(
    String prompt, {
    String? residentContext,
    String? screenContext,
  });

  Future<String> getResponse(
    String prompt, {
    String? residentContext,
    String? screenContext,
  });
}

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HttpAiAssistantRepository(apiClient: apiClient);
});
