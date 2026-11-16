import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/features/insights/application/trend_providers.dart';
import 'package:aquagrow_mobile/features/insights/domain/trend_forecast.dart';
import 'package:aquagrow_mobile/features/insights/presentation/widgets/trend_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({TrendForecast? forecast}) {
    return ProviderScope(
      overrides: [
        trendProvider.overrideWithValue(forecast),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: TrendChip(),
        ),
      ),
    );
  }

  testWidgets('renders nothing when forecast is null', (tester) async {
    await tester.pumpWidget(buildSubject(forecast: null));
    await tester.pump();

    expect(find.byType(TrendChip), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('renders warning chip with icon and message when trend present',
      (tester) async {
    const forecast = TrendForecast(
      direction: TrendDirection.falling,
      change: 0.3,
      window: Duration(hours: 6),
      timeToLeaveRange: Duration(hours: 3),
      message:
          'pH has dropped 0.3 in 6 hours. It may leave the safe range in about 3 hours.',
    );

    await tester.pumpWidget(buildSubject(forecast: forecast));
    await tester.pump();

    expect(find.text(forecast.message), findsOneWidget);
    expect(find.byIcon(Icons.trending_down), findsOneWidget);
  });
}
