import '../../domain/entities/resident.dart';

abstract class ResidentRepository {
  // [MICROSERVICE_INTEGRATION_POINT]: ResidentService - GET /api/v1/residents/{id}
  Future<Resident?> getResident(String id);

  // [MICROSERVICE_INTEGRATION_POINT]: ResidentService - GET /api/v1/residents
  Future<List<Resident>> listResidents();

  Future<void> updateResident(Resident resident);
}
