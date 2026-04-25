import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/resident_entity.dart';
import '../../data/local/care_log_entity.dart';

class DashboardData {
  final List<ResidentEntity> residents;
  final List<CareLogEntity> recentLogs;
  final int pendingLogsCount;

  DashboardData({
    required this.residents,
    required this.recentLogs,
    required this.pendingLogsCount,
  });
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  // Mock data for now until Isar repository logic is fully implemented in Phase 6
  await Future.delayed(const Duration(milliseconds: 800));

  final residents = [
    ResidentEntity()
      ..remoteId = 'res_1'
      ..firstName = 'Alice'
      ..lastName = 'Smith'
      ..roomNumber = '101'
      ..careLevel = 'High'
      ..lastCareLogSummary = 'Participated in gardening activity.'
      ..lastCareLogTime = DateTime.now().subtract(const Duration(hours: 2)),
    ResidentEntity()
      ..remoteId = 'res_2'
      ..firstName = 'Robert'
      ..lastName = 'Johnson'
      ..roomNumber = '104'
      ..careLevel = 'Medium'
      ..lastCareLogSummary = 'Resting comfortably.'
      ..lastCareLogTime = DateTime.now().subtract(const Duration(hours: 4)),
  ];

  final logs = [
    CareLogEntity()
      ..residentId = 'res_1'
      ..caregiverId = 'user_2'
      ..timestamp = DateTime.now().subtract(const Duration(minutes: 45))
      ..category = 'Meaningful Work'
      ..notes = 'Alice helped with the flower arrangements.',
  ];

  return DashboardData(
    residents: residents,
    recentLogs: logs,
    pendingLogsCount: 3,
  );
});
