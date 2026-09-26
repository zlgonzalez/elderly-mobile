import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/memory_item.dart';
import 'mock_memory_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: MemoryService - List/Create Memories
// Contract: GET /api/v1/residents/{residentId}/memories
// Contract: POST /api/v1/residents/{residentId}/memories
abstract class MemoryRepository {
  Future<List<MemoryItem>> getMemories(String residentId);
  Future<MemoryItem> createMemory(String residentId, MemoryItem memory);
  Future<bool> deleteMemory(String residentId, String memoryId);
}

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  // In production, when USE_MOCK_DATA is false, connect to real microservice
  return MockMemoryRepository();
});
