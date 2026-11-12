import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../family_portal/resident_provider.dart';
import 'care_tasks_provider.dart';
import 'widgets/capability_intake_sheet.dart';
import 'widgets/generation_progress_sheet.dart';
import 'widgets/regimen_preview_sheet.dart';

bool canManageRegimenFor(UserProfile? user) {
  return user != null &&
      (user.role == UserRole.visitingCaregiver || user.role == UserRole.admin);
}

Future<void> startGenerateRegimenFlow(
  BuildContext context,
  WidgetRef ref, {
  bool openRefine = false,
}) async {
  var resident = ref.read(residentProvider);
  if (!resident.hasRequiredRegimenCapabilities) {
    final result = await showModalBottomSheet<CapabilityIntakeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CapabilityIntakeSheet(resident: resident),
    );
    if (result == null || !context.mounted) return;
    try {
      resident = await ref.read(residentProvider.notifier).updateCapabilities(
            cognitiveCapability: result.cognitiveCapability,
            physicalCapability: result.physicalCapability,
            cognitiveStage: result.cognitiveStage,
            motorLimitations: result.motorLimitations,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save resident capabilities: $e')),
      );
      return;
    }
  }
  if (!context.mounted) return;

  final navigator = Navigator.of(context);
  var progressSheetOpen = true;
  showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GenerationProgressSheet(resident: resident),
  ).whenComplete(() {
    progressSheetOpen = false;
  });

  try {
    final plan = await ref.read(careTasksProvider.notifier).generateRegimen(
          resident: resident,
          autoApply: false,
        );
    if (progressSheetOpen && navigator.canPop()) {
      navigator.pop();
    }
    if (!context.mounted) return;
    if (plan != null) {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => RegimenPreviewSheet(
          showRefinementInitially: openRefine,
        ),
      );
    }
  } catch (e) {
    if (progressSheetOpen && navigator.canPop()) {
      navigator.pop();
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not generate regimen: $e')),
    );
  }
}
