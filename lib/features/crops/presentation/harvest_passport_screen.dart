import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/crops/application/crop_detail_providers.dart';
import 'package:aquagrow_mobile/features/crops/domain/harvest_passport.dart';
import 'package:aquagrow_mobile/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Harvest Passport: the facts about a harvest and a QR code that proves them.
///
/// OWNER: Udeshika (see docs/tasks/udeshika.md).
class HarvestPassportScreen extends ConsumerWidget {
  /// Creates the screen for the pod with [podId].
  const HarvestPassportScreen({required this.podId, super.key});

  /// The pod being harvested.
  final String podId;

  static const double _qrSize = 220;

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

            return ListView(
              padding: const EdgeInsets.all(AgSpace.screen),
              children: [
                Card(
                  elevation: 0,
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AgRadius.all(AgRadius.r20),
                    side: BorderSide(color: c.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AgSpace.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(passport.crop, style: text.titleLarge),
                        const SizedBox(height: AgSpace.s16),
                        _Fact('Pod', passport.pod),
                        _Fact(
                          'Planted',
                          passport.toFacts()['plantedAt']! as String,
                        ),
                        _Fact(
                          'Harvested',
                          passport.toFacts()['harvestedAt']! as String,
                        ),
                        _Fact('Days grown', '${passport.daysGrown}'),
                        _Fact(
                          'Average pH',
                          passport.avgPh?.toStringAsFixed(2) ?? '--',
                        ),
                        _Fact(
                          'Average EC',
                          passport.avgEc == null
                              ? '--'
                              : '${passport.avgEc!.toStringAsFixed(2)} mS/cm',
                        ),
                        _Fact(
                          'Water saved',
                          '${passport.waterSavedLitres.toStringAsFixed(1)} L',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AgSpace.s20),
                Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(AgSpace.s12),
                    child: QrImageView(
                      data: passport.qrData,
                      size: _qrSize,
                    ),
                  ),
                ),
                const SizedBox(height: AgSpace.s12),
                Center(
                  child: Text(
                    'Hash: ${passport.shortHash}',
                    style: text.bodySmall?.copyWith(color: c.textSecondary),
                  ),
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
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: text.bodyMedium),
          Text(value, style: text.titleSmall),
        ],
      ),
    );
  }
}
