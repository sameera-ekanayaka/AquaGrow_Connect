import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('CropsScreen (My Pods)', () {
    late PodSimulator sim;

    setUp(() {
      sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10));
    });

    tearDown(() {
      sim.dispose();
    });

    testWidgets('renders two pod cards with crop names using testApp()',
        (tester) async {
      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();

      // Switch to Crops tab
      await tester.tap(find.byTooltip('Crops'));
      await tester.pumpAndSettle();

      expect(find.text('My Pods'), findsOneWidget);
      expect(find.text('Genovese Basil'), findsOneWidget);
      expect(find.text('Baby Spinach'), findsOneWidget);
      expect(find.text('Add a pod'), findsOneWidget);
    });

    Future<void> openAddPod(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();
      await tester.tap(find.byTooltip('Crops'));
      await tester.pumpAndSettle();

      final addBtn = find.text('Add a pod');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
    }

    Future<void> fillAndSubmit(
      WidgetTester tester, {
      String name = 'Pod Gamma',
      String room = 'Balcony',
      String serial = 'AQG-2026-0042',
    }) async {
      await tester.enterText(find.byKey(const Key('add-pod-name')), name);
      await tester.enterText(find.byKey(const Key('add-pod-room')), room);
      await tester.enterText(find.byKey(const Key('add-pod-serial')), serial);
      await tester.tap(find.byKey(const Key('add-pod-submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('Add a pod opens the form', (tester) async {
      await openAddPod(tester);

      expect(find.text('Pod name'), findsOneWidget);
      expect(find.text('Room'), findsOneWidget);
      expect(find.text('Serial number'), findsOneWidget);
      expect(find.text('NFT'), findsOneWidget);
      expect(find.text('DWC'), findsOneWidget);
      expect(find.text('Add pod'), findsOneWidget);
    });

    testWidgets('adding a pod shows it on My Pods and selects it',
        (tester) async {
      await openAddPod(tester);
      await tester.tap(find.text('DWC'));
      await tester.pumpAndSettle();
      expect(find.text('DWC: The roots sit in the water.'), findsOneWidget);

      await fillAndSubmit(tester);

      expect(find.text('Pod name'), findsNothing);
      expect(find.text('Pod Gamma added'), findsOneWidget);
      expect(sim.pods, hasLength(3));
      final added = sim.pods.last;
      expect(added.name, 'Pod Gamma');
      expect(added.room, 'Balcony');
      expect(added.batch, isNull);
      await tester.ensureVisible(find.text('Tap to plant a crop'));
      expect(find.text('Tap to plant a crop'), findsOneWidget);
      // The empty pod's card is titled with the pod's own name.
      expect(find.text('Pod Gamma'), findsOneWidget);
      expect(find.text('Balcony'), findsOneWidget);
    });

    testWidgets('empty fields show what is missing and add nothing',
        (tester) async {
      await openAddPod(tester);
      await tester.tap(find.byKey(const Key('add-pod-submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('Pod name is required, for example Pod Gamma'),
        findsOneWidget,
      );
      expect(
        find.text('Room is required, for example Kitchen'),
        findsOneWidget,
      );
      expect(find.text('Serial number is required'), findsOneWidget);
      expect(sim.pods, hasLength(2));
    });

    testWidgets('after a failed try, typing clears that field error',
        (tester) async {
      await openAddPod(tester);
      await tester.tap(find.byKey(const Key('add-pod-submit')));
      await tester.pumpAndSettle();
      const nameError = 'Pod name is required, for example Pod Gamma';
      expect(find.text(nameError), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('add-pod-name')),
        'Pod Gamma',
      );
      await tester.pumpAndSettle();

      expect(find.text(nameError), findsNothing);
      expect(
        find.text('Room is required, for example Kitchen'),
        findsOneWidget,
      );
    });

    testWidgets('a serial number already used shows under the field',
        (tester) async {
      sim.addPod(name: 'Pod Gamma', room: 'Balcony', serialNumber: 'AQG-1234');
      await openAddPod(tester);

      await fillAndSubmit(tester, name: 'Pod Delta', serial: 'aqg-1234');

      expect(
        find.text('This serial number is already registered.'),
        findsOneWidget,
      );
      expect(find.text('Pod name'), findsOneWidget);
      expect(sim.pods, hasLength(3));
    });

    testWidgets('Close leaves the pods unchanged', (tester) async {
      await openAddPod(tester);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Pod name'), findsNothing);
      expect(sim.pods, hasLength(2));
    });

    testWidgets('renders grid layout on wide screens (>= 600px)',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(sim: sim));
      await tester.pump();

      await tester.tap(find.byTooltip('Crops'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Genovese Basil'), findsOneWidget);
      expect(find.text('Baby Spinach'), findsOneWidget);
    });

    testWidgets('a new user with no pods can add the first one',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final empty = PodSimulator(
        seeds: const [],
        clock: () => DateTime(2026, 11, 15, 10),
      );
      addTearDown(empty.dispose);

      await tester.pumpWidget(testApp(sim: empty));
      await tester.pump();
      await tester.tap(find.byTooltip('Crops'));
      await tester.pumpAndSettle();

      expect(find.text('No pods yet'), findsOneWidget);
      await tester.tap(find.text('Add a pod'));
      await tester.pumpAndSettle();
      await fillAndSubmit(tester);

      expect(find.text('No pods yet'), findsNothing);
      expect(find.text('Pod Gamma added'), findsOneWidget);
      expect(empty.pods.single.name, 'Pod Gamma');
    });

    testWidgets('shows empty state when pods list is empty', (tester) async {
      await tester.pumpWidget(
        testApp(sim: sim),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Crops'));
      await tester.pumpAndSettle();

      expect(find.text('My Pods'), findsOneWidget);
    });

    testWidgets('tapping an empty pod plants the chosen crop', (tester) async {
      await openAddPod(tester);
      await fillAndSubmit(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final podCard = find.text('Tap to plant a crop');
      await tester.ensureVisible(podCard);
      await tester.tap(podCard);
      await tester.pumpAndSettle();
      expect(find.text('Choose a crop'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Plant Sweet Mint'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a crop'), findsNothing);
      expect(find.text('Sweet Mint planted in Pod Gamma'), findsOneWidget);
      final gamma = sim.pods.firstWhere((p) => p.name == 'Pod Gamma');
      expect(gamma.batch?.cropName, 'Sweet Mint');
      expect(gamma.batch?.daysToHarvest, 35);
    });

    testWidgets('a name already used by a pod is refused', (tester) async {
      await openAddPod(tester);
      await fillAndSubmit(tester, name: 'Pod Alpha');

      expect(
        find.text(
          'You already have a pod called Pod Alpha. Pick another name.',
        ),
        findsOneWidget,
      );
      expect(sim.pods, hasLength(2));
    });

    testWidgets('deleting a pod lets its name and serial number be reused',
        (tester) async {
      await openAddPod(tester);
      await fillAndSubmit(
        tester,
        name: 'Pod Gamma',
        room: 'Balcony',
        serial: 'AQG-REUSE-1',
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(sim.pods, hasLength(3));

      // Delete Pod Gamma from the empty pod sheet.
      final podCard = find.text('Tap to plant a crop');
      await tester.ensureVisible(podCard);
      await tester.tap(podCard);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this pod'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete pod'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(sim.pods, hasLength(2));

      // Re-add Pod Gamma with the same name and serial number.
      final addBtn = find.text('Add a pod');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      await fillAndSubmit(
        tester,
        name: 'Pod Gamma',
        room: 'Balcony',
        serial: 'AQG-REUSE-1',
      );

      expect(find.text('Pod Gamma added'), findsOneWidget);
      expect(sim.pods, hasLength(3));
      expect(sim.pods.last.name, 'Pod Gamma');
    });
  });
}
