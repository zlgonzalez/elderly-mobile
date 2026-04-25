import 'package:hive/hive.dart';
import '../../core/network/api_client.dart';
import '../local/care_log_entity.dart';
import '../local/resident_entity.dart';

class CareLogRepository {
  final Box<ResidentEntity> residentsBox;
  final Box<CareLogEntity> careLogsBox;
  final ApiClient apiClient;

  CareLogRepository({
    required this.residentsBox,
    required this.careLogsBox,
    required this.apiClient,
  });

  // Fetch all residents from local storage
  Future<List<ResidentEntity>> getAllResidents() async {
    return residentsBox.values.toList();
  }

  // Get a specific resident
  Future<ResidentEntity?> getResident(String remoteId) async {
    try {
      return residentsBox.values.firstWhere((r) => r.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  // Save a new care log locally
  Future<void> saveCareLog(CareLogEntity log) async {
    await careLogsBox.add(log);

    // Trigger background sync (simplified)
    _syncPendingLogs();
  }

  // Get logs for a specific resident
  Future<List<CareLogEntity>> getLogsForResident(String residentId) async {
    final logs = careLogsBox.values
        .where((log) => log.residentId == residentId)
        .toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  // Background sync logic
  Future<void> _syncPendingLogs() async {
    final pendingLogs = careLogsBox.values.where((log) => !log.isSynced).toList();

    for (final log in pendingLogs) {
      try {
        // Mock API call
        // final response = await apiClient.post('/care-logs', body: {...});
        // log.remoteId = response['id'];
        log.isSynced = true;
        await log.save();
      } catch (e) {
        // Sync failed, will retry next time
      }
    }
  }

  // Seed initial data for testing
  Future<void> seedInitialData() async {
    if (residentsBox.isEmpty) {
      final residents = [
        ResidentEntity()
          ..remoteId = 'res_1'
          ..firstName = 'Alice'
          ..lastName = 'Smith'
          ..roomNumber = '101'
          ..careLevel = 'High',
        ResidentEntity()
          ..remoteId = 'res_2'
          ..firstName = 'Robert'
          ..lastName = 'Johnson'
          ..roomNumber = '104'
          ..careLevel = 'Medium',
      ];

      for (final resident in residents) {
        await residentsBox.add(resident);
      }
    }
  }
}
