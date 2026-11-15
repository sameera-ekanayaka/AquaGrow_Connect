import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:aquagrow_mobile/features/care/presentation/widgets/care_reminder_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareReminderItemTile', () {
    final referenceNow = DateTime(2026, 11, 15, 10);

    testWidgets('renders title, frequency, and status badge', (tester) async {
      final reminder = CareReminder(
        id: 'r1',
        title: 'Clean the filter',
        frequencyLabel: 'weekly',
        intervalDays: 7,
        lastCompletedAt: referenceNow.subtract(const Duration(days: 7)),
      );

      var toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CareReminderItemTile(
              reminder: reminder,
              referenceNow: referenceNow,
              onToggle: (_) => toggled = true,
            ),
          ),
        ),
      );

      expect(find.text('Clean the filter'), findsOneWidget);
      expect(find.text('weekly'), findsOneWidget);
      expect(find.text('Due today'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('shows completed status badge and strikethrough text',
        (tester) async {
      final reminder = CareReminder(
        id: 'r1',
        title: 'Top up nutrients',
        frequencyLabel: 'every 10 days',
        intervalDays: 10,
        lastCompletedAt: referenceNow,
        isCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CareReminderItemTile(
              reminder: reminder,
              referenceNow: referenceNow,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Top up nutrients'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('Top up nutrients'));
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));
    });
  });
}
