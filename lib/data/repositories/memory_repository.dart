import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/memory_item.dart';
import '../../core/network/api_client.dart';
import 'http_memory_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: MemoryService - List/Create Memories
// Contract: GET /api/v1/memories?patient_id={uuid}
// Contract: POST /api/v1/memories
// Contract: DELETE /api/v1/memories/{id}
abstract class MemoryRepository {
  Future<List<MemoryItem>> getMemories(String residentId);
  Future<MemoryItem> createMemory(String residentId, MemoryItem memory);
  Future<bool> deleteMemory(String residentId, String memoryId);
}

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HttpMemoryRepository(apiClient: apiClient);
});
