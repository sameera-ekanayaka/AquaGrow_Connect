import 'package:aquagrow_mobile/app/shell/notification_setup.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/features/sync/presentation/sync_listener.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('the signed-in shell runs offline sync and notifications',
      (tester) async {
    final sim = PodSimulator(clock: () => DateTime(2026, 11, 15, 10));
    addTearDown(sim.dispose);

    await tester.pumpWidget(testApp(sim: sim));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SyncListener), findsOneWidget);
    expect(find.byType(NotificationSetup), findsOneWidget);
  });
}
