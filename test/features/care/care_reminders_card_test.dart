import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/care/application/care_reminders_provider.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:aquagrow_mobile/features/care/presentation/widgets/care_reminders_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareRemindersCard widget tests', () {
    testWidgets('renders header, counter, and reminder list items',
        (tester) async {
      final sampleReminders = [
        const CareReminder(
          id: 'r1',
          title: 'Clean the filter',
          frequencyLabel: 'weekly',
          intervalDays: 7,
          isCompleted: false,
        ),
        const CareReminder(
          id: 'r2',
          title: 'Top up nutrients',
          frequencyLabel: 'every 10 days',
          intervalDays: 10,
          isCompleted: true,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          careRemindersProvider.overrideWith(
            (ref) => CareRemindersNotifier(initialReminders: sampleReminders),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(child: CareRemindersCard()),
            ),
          ),
        ),
      );

      expect(find.text('Care reminders'), findsOneWidget);
      expect(find.text('1 of 2 done'), findsOneWidget);
      expect(find.text('Clean the filter'), findsOneWidget);
      expect(find.text('Top up nutrients'), findsOneWidget);

      // Tapping uncompleted checkbox toggles it
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(find.text('2 of 2 done'), findsOneWidget);
      expect(
        find.textContaining('Completed "Clean the filter"'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty placeholder when reminder list is empty',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          careRemindersProvider.overrideWith(
            (ref) => CareRemindersNotifier(initialReminders: []),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: CareRemindersCard()),
          ),
        ),
      );

      expect(find.text('0 of 0 done'), findsOneWidget);
      expect(find.text('No care reminders scheduled'), findsOneWidget);
    });
  });
}
