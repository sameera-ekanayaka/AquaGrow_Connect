import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/features/auth/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  final user = UserProfile(
    id: 'u1',
    email: 'grower@aquagrow.io',
    fullName: 'Osanda',
    role: UserRole.owner,
    createdAt: DateTime(2026, 11, 1),
  );

  late RecordingAuthRepository repo;

  setUp(() => repo = RecordingAuthRepository(user: user));

  Future<void> pumpProfile(WidgetTester tester, {ThemeMode? mode}) async {
    await tester.pumpWidget(
      authTestApp(
        const ProfileScreen(),
        repo,
        themeMode: mode ?? ThemeMode.light,
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
