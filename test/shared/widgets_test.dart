import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('SensorTile shows label, value and caption', (tester) async {
    await tester.pumpWidget(
      _wrap(const SensorTile(label: 'pH', value: '6.2', caption: 'Target 5.5–6.5')),
    );

    expect(find.text('pH'), findsOneWidget);
    expect(find.text('6.2'), findsOneWidget);
    expect(find.text('Target 5.5–6.5'), findsOneWidget);
  });

  testWidgets('showConfirmDialog returns false on cancel and true on confirm', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Log out?',
                message: 'You will need to sign in again.',
                confirmLabel: 'Log out',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('EmptyView shows its title and message', (tester) async {
    await tester.pumpWidget(
      _wrap(const EmptyView(title: 'No alerts', message: 'Your pods are healthy.')),
    );

    expect(find.text('No alerts'), findsOneWidget);
    expect(find.text('Your pods are healthy.'), findsOneWidget);
  });
}
