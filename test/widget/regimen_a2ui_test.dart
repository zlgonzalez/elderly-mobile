import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/domain/entities/care_task.dart';
import 'package:elderly_mobile/domain/entities/regimen_plan.dart';
import 'package:elderly_mobile/presentation/a2ui/regimen_a2ui_surface.dart';
import 'package:elderly_mobile/presentation/a2ui/step_text_formatter.dart';

void main() {
  group('parseFacilitationStep', () {
    test('strips single, duplicated, and labeled step number prefixes', () {
      final p1 = parseFacilitationStep(
        '1. Prepare Tray & Seating: Position the resident comfortably.',
      );
      expect(p1.heading, 'Prepare Tray & Seating');
      expect(p1.body, 'Position the resident comfortably.');
      expect(p1.cleanedText.startsWith('1.'), isFalse);

      final p2 = parseFacilitationStep(
        '1. 1. Sit Beside & Invite: Offer two concrete choices.',
      );
      expect(p2.heading, 'Sit Beside & Invite');
      expect(p2.body, 'Offer two concrete choices.');

      final p3 = parseFacilitationStep(
        'Step 3 - Gently demonstrate one motion at a time.',
      );
      expect(p3.heading, isNull);
      expect(p3.body, 'Gently demonstrate one motion at a time.');
    });
  });

  group('RegimenA2uiSurface', () {
    RegimenPlan buildSamplePlan() {
      final now = DateTime.utc(2026, 11, 23);
      return RegimenPlan(
        id: 'plan_a2ui_test',
        residentId: 'res_margaret',
        weekStartDate: now,
        generatedAt: now,
        planStatus: 'preview',
        generationSource: RegimenGenerationSource.kuboAgent,
        safetyFlags: const ['Use stabilized weighted tray for mild tremors'],
        scorecard: const ClinicalScorecard(
          compositeScore: 91,
          cognitiveAlignmentScore: 23,
          physicalAccessibilityScore: 18,
          purposefulEngagementScore: 18,
          safetyControlOfErrorScore: 14,
          modalityBalanceScore: 18,
          feedback: 'Well-balanced 7-day Montessori regimen.',
        ),
        items: const [
          CareTask(
            id: 'task_day1',
            residentId: 'res_margaret',
            dayNumber: 1,
            title: 'Sensory Fabric Swatch Matching',
            description: 'Tactile matching on a rimmed birch tray.',
            time: '10:00 AM',
            category: TaskCategory.activity,
            montessoriDomain: 'Sensorial',
            materialsTraySetup: 'Weighted birch tray with non-skid mat',
            materials: [
              '12x16 in rimmed birch tray',
              '6 paired cotton & linen fabric swatches',
            ],
            steps: [
              '1. Prepare Tray & Seating: Place the birch tray on a non-skid mat.',
              '2. 2. Sit Beside & Invite: Offer linen and corduroy swatches.',
            ],
            scriptPrompt: 'Which fabric feels softer to you today?',
            dignityTip: 'Wait 5-10 seconds before offering a gentle gesture.',
            safetyComfort: 'Ensure seated elbow-height table posture.',
            historicalConnection: 'Connects to sewing and textile memories.',
          ),
          CareTask(
            id: 'task_day2',
            residentId: 'res_margaret',
            dayNumber: 2,
            title: 'Botanical Leaf Classification',
            description: 'Large cork-backed botanical specimens.',
            time: '2:00 PM',
            category: TaskCategory.physical,
            montessoriDomain: 'Practical Life',
            materials: ['6 laminated leaf cards'],
            steps: ['1. Arrange Cards: Lay 3 leaf cards on the left.'],
          ),
        ],
      );
    }

    testWidgets(
      'forPlan renders A2uiSurface with scorecard, day switcher, and deduplicated steps',
      (tester) async {
        final plan = buildSamplePlan();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RegimenA2uiSurface.forPlan(plan: plan),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(A2uiSurface), findsOneWidget);
        expect(find.byKey(const Key('a2ui_clinical_scorecard')), findsOneWidget);
        expect(find.text('91'), findsOneWidget);
        expect(find.text('Cognitive: 23'), findsOneWidget);
        expect(find.text('Sensory Fabric Swatch Matching'), findsOneWidget);

        // Must never render duplicated "1. 1." or raw "1. " inside step body
        expect(find.textContaining('1. 1.'), findsNothing);
        expect(find.textContaining('2. 2.'), findsNothing);
        expect(find.text('Prepare Tray & Seating'), findsOneWidget);
        expect(
          find.text('Place the birch tray on a non-skid mat.'),
          findsOneWidget,
        );
        expect(find.text('Sit Beside & Invite'), findsOneWidget);

        // Switch to Day 2 via thumb-friendly day pill
        expect(find.text('Botanical Leaf Classification'), findsNothing);
        await tester.tap(find.byKey(const Key('a2ui_day_pill_2')));
        await tester.pumpAndSettle();

        expect(find.text('Botanical Leaf Classification'), findsOneWidget);
        expect(find.text('Arrange Cards'), findsOneWidget);

        // Switch to All Days
        await tester.tap(find.byKey(const Key('a2ui_day_pill_all')));
        await tester.pumpAndSettle();
        expect(find.text('Sensory Fabric Swatch Matching'), findsOneWidget);
        expect(find.text('Botanical Leaf Classification'), findsOneWidget);
      },
    );

    testWidgets(
      'forTask renders applied task detail card with checkable materials and A2UI actions',
      (tester) async {
        final dispatched = <A2uiRendererAction>[];
        const task = CareTask(
          id: 'task_applied_1',
          residentId: 'res_margaret',
          dayNumber: 1,
          title: 'Warm Herb Sachet Assembly',
          description: 'Calming lavender & rosemary sachets.',
          time: '10:30 AM',
          category: TaskCategory.purposeful,
          montessoriDomain: 'Practical Life',
          materialsTraySetup: 'Non-skid tray with wide-mouth muslin sachets',
          materials: ['4 cotton muslin sachets', 'Wide-bowl padded scoop'],
          steps: [
            '1. Prepare Workstation: Place sachets on the left and jars on the right.',
            '2. Invite Choice: Ask whether they prefer lavender or rosemary first.',
          ],
          scriptPrompt: 'Would you like to fill the lavender sachet first?',
          dignityTip: 'Honor their pace and pause for shared memories.',
          safetyComfort: 'Keep jars stabilized on non-skid silicone mat.',
          historicalConnection: 'Tied to decades of backyard herb gardening.',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RegimenA2uiSurface.forTask(
                  task: task,
                  onAction: dispatched.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(A2uiSurface), findsOneWidget);
        expect(find.byKey(const Key('a2ui_activity_detail_card')), findsOneWidget);
        expect(find.text('Warm Herb Sachet Assembly'), findsOneWidget);
        expect(find.text('Prepare Workstation'), findsOneWidget);
        expect(find.textContaining('1. 1.'), findsNothing);

        // Tap a material chip to check it off
        await tester.tap(find.text('4 cotton muslin sachets'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.check_box), findsOneWidget);

        // Tap A2UI action buttons
        await tester.ensureVisible(find.text('Mark Completed'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark Completed'));
        await tester.pumpAndSettle();
        expect(dispatched.length, 1);
        expect(dispatched.first.name, 'mark_completed');
        expect(dispatched.first.context['taskId'], 'task_applied_1');

        await tester.ensureVisible(find.text('Skip'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        expect(dispatched.length, 2);
        expect(dispatched.last.name, 'skip_activity');
      },
    );
  });
}
