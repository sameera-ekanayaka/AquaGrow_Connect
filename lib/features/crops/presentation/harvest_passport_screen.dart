import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/crops/application/crop_detail_providers.dart';
import 'package:aquagrow_mobile/features/crops/domain/harvest_passport.dart';
import 'package:aquagrow_mobile/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Harvest Passport: the facts about a harvest and a QR code that proves them.
///
/// OWNER: Udeshika (see docs/tasks/udeshika.md).
class HarvestPassportScreen extends ConsumerWidget {
  /// Creates the screen for the pod with [podId].
  const HarvestPassportScreen({required this.podId, super.key});

  /// The pod being harvested.
  final String podId;

  static const double _qrSize = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podsAsync = ref.watch(podsProvider);
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Harvest Passport')),
      body: SafeArea(
        child: AsyncValueView<List<Pod>>(
          value: podsAsync,
          data: (pods) {
            final matches = pods.where((p) => p.id == podId);
            final pod = matches.isEmpty ? null : matches.first;
            final batch = pod?.batch;
            if (pod == null || batch == null) {
              return const EmptyView(
                title: 'No passport yet',
                message: 'Nothing is growing in this pod.',
              );
            }

            final now = DateTime.now();
            final averages =
                ref.watch(cropTodayTelemetryProvider(podId)).valueOrNull;
            final passport = HarvestPassport(
              crop: batch.cropName,
              variety: batch.variety,
              pod: pod.name,
              plantedAt: batch.plantedAt,
              harvestedAt: DateTime(now.year, now.month, now.day),
              avgPh: averages?.avgPh,
              avgEc: averages?.avgEc,
            );
            final facts = passport.toFacts();

            return ListView(
              padding: const EdgeInsets.all(AgSpace.screen),
              children: [
                Text('Harvest passport', style: text.headlineMedium),
                const SizedBox(height: AgSpace.s8),
                Text(
                  'Scan the code with any phone camera to read where this '
                  '${passport.crop.toLowerCase()} came from.',
                  style: text.bodyMedium?.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AgSpace.s20),
                Card(
                  elevation: 0,
                  color: c.subtle,
                  shape: RoundedRectangleBorder(
                    borderRadius: AgRadius.all(AgRadius.r20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AgSpace.s16),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AgRadius.all(AgRadius.r16),
                            ),
                            padding: const EdgeInsets.all(AgSpace.s16),
                            child: QrImageView(
                              data: passport.qrData,
                              size: _qrSize,
                            ),
                          ),
                        ),
                        const SizedBox(height: AgSpace.s8),
                        Text(
                          'Code ${passport.shortHash}',
                          style:
                              text.bodySmall?.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: AgSpace.s16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AgSpace.s16),
                          decoration: BoxDecoration(
                            color: c.brand,
                            borderRadius: AgRadius.all(AgRadius.r16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop_rounded),
                              const SizedBox(width: AgSpace.s12),
                              // Expanded lets the caption wrap on narrow
                              // phones instead of overflowing the card.
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${passport.waterSavedLitres.toStringAsFixed(1)} L',
                                      style: text.titleLarge,
                                    ),
                                    Text(
                                      'water saved compared with soil',
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AgSpace.s16),
                        _Fact('Crop', passport.crop),
                        _Fact('Pod', '${pod.name}, ${pod.room}'),
                        _Fact('Planted', facts['plantedAt']! as String),
                        _Fact('Harvested', facts['harvestedAt']! as String),
                        _Fact('Days grown', '${passport.daysGrown}'),
                        _Fact(
                          'Average pH',
                          passport.avgPh?.toStringAsFixed(1) ?? '--',
                        ),
                        _Fact(
                          'Average EC',
                          passport.avgEc == null
                              ? '--'
                              : '${passport.avgEc!.toStringAsFixed(1)} mS/cm',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AgSpace.s20),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: text.bodyMedium?.copyWith(color: c.textSecondary)),
          Text(value, style: text.titleSmall),
        ],
      ),
    );
  }
}
