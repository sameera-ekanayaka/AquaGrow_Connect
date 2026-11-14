import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  late RecordingAuthRepository repo;

  setUp(() => repo = RecordingAuthRepository());

  Future<void> pumpRegister(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(authTestApp(const RegisterScreen(), repo));
    await tester.pump();
  }

  Future<void> fill(
    WidgetTester tester, {
    String name = 'Sameera',
    String email = 'grower@aquagrow.io',
    String password = 'Password123',
    String? confirm,
  }) async {
    await tester.enterText(find.byKey(const Key('register-name')), name);
    await tester.enterText(find.byKey(const Key('register-email')), email);
    await tester.enterText(
      find.byKey(const Key('register-password')),
      password,
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm')),
      confirm ?? password,
    );
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
  }

  testWidgets('shows the Figma heading and fields', (tester) async {
    await pumpRegister(tester);

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('valid details create the account', (tester) async {
    await pumpRegister(tester);

    await fill(tester);
    await submit(tester);

    expect(repo.signUpCalls, ['grower@aquagrow.io']);
  });

  testWidgets('a short password shows the rule and does not sign up',
      (tester) async {
    await pumpRegister(tester);

    await fill(tester, password: 'abc1');
    await submit(tester);

    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(repo.signUpCalls, isEmpty);
  });

  testWidgets('an invalid email shows the error and does not sign up',
      (tester) async {
    await pumpRegister(tester);

    await fill(tester, email: 'grower@');
    await submit(tester);

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(repo.signUpCalls, isEmpty);
  });

  testWidgets('mismatched passwords are caught before signing up',
      (tester) async {
    await pumpRegister(tester);

    await fill(tester, confirm: 'Password124');
    await submit(tester);

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(repo.signUpCalls, isEmpty);
  });

  testWidgets('a failed sign up shows the friendly message', (tester) async {
    repo.error = const AuthFailure(
      'An account with this email already exists. Sign in instead.',
    );
    await pumpRegister(tester);

    await fill(tester);
    await submit(tester);

    expect(find.textContaining('already exists'), findsOneWidget);
  });
}
