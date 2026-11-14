import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recording_auth_repository.dart';

void main() {
  late RecordingAuthRepository repo;

  setUp(() => repo = RecordingAuthRepository());

  Future<void> pumpLogin(WidgetTester tester, {ThemeMode? mode}) async {
    await tester.pumpWidget(
      authTestApp(
        const LoginScreen(),
        repo,
        themeMode: mode ?? ThemeMode.light,
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the Figma headings and both buttons', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to check on your pods.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Use demo account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('the heading is readable: dark on light and light on dark',
      (tester) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await pumpLogin(tester, mode: mode);
      final heading = tester.widget<Text>(find.text('Welcome back'));
      final context = tester.element(find.text('Welcome back'));
      final theme = Theme.of(context);
      final colour =
          heading.style?.color ?? theme.textTheme.headlineMedium!.color!;
      final background = theme.scaffoldBackgroundColor;
      expect(
        (colour.computeLuminance() - background.computeLuminance()).abs(),
        greaterThan(0.5),
        reason: 'heading must contrast with the background in $mode',
      );
    }
  });

  testWidgets('an invalid email shows the error and does not call signIn',
      (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'not-an-email',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Password123',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(repo.signInCalls, isEmpty);
  });

  testWidgets('an empty form shows both errors and does not call signIn',
      (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);
    expect(repo.signInCalls, isEmpty);
  });

  testWidgets('valid details call signIn with the trimmed email',
      (tester) async {
    await pumpLogin(tester);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      '  grower@aquagrow.io ',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Password123',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(repo.signInCalls, ['grower@aquagrow.io']);
  });

  testWidgets('Use demo account signs in with one tap', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('login-demo')));
    await tester.pump();

    expect(repo.signInCalls, [AppConstants.mockOwnerEmail]);
  });

  testWidgets('a failed sign in shows the friendly failure message',
      (tester) async {
    repo.error = const AuthFailure('Wrong email or password.');
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('login-demo')));
    await tester.pump();

    expect(find.text('Wrong email or password.'), findsOneWidget);
  });

  testWidgets('forgot password sends a link and confirms where it went',
      (tester) async {
    await pumpLogin(tester);
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'grower@aquagrow.io',
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);

    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(repo.resetCalls, ['grower@aquagrow.io']);
    expect(find.text('Reset your password'), findsNothing);
    expect(
      find.textContaining('Reset link sent to grower@aquagrow.io'),
      findsOneWidget,
    );
  });

  testWidgets('forgot password keeps the dialog open with an error on failure',
      (tester) async {
    repo.error =
        const AuthFailure('Too many attempts. Wait a minute and try again.');
    await pumpLogin(tester);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('reset-email')), 'a@b.co');
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.textContaining('Too many attempts'), findsOneWidget);
  });

  testWidgets('forgot password rejects an invalid email', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('reset-email')), 'nope');
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(repo.resetCalls, isEmpty);
  });
}
