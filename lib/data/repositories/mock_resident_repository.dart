import '../../domain/entities/resident.dart';
import '../fixtures/resident_fixtures.dart';
import 'resident_repository.dart';

class MockResidentRepository implements ResidentRepository {
  final Map<String, Resident> _residents = {
    for (final r in ResidentFixtures.allResidents) r.id: r,
  };

  @override
  // [MICROSERVICE_INTEGRATION_POINT]: ResidentService - GET /api/v1/residents/{id}
  // TODO(microservice): Replace mock data with: final res = await apiClient.get('/api/v1/residents/$id');
  Future<Resident?> getResident(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _residents[id] ?? ResidentFixtures.margaretThompson;
  }

  @override
  // [MICROSERVICE_INTEGRATION_POINT]: ResidentService - GET /api/v1/residents
  // TODO(microservice): Replace mock data with: final res = await apiClient.get('/api/v1/residents');
  Future<List<Resident>> listResidents() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _residents.values.toList();
  }

  @override
  Future<void> updateResident(Resident resident) async {
    _residents[resident.id] = resident;
  }
}
