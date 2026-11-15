import 'package:aquagrow_mobile/features/insights/presentation/widgets/shake_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShakeFeedback', () {
    testWidgets('displays "Refreshed" snackbar with refresh icon',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => ShakeFeedback.show(context),
                  child: const Text('Trigger Refresh'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Refreshed'), findsNothing);

      await tester.tap(find.text('Trigger Refresh'));
      await tester.pump(); // Start snackbar animation

      expect(find.text('Refreshed'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('does not throw when context has no ScaffoldMessenger',
        (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(() => ShakeFeedback.show(context), returnsNormally);
            return const SizedBox();
          },
        ),
      );
    });
  });
}
