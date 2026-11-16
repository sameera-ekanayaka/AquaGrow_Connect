import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/features/auth/presentation/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  final user = UserProfile(
    id: 'u1',
    email: 'grower@aquagrow.io',
    fullName: 'Kamal Silva',
    role: UserRole.owner,
    createdAt: DateTime(2026, 11, 1),
  );

  late RecordingAuthRepository repo;

  setUp(() {
    repo = RecordingAuthRepository(user: user);
  });

  testWidgets(
      'delete account flow requires first confirmation and typing DELETE',
      (tester) async {
    await tester.pumpWidget(
      authTestApp(
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('trigger-delete-btn'),
                onPressed: () => showDeleteAccountFlow(context, ref),
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
        repo,
      ),
    );
    await tester.pumpAndSettle();

    // Trigger flow
    await tester.tap(find.byKey(const Key('trigger-delete-btn')));
    await tester.pumpAndSettle();

    // First confirmation dialog is shown
    expect(find.text('Delete account?'), findsOneWidget);
    expect(
      find.text(
        'Delete your account and all pod history? This cannot be undone.',
      ),
      findsOneWidget,
    );

    // Confirm step 1
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    // Second confirmation dialog
    expect(find.text('Final confirmation'), findsOneWidget);

    final deleteBtn = find.byKey(const Key('delete-confirm-btn'));
    expect(tester.widget<FilledButton>(deleteBtn).onPressed, isNull);

    // Enter only password - still disabled
    await tester.enterText(
      find.byKey(const Key('delete-password-input')),
      'mypassword',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(deleteBtn).onPressed, isNull);

    // Enter wrong confirmation word - still disabled
    await tester.enterText(
      find.byKey(const Key('delete-confirm-input')),
      'delete',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(deleteBtn).onPressed, isNull);

    // Enter exact "DELETE" - becomes enabled
    await tester.enterText(
      find.byKey(const Key('delete-confirm-input')),
      'DELETE',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(deleteBtn).onPressed, isNotNull);

    // Tap delete permanently
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    expect(repo.user, isNull);
  });
}
