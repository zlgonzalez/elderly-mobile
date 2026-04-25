import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/local/resident_entity.dart';
import '../../data/local/care_log_entity.dart';
import '../../data/repositories/care_log_repository.dart';
import '../auth/auth_provider.dart';

// Provide Hive boxes
final residentsBoxProvider = FutureProvider<Box<ResidentEntity>>((ref) async {
  return Hive.openBox<ResidentEntity>('residents');
});

final careLogsBoxProvider = FutureProvider<Box<CareLogEntity>>((ref) async {
  return Hive.openBox<CareLogEntity>('careLogs');
});

final careLogRepositoryProvider = FutureProvider<CareLogRepository>((ref) async {
  final residentsBox = await ref.watch(residentsBoxProvider.future);
  final careLogsBox = await ref.watch(careLogsBoxProvider.future);
  final apiClient = ref.watch(apiClientProvider);
  final repo = CareLogRepository(
    residentsBox: residentsBox,
    careLogsBox: careLogsBox,
    apiClient: apiClient,
  );
  await repo.seedInitialData();
  return repo;
});

final residentsProvider = FutureProvider<List<ResidentEntity>>((ref) async {
  final repo = await ref.watch(careLogRepositoryProvider.future);
  return repo.getAllResidents();
});

final residentLogsProvider = FutureProvider.family<List<CareLogEntity>, String>((ref, residentId) async {
  final repo = await ref.watch(careLogRepositoryProvider.future);
  return repo.getLogsForResident(residentId);
});
