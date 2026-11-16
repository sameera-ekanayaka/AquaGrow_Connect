import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/features/auth/presentation/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  final user = UserProfile(
    id: 'u1',
    email: 'grower@aquagrow.io',
    fullName: 'Kamal Silva',
    farmName: 'Ceylon Hydro',
    phone: '0771234567',
    role: UserRole.owner,
    createdAt: DateTime(2026, 11, 1),
  );

  late RecordingAuthRepository repo;

  setUp(() {
    repo = RecordingAuthRepository(user: user);
  });

  testWidgets('EditProfileScreen pre-fills fields and updates successfully',
      (tester) async {
    await tester.pumpWidget(authTestApp(const EditProfileScreen(), repo));
    await tester.pumpAndSettle();

    expect(find.text('Kamal Silva'), findsOneWidget);
    expect(find.text('Ceylon Hydro'), findsOneWidget);
    expect(find.text('0771234567'), findsOneWidget);

    // Edit full name to new valid 2-word name
    await tester.enterText(
      find.byKey(const Key('edit-profile-name')),
      'Nimal Perera',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('edit-profile-save-btn')));
    await tester.pumpAndSettle();

    expect(repo.user?.fullName, 'Nimal Perera');
  });

  testWidgets(
      'EditProfileScreen shows validation error when name is single word',
      (tester) async {
    await tester.pumpWidget(authTestApp(const EditProfileScreen(), repo));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('edit-profile-name')),
      'SingleWord',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('edit-profile-save-btn')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your first and last name'), findsOneWidget);
  });
}
