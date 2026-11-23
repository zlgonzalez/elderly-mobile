import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../data/repositories/care_tasks_repository.dart';
import '../../domain/entities/regimen_plan.dart';
import '../../main.dart';
import '../care_tasks/care_tasks_provider.dart';
import '../care_tasks/regimen_batch_provider.dart';
import '../care_tasks/widgets/regimen_preview_sheet.dart';
import '../family_portal/resident_provider.dart';
import 'sidebar_nav.dart';

class ResponsiveLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ResponsiveLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends ConsumerState<ResponsiveLayout>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final residentId = ref.read(residentProvider).id;
      ref.read(regimenBatchProvider.notifier).refreshActiveJob(residentId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final residentId = ref.read(residentProvider).id;
      ref.read(regimenBatchProvider.notifier).refreshActiveJob(residentId);
    }
  }

  Future<void> _openBatchPreview(RegimenBatchCompletionEvent event) async {
    if (ref.read(residentProvider).id != event.residentId) {
      await ref.read(residentProvider.notifier).selectById(event.residentId);
    }
    widget.navigationShell.goBranch(3);

    var plan = event.job.plan;
    if (plan == null) {
      await ref
          .read(regimenBatchProvider.notifier)
          .refreshActiveJob(event.residentId);
      plan = ref
          .read(regimenBatchProvider)
          .jobForResident(event.residentId)
          ?.plan;
      if (plan == null) {
        try {
          final hydrated = await ref
              .read(careTasksRepositoryProvider)
              .getBatchJob(event.residentId, event.job.id);
          plan = hydrated.plan;
        } catch (_) {}
      }
    }
    if (plan == null) return;
    ref.read(careTasksProvider.notifier).setPreviewPlanFromBatch(plan);

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;
    await showModalBottomSheet<void>(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const RegimenPreviewSheet(),
    );
  }

  void _handleCompletionEvent(RegimenBatchCompletionEvent event) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    if (event.job.status == BatchJobStatus.completed) {
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            event.job.jobType == BatchJobType.refinement
                ? 'Refined 7-day regimen is ready for review.'
                : '7-day Montessori regimen is ready for review.',
          ),
          action: SnackBarAction(
            label: 'Review Plan',
            onPressed: () => _openBatchPreview(event),
          ),
        ),
      );
    } else if (event.job.status == BatchJobStatus.failed) {
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            event.job.errorMessage?.isNotEmpty == true
                ? 'Regimen generation failed: ${event.job.errorMessage}'
                : 'Regimen generation failed. Open Care Tasks to retry or use baseline.',
          ),
          action: SnackBarAction(
            label: 'Open Tasks',
            onPressed: () async {
              if (ref.read(residentProvider).id != event.residentId) {
                await ref
                    .read(residentProvider.notifier)
                    .selectById(event.residentId);
              }
              widget.navigationShell.goBranch(3);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(
      residentProvider.select((r) => r.id),
      (prev, next) {
        if (prev != next) {
          ref.read(regimenBatchProvider.notifier).refreshActiveJob(next);
        }
      },
    );

    ref.listen<RegimenBatchCompletionEvent?>(
      regimenBatchProvider.select((s) => s.lastCompletionEvent),
      (prev, next) {
        if (next != null && next.eventId != prev?.eventId) {
          _handleCompletionEvent(next);
        }
      },
    );

    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width >= 800;

    if (isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            SidebarNav(navigationShell: widget.navigationShell),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: widget.navigationShell,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.navigationShell,
    );
  }
}
