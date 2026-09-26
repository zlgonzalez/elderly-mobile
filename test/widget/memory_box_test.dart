import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/memory_box/memory_box_screen.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('MemoryBoxScreen renders memories, format filters, and can open AddMemorySheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createPlatformTestWidget(
        child: const MemoryBoxScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and count
    expect(find.text('Memory Box'), findsOneWidget);
    expect(find.textContaining('memories preserved'), findsOneWidget);

    // Verify Memories in feed
    expect(find.text('Wedding Day 1965'), findsOneWidget);
    expect(find.text('Teaching Career'), findsOneWidget);
    expect(find.text('Garden in Full Bloom'), findsOneWidget);

    // Verify Format filters
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Photo'), findsWidgets);
    expect(find.text('Story'), findsWidgets);
    expect(find.text('Letter'), findsWidgets);
    expect(find.text('Video'), findsWidgets);

    // Open Add Memory Modal
    final addBtn = find.widgetWithText(ElevatedButton, 'Add Memory');
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify Modal elements
    expect(find.text('Add to Memory Box'), findsOneWidget);
    expect(find.text('Title *'), findsOneWidget);
    expect(find.text('Save Memory'), findsOneWidget);

    // Enter title and save
    await tester.enterText(find.widgetWithText(TextFormField, 'Title *'), 'Special Autumn Walk');
    await tester.pump();

    await tester.tap(find.text('Save Memory'));
    await tester.pumpAndSettle();

    // Verify new item appears in list
    expect(find.text('Special Autumn Walk'), findsOneWidget);
  });
}
