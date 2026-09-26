import '../../domain/entities/montessori_activity.dart';
import '../fixtures/montessori_fixtures.dart';
import 'montessori_repository.dart';

// [MICROSERVICE_INTEGRATION_POINT]: ActivityService - Mock Implementation
// Simulates /api/v1/activities/montessori responses using curated Montessori fixtures
class MockMontessoriRepository implements MontessoriRepository {
  final List<MontessoriActivity> _activities = List.from(MontessoriFixtures.activities);

  @override
  Future<List<MontessoriActivity>> getActivities({MontessoriCategory? category, String? query}) async {
    var result = List<MontessoriActivity>.from(_activities);
    if (category != null) {
      result = result.where((a) => a.category == category).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.summary.toLowerCase().contains(q) ||
            a.materials.any((m) => m.toLowerCase().contains(q));
      }).toList();
    }
    return result;
  }

  @override
  Future<MontessoriActivity?> getActivityById(String id) async {
    try {
      return _activities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
