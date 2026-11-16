import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/location/presentation/widgets/location_rationale_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildUnderTest({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: child,
      ),
    );
  }

  group('LocationRationaleDialog widget tests', () {
    testWidgets('shows title and usage explanation text', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildUnderTest(child: const LocationRationaleDialog()),
      );
      await tester.pump();

      expect(find.text('Use your location?'), findsOneWidget);
      expect(
        find.textContaining('AquaGrow Connect uses your location'),
        findsOneWidget,
      );
      expect(find.textContaining('real-time local weather'), findsOneWidget);
      expect(find.textContaining('hydroponic suppliers'), findsOneWidget);
    });

    testWidgets('Allow button pops navigator with true', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool? dialogResult;
      await tester.pumpWidget(
        buildUnderTest(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                dialogResult = await LocationRationaleDialog.show(ctx);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Use your location?'), findsOneWidget);

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(find.text('Use your location?'), findsNothing);
    });

    testWidgets('Not now button pops navigator with false', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool? dialogResult;
      await tester.pumpWidget(
        buildUnderTest(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                dialogResult = await LocationRationaleDialog.show(ctx);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Use your location?'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
      expect(find.text('Use your location?'), findsNothing);
    });
  });
}
