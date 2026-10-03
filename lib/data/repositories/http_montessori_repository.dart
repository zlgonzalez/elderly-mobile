import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/montessori_activity.dart';
import 'mock_montessori_repository.dart';
import 'montessori_repository.dart';

class HttpMontessoriRepository implements MontessoriRepository {
  final ApiClient _apiClient;
  final MockMontessoriRepository _fallback = MockMontessoriRepository();

  HttpMontessoriRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<MontessoriActivity>> getActivities({MontessoriCategory? category, String? query}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category.name;
      }
      if (query != null && query.trim().isNotEmpty) {
        queryParams['query'] = query.trim();
      }

      final res = await _apiClient.get(
        '/activities/montessori',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (res is List && res.isNotEmpty) {
        return res
            .map((item) => MontessoriActivity.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMontessoriRepository] getActivities error: $e, using local fallback');
      }
    }

    return _fallback.getActivities(category: category, query: query);
  }

  @override
  Future<MontessoriActivity?> getActivityById(String id) async {
    try {
      final res = await _apiClient.get('/activities/montessori/$id');
      if (res is Map<String, dynamic>) {
        return MontessoriActivity.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HttpMontessoriRepository] getActivityById error: $e, using local fallback');
      }
    }

    return _fallback.getActivityById(id);
  }
}
