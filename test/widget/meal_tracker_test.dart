import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elderly_mobile/presentation/health_vitals/widgets/food_library_sheet.dart';
import 'package:elderly_mobile/presentation/health_vitals/widgets/meal_tracker_widget.dart';
import '../platform/platform_harness.dart';

void main() {
  testWidgets('MealTrackerWidget displays nutrition targets, opens food library, adds items, and logs meal', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createPlatformTestWidget(
        child: const SingleChildScrollView(
          child: MealTrackerWidget(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Macro bars
    expect(find.text("Today's Nutrition & Meals"), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);

    // Verify Meal Type Chips
    expect(find.text('Breakfast 🌅'), findsWidgets);
    expect(find.text('Lunch ☀️'), findsWidgets);

    // Open Food Library (35+)
    final libBtn = find.text('Food Library (35+)');
    expect(libBtn, findsOneWidget);
    await tester.tap(libBtn);
    await tester.pumpAndSettle();

    // Search for Oatmeal
    expect(find.text('Food Library'), findsOneWidget);
    final searchInput = find.descendant(
      of: find.byType(FoodLibrarySheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchInput, 'Oatmeal');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Oatmeal'), findsOneWidget);
    final addBtn = find.widgetWithText(ElevatedButton, 'Add');
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify Oatmeal is selected in chips
    expect(find.widgetWithText(Chip, 'Oatmeal (1 cup)'), findsOneWidget);

    // Tap Save Meal Log
    final saveMealBtn = find.text('Save Meal Log');
    expect(saveMealBtn, findsOneWidget);
    await tester.tap(saveMealBtn);
    await tester.pumpAndSettle();

    // Verify confirmation and today's meal updated
    expect(find.textContaining('logged'), findsWidgets);
  });
}
