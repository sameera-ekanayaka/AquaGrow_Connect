import 'package:aquagrow_mobile/core/theme/app_theme.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _basil = 'assets/images/crops/basil.png';

Widget _wrap(Widget child, {ThemeData? theme, double width = 390}) =>
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );

void main() {
  group('CropTile', () {
    testWidgets('shows the title, the detail and the photo', (tester) async {
      await tester.pumpWidget(
        _wrap(
          // Align lets the tile keep its own width, as it does in a row on Home.
          const Align(
            child: CropTile(
              title: 'Baby Spinach',
              detail: 'Dining room, day 4',
              imageAsset: _basil,
            ),
          ),
        ),
      );

      expect(find.text('Baby Spinach'), findsOneWidget);
      expect(find.text('Dining room, day 4'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.getSize(find.byType(CropTile)).width, CropTile.tileWidth);
    });

    testWidgets('shows the plant placeholder without a photo', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CropTile(
            title: 'Baby Spinach',
            detail: 'Dining room, day 4',
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.grass_rounded), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          CropTile(
            title: 'Baby Spinach',
            detail: 'Day 4',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(CropTile));
      expect(taps, 1);
    });
  });

  group('CropHero', () {
    testWidgets('shows the badge, name and caption over the photo',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CropHero(
            name: 'Genovese Basil',
            badgeLabel: 'Day 8 · Growing',
            caption: 'Harvest in about 20 days',
            imageAsset: _basil,
          ),
        ),
      );

      expect(find.text('Genovese Basil'), findsOneWidget);
      expect(find.text('Harvest in about 20 days'), findsOneWidget);
      expect(
        find.widgetWithText(StatusBadge, 'Day 8 · Growing'),
        findsOneWidget,
      );
      expect(find.byType(Image), findsOneWidget);
      expect(tester.getSize(find.byType(CropHero)).height, CropHero.heroHeight);
    });

    testWidgets('hides the open button when there is no onTap', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CropHero(
            name: 'Genovese Basil',
            badgeLabel: 'Growing',
            caption: 'Day 8',
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('the open button calls onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          CropHero(
            name: 'Genovese Basil',
            badgeLabel: 'Growing',
            caption: 'Day 8',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Open Genovese Basil'));
      expect(taps, 1);
    });
  });

  group('PodCard', () {
    PodCard card({VoidCallback? onTap, String? imageAsset = _basil}) => PodCard(
          cropName: 'Genovese Basil',
          location: 'Kitchen · Pod Alpha',
          stageLabel: 'Growing',
          harvestLine: 'Day 8 of 28, harvest in about 20 days',
          imageAsset: imageAsset,
          onTap: onTap,
        );

    testWidgets('shows the crop, location, stage and harvest line',
        (tester) async {
      await tester.pumpWidget(_wrap(card(onTap: () {})));

      expect(find.text('Genovese Basil'), findsOneWidget);
      expect(find.text('Kitchen · Pod Alpha'), findsOneWidget);
      expect(
        find.text('Day 8 of 28, harvest in about 20 days'),
        findsOneWidget,
      );
      // Stage appears in the photo badge and in the body.
      expect(find.text('Growing'), findsNWidgets(2));
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(card(onTap: () => taps++)));

      await tester.tap(find.byType(PodCard));
      expect(taps, 1);
    });

    testWidgets('shows the placeholder without a photo', (tester) async {
      await tester.pumpWidget(_wrap(card(imageAsset: null)));

      expect(find.byIcon(Icons.grass_rounded), findsOneWidget);
    });
  });

  testWidgets('all three fit a 320 px phone in dark mode without overflow',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        theme: AppTheme.dark,
        width: 320,
        const Column(
          children: [
            CropHero(
              name: 'A very long crop name that will not fit on one line',
              badgeLabel: 'Day 8 · Growing',
              caption: 'Harvest in about 20 days, give or take a few more',
              imageAsset: _basil,
            ),
            PodCard(
              cropName: 'A very long crop name that will not fit on one line',
              location: 'Kitchen · Pod Alpha',
              stageLabel: 'Growing',
              harvestLine: 'Day 8 of 28, harvest in about 20 days',
            ),
            CropTile(
              title: 'A very long crop name',
              detail: 'Dining room, day 4',
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
