import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/memory_item.dart';
import '../fixtures/resident_fixtures.dart';
import 'memory_repository.dart';
import 'mock_memory_repository.dart';

class HttpMemoryRepository implements MemoryRepository {
  final ApiClient _apiClient;
  final MockMemoryRepository _fallback = MockMemoryRepository();

  HttpMemoryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<MemoryItem>> getMemories(String residentId) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final res = await _apiClient.get('/memories', queryParameters: {'patient_id': patientUuid});
      if (res is List && res.isNotEmpty) {
        return res.map((item) {
          final m = item as Map<String, dynamic>;
          final tags = <String>[];
          if (m['category'] != null && m['category'].toString().isNotEmpty) {
            tags.add('#${m['category'].toString().toLowerCase().replaceAll(' ', '')}');
          }
          if (m['era'] != null && m['era'].toString().isNotEmpty) {
            tags.add('#${m['era'].toString().toLowerCase().replaceAll(' ', '')}');
          }

          DateTime date = DateTime.now();
          if (m['date_str'] != null) {
            final parsed = DateTime.tryParse(m['date_str'].toString());
            if (parsed != null) date = parsed;
          } else if (m['created_at'] != null) {
            final parsed = DateTime.tryParse(m['created_at'].toString());
            if (parsed != null) date = parsed;
          }

          return MemoryItem(
            id: m['id']?.toString() ?? '',
            residentId: residentId,
            format: MemoryFormat.fromString(m['media_type']?.toString() ?? 'photo'),
            title: m['title']?.toString() ?? 'Untitled Memory',
            content: m['notes']?.toString(),
            mediaUrl: m['media_url'] != null && m['media_url'].toString().isNotEmpty
                ? _apiClient.resolveMediaUrl(m['media_url'].toString())
                : null,
            date: date,
            sharedBy: m['created_by']?.toString() ?? 'Family Member',
            tags: tags,
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMemoryRepository] getMemories network error: $e, using fallback');
      }
    }
    return _fallback.getMemories(residentId);
  }

  @override
  Future<MemoryItem> createMemory(String residentId, MemoryItem memory) async {
    final patientUuid = ResidentFixtures.toBackendUuid(residentId);
    try {
      final category = memory.tags.isNotEmpty
          ? memory.tags.first.replaceAll('#', '')
          : 'Memories';

      final body = {
        'patient_id': patientUuid,
        'title': memory.title,
        'category': category,
        'media_type': memory.format.name,
        'media_url': memory.mediaUrl ?? '',
        'date_str': memory.date.toIso8601String(),
        'era': memory.tags.length > 1 ? memory.tags[1].replaceAll('#', '') : 'Family',
        'prompt_trigger': '',
        'notes': memory.content ?? '',
        'created_by': memory.sharedBy,
      };

      final res = await _apiClient.post('/memories', body: body);
      if (res is Map<String, dynamic>) {
        final id = res['id']?.toString() ?? memory.id;
        return memory.copyWith(id: id);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMemoryRepository] createMemory network error: $e, using fallback');
      }
    }
    return _fallback.createMemory(residentId, memory);
  }

  @override
  Future<bool> deleteMemory(String residentId, String memoryId) async {
    if (memoryId.contains('-')) {
      try {
        await _apiClient.delete('/memories/$memoryId');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[HttpMemoryRepository] deleteMemory network error: $e');
        }
      }
    }
    return _fallback.deleteMemory(residentId, memoryId);
  }
}
