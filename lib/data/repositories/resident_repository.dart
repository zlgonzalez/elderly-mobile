import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/resident.dart';
import 'http_resident_repository.dart';
import 'mock_resident_repository.dart';

abstract class ResidentRepository {
  // [MICROSERVICE_INTEGRATION_POINT]: PatientService - GET /api/v1/patients/{id}
  Future<Resident?> getResident(String id);

  // [MICROSERVICE_INTEGRATION_POINT]: PatientService - GET /api/v1/patients
  Future<List<Resident>> listResidents();

  Future<void> updateResident(Resident resident);
}

final residentRepositoryProvider = Provider<ResidentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockResidentRepository();
  }
  return HttpResidentRepository(apiClient: ref.watch(apiClientProvider));
});
