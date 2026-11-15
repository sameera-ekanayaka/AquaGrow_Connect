import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('Care > Settings opens the settings screen', (tester) async {
    final sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10));
    addTearDown(sim.dispose);

    await tester.pumpWidget(testApp(sim: sim));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Care'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
