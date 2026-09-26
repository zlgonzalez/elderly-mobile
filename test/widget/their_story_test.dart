import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/their_story/their_story_screen.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('TheirStoryScreen displays biography, philosophy, milestone sequence, and memory action', (tester) async {
    bool addMemoryTapped = false;

    await tester.pumpWidget(
      createPlatformTestWidget(
        child: TheirStoryScreen(
          onAddMemoryTap: () {
            addMemoryTapped = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Header
    expect(find.text("Margaret Thompson's Story"), findsOneWidget);
    expect(find.text('Margaret Thompson'), findsOneWidget);
    expect(find.text('B.Ed., University of Vermont, 1965'), findsOneWidget);

    // Verify Quote and Career info
    expect(find.textContaining('Every child is a garden waiting to bloom'), findsOneWidget);

    // Verify Milestones
    expect(find.text('1965'), findsOneWidget);
    expect(find.text('Wedding Day 1965'), findsOneWidget);
    expect(find.text('1998'), findsOneWidget);
    expect(find.text('Vermont Educator of the Year'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);
    expect(find.text('Retired after 35 years'), findsOneWidget);
    expect(find.text('2018'), findsOneWidget);
    expect(find.text('Lost Harold'), findsOneWidget);

    // Verify Action button (scroll until visible in SingleChildScrollView)
    final addMemoryBtn = find.text('Add to Memory Box');
    expect(addMemoryBtn, findsOneWidget);
    await tester.scrollUntilVisible(addMemoryBtn, 200);
    await tester.pumpAndSettle();

    await tester.tap(addMemoryBtn);
    await tester.pump();

    expect(addMemoryTapped, isTrue);
  });
}
