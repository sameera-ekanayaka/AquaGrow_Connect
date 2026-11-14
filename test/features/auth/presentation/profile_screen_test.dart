import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/features/auth/presentation/profile_screen.dart';
import 'package:aquagrow_mobile/features/sync/application/sync_providers.dart';
import 'package:aquagrow_mobile/features/sync/application/sync_service.dart';
import 'package:aquagrow_mobile/features/sync/domain/sync_queue.dart';
import 'package:aquagrow_mobile/features/sync/domain/telemetry_uploader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recording_auth_repository.dart';

class _NoUpload implements TelemetryUploader {
  @override
  Future<void> upload(List<SensorReading> readings) async {}
}

void main() {
  final user = UserProfile(
    id: 'u1',
    email: 'grower@aquagrow.io',
    fullName: 'Osanda',
    role: UserRole.owner,
    createdAt: DateTime(2026, 11, 1),
  );

  final now = DateTime(2026, 11, 15, 10, 30);
  late RecordingAuthRepository repo;
  late SyncService sync;

  setUp(() {
    repo = RecordingAuthRepository(user: user);
    sync = SyncService(
      queue: InMemorySyncQueue(capacity: 500),
      uploader: _NoUpload(),
      cache: (_) async {},
      clock: () => now.subtract(const Duration(minutes: 2)),
    );
  });

  Future<void> pumpProfile(WidgetTester tester, {ThemeMode? mode}) async {
    await tester.pumpWidget(
      authTestApp(
        const ProfileScreen(),
        repo,
        themeMode: mode ?? ThemeMode.light,
        overrides: [
          syncServiceProvider.overrideWith((ref) => sync),
          syncClockProvider.overrideWith((ref) => Stream.value(now)),
        ],
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the signed-in user with initials', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('OS'), findsOneWidget);
    expect(find.text('Osanda'), findsOneWidget);
    expect(find.text('grower@aquagrow.io'), findsOneWidget);
  });

  testWidgets('shows the data mode and security note', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Data mode'), findsOneWidget);
    expect(find.text('Simulation · built-in pods'), findsOneWidget);
    expect(find.textContaining('Android Keystore'), findsOneWidget);
  });

  testWidgets('says not synced yet before the first sync', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Last synced'), findsOneWidget);
    expect(find.text('Not synced yet'), findsOneWidget);
  });

  testWidgets('shows how long ago readings synced and how many',
      (tester) async {
    await sync.setOffline(true);
    for (var i = 0; i < 37; i++) {
      await sync.onReading(
        SensorReading(
          id: 'r$i',
          deviceId: 'pod-alpha',
          ph: 6,
          tdsPpm: 800,
          ecMs: 1.6,
          waterTempC: 21,
          waterLevelPct: 80,
          recordedAt: DateTime(2026, 11, 15, 10).add(Duration(seconds: i)),
        ),
      );
    }
    await sync.setOffline(false);

    await pumpProfile(tester);

    expect(find.text('2 min ago · 37 readings'), findsOneWidget);
  });

  testWidgets('sign out asks first and does nothing on cancel', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.signOutCalls, 0);
  });

  testWidgets('sign out signs out after confirming', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(repo.signOutCalls, 1);
  });

  testWidgets('renders in dark mode without errors', (tester) async {
    await pumpProfile(tester, mode: ThemeMode.dark);

    expect(find.text('Osanda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
