import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/care_tasks_repository.dart';
import '../repositories/health_vitals_repository.dart';
import '../repositories/meal_repository.dart';
import '../repositories/memory_repository.dart';
import '../repositories/mock_care_tasks_repository.dart';
import '../repositories/mock_health_vitals_repository.dart';
import '../repositories/mock_meal_repository.dart';
import '../repositories/mock_memory_repository.dart';
import '../repositories/mock_mood_repository.dart';
import '../repositories/mood_repository.dart';
import '../../presentation/family_portal/resident_provider.dart';

class ProfileStorageManager {
  final Ref _ref;

  ProfileStorageManager(this._ref);

  void resetAllToDemo() {
    final careRepo = _ref.read(careTasksRepositoryProvider);
    if (careRepo is MockCareTasksRepository) {
      careRepo.resetToDemo('res_margaret');
      careRepo.resetToDemo('res_robert');
      careRepo.resetToDemo('res_dorothy');
    }

    final memRepo = _ref.read(memoryRepositoryProvider);
    if (memRepo is MockMemoryRepository) {
      memRepo.resetToDemo('res_margaret');
      memRepo.resetToDemo('res_robert');
      memRepo.resetToDemo('res_dorothy');
    }

    final vitalsRepo = _ref.read(healthVitalsRepositoryProvider);
    if (vitalsRepo is MockHealthVitalsRepository) {
      vitalsRepo.resetToDemo('res_margaret');
      vitalsRepo.resetToDemo('res_robert');
      vitalsRepo.resetToDemo('res_dorothy');
    }

    final mealRepo = _ref.read(mealRepositoryProvider);
    if (mealRepo is MockMealRepository) {
      mealRepo.resetToDemo('res_margaret');
      mealRepo.resetToDemo('res_robert');
      mealRepo.resetToDemo('res_dorothy');
    }

    final moodRepo = _ref.read(moodRepositoryProvider);
    if (moodRepo is MockMoodRepository) {
      moodRepo.resetToDemo('res_margaret');
      moodRepo.resetToDemo('res_robert');
      moodRepo.resetToDemo('res_dorothy');
    }

    _ref.read(residentProvider.notifier).resetToDemo();
  }
}

final profileStorageManagerProvider = Provider<ProfileStorageManager>((ref) {
  return ProfileStorageManager(ref);
});
