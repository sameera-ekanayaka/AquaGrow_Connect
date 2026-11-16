import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/care/application/care_reminders_provider.dart';
import 'package:aquagrow_mobile/features/care/domain/care_reminder.dart';
import 'package:aquagrow_mobile/features/care/presentation/care_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareScreen widget tests', () {
    testWidgets('renders TabHeader, CareRemindersCard, and navigation tiles',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleReminders = [
        const CareReminder(
          id: 'r1',
          title: 'Clean the filter',
          frequencyLabel: 'weekly',
          intervalDays: 7,
          isCompleted: false,
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
            home: const Scaffold(body: CareScreen()),
          ),
        ),
      );

      // Care header
      expect(find.text('Care'), findsOneWidget);
      expect(find.text('LOOK AFTER YOUR PODS'), findsNothing);

      // Reminders card
      expect(find.text('Care reminders'), findsOneWidget);
      expect(find.text('Clean the filter'), findsOneWidget);

      // Navigation tiles
      expect(find.text('Hydroponic suppliers'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Pod simulator'), findsOneWidget);
    });
  });
}
