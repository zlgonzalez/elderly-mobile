import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import 'mock_ai_assistant_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: AiService - Streaming/Query API
// Endpoints:
// - POST /api/v1/ai/chat/stream
// - POST /api/v1/ai/chat/completions
// Contract:
// Request: { "prompt": string, "residentContext": string, "screenContext": string }
// Response: Server-sent event stream (SSE) or JSON completion with elder-care/Montessori guidance.
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
  final config = ref.watch(appConfigProvider);
  return MockAiAssistantRepository(apiKey: config.geminiApiKey);
});
