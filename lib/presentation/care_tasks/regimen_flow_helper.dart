import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../family_portal/resident_provider.dart';
import 'regimen_batch_provider.dart';
import 'widgets/capability_intake_sheet.dart';

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

  final batchState = ref.read(regimenBatchProvider);
  if (batchState.hasActiveJobFor(resident.id)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A regimen generation job is already running for this resident.',
        ),
      ),
    );
    return;
  }

  try {
    final job = await ref
        .read(regimenBatchProvider.notifier)
        .enqueueGeneration(resident);
    if (!context.mounted) return;
    if (job != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Started background 7-day regimen generation for ${resident.name}. You can keep using the app.',
          ),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not start regimen generation: $e')),
    );
  }
}
