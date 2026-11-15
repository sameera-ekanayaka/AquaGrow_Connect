import 'package:aquagrow_mobile/core/models/crop_batch.dart';
import 'package:aquagrow_mobile/core/models/crop_recipe.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/crops/application/crop_detail_providers.dart';
import 'package:aquagrow_mobile/features/crops/domain/crop_recipes.dart';
import 'package:aquagrow_mobile/shared/widgets/confirm_dialog.dart';
import 'package:aquagrow_mobile/shared/widgets/crop_hero.dart';
import 'package:aquagrow_mobile/shared/widgets/section_header.dart';
import 'package:aquagrow_mobile/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detail of the crop growing in one pod.
///
/// OWNER: Udeshika (see docs/tasks/udeshika.md).
/// Displays crop status, stage timeline, target recipe parameters,
/// 24h telemetry averages, and the harvest action.
class CropDetailScreen extends ConsumerWidget {
  const CropDetailScreen({required this.podId, super.key});

  final String podId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podsAsync = ref.watch(podsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crop Detail')),
      body: SafeArea(
        child: AsyncValueView<List<Pod>>(
          value: podsAsync,
          data: (pods) {
            final matches = pods.where((p) => p.id == podId);
            final pod = matches.isEmpty ? null : matches.first;
            final batch = pod?.batch;

            if (pod == null || batch == null) {
              return const EmptyView(
                title: 'Nothing growing',
                message: 'Start a batch in this pod to view crop details.',
              );
            }

            final now = DateTime.now();
            final currentStage = batch.stage(now);
            final recipe = CropRecipes.findForCrop(batch.cropName);
            final todayTelemetry = ref.watch(cropTodayTelemetryProvider(podId));

            final isHarvestable = currentStage == GrowthStage.readyToHarvest ||
                currentStage == GrowthStage.growing;

            return ListView(
              padding: const EdgeInsets.all(AgSpace.screen),
              children: [
                CropHero(
                  name: batch.cropName,
                  badgeLabel:
                      '${currentStage.label} · Day ${batch.dayNumber(now)}',
                  caption: batch.daysLeft(now) == 0
                      ? 'Ready for harvest'
                      : 'Harvest est. in ${batch.daysLeft(now)} days',
                  imageAsset: batch.imageAsset,
                ),
                const SizedBox(height: AgSpace.s20),
                _StageTimelineCard(currentStage: currentStage),
                const SizedBox(height: AgSpace.s16),
                _ProgressCard(batch: batch, now: now),
                const SizedBox(height: AgSpace.s20),
                const SectionHeader(title: 'Recipe Targets'),
                _RecipeTargetsCard(recipe: recipe),
                const SizedBox(height: AgSpace.s20),
                const SectionHeader(title: "Today's Average (24h)"),
                _TodayAverageCard(todayTelemetry: todayTelemetry),
                const SizedBox(height: AgSpace.s24),
                FilledButton.icon(
                  onPressed: isHarvestable
                      ? () => _onHarvest(context, batch, currentStage)
                      : null,
                  icon: const Icon(Icons.eco_rounded),
                  label: Text(
                    currentStage == GrowthStage.harvested
                        ? 'Already Harvested'
                        : 'Harvest Crop',
                  ),
                ),
                const SizedBox(height: AgSpace.s16),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _onHarvest(
    BuildContext context,
    CropBatch batch,
    GrowthStage stage,
  ) async {
    final bool isEarly = stage == GrowthStage.growing;
    final confirmed = await showConfirmDialog(
      context,
      title: isEarly ? 'Harvest early?' : 'Harvest crop?',
      message: isEarly
          ? '${batch.cropName} is still in the growing stage. Are you sure you want to harvest early?'
          : 'Are you ready to harvest ${batch.cropName} and generate its Harvest Passport?',
      confirmLabel: isEarly ? 'Harvest Early' : 'Harvest',
    );

    if (confirmed && context.mounted) {
      context.push('/crops/$podId/passport');
    }
  }
}

class _StageTimelineCard extends StatelessWidget {
  const _StageTimelineCard({required this.currentStage});

  final GrowthStage currentStage;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    final steps = [
      (GrowthStage.seedling, 'Seedling'),
      (GrowthStage.growing, 'Growing'),
      (GrowthStage.readyToHarvest, 'Ready to harvest'),
    ];

    return Card(
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
            Text('Growth Stages', style: text.titleMedium),
            const SizedBox(height: AgSpace.s16),
            Row(
              children: steps.asMap().entries.map((entry) {
                final idx = entry.key;
                final stage = entry.value.$1;
                final label = entry.value.$2;

                final isCurrent = currentStage == stage;
                final isPast = currentStage.index > stage.index;
                final isActive = isCurrent || isPast;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? c.brand
                                    : (isPast ? c.brandSurface : c.subtle),
                                border: Border.all(
                                  color: isActive ? c.brand : c.border,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                isPast
                                    ? Icons.check_rounded
                                    : (isCurrent
                                        ? Icons.eco_rounded
                                        : Icons.circle_outlined),
                                size: 16,
                                color: isCurrent ? c.onDark : c.text,
                              ),
                            ),
                            const SizedBox(height: AgSpace.s8),
                            Text(
                              label,
                              style: text.bodySmall?.copyWith(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent ? c.text : c.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      if (idx < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isPast ? c.brand : c.border,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.batch, required this.now});

  final CropBatch batch;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Card(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress', style: text.titleMedium),
                Text(
                  '${(batch.progress(now) * 100).toInt()}%',
                  style: text.labelLarge?.copyWith(color: c.text),
                ),
              ],
            ),
            const SizedBox(height: AgSpace.s12),
            ClipRRect(
              borderRadius: AgRadius.all(AgRadius.r16),
              child: LinearProgressIndicator(
                value: batch.progress(now),
                minHeight: 10,
                backgroundColor: c.subtle,
                color: c.brand,
              ),
            ),
            const SizedBox(height: AgSpace.s12),
            Text(
              'Day ${batch.dayNumber(now)} of ${batch.daysToHarvest} · ${batch.daysLeft(now)} days left',
              style: text.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTargetsCard extends StatelessWidget {
  const _RecipeTargetsCard({required this.recipe});

  final CropRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;

    return Card(
      elevation: 0,
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AgRadius.all(AgRadius.r20),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.s16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TargetItem(
                    label: 'pH Range',
                    value:
                        '${recipe.minPh.toStringAsFixed(1)} - ${recipe.maxPh.toStringAsFixed(1)}',
                  ),
                ),
                Expanded(
                  child: _TargetItem(
                    label: 'Target EC',
                    value: '${recipe.targetEc.toStringAsFixed(1)} mS/cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AgSpace.s16),
            Row(
              children: [
                Expanded(
                  child: _TargetItem(
                    label: 'Water Temp',
                    value: '${recipe.targetWaterTempC.toStringAsFixed(1)} °C',
                  ),
                ),
                Expanded(
                  child: _TargetItem(
                    label: 'Light Hours',
                    value: '${recipe.lightHoursPerDay} hrs / day',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetItem extends StatelessWidget {
  const _TargetItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodySmall?.copyWith(color: c.textSecondary)),
        const SizedBox(height: AgSpace.s4),
        Text(value, style: text.titleMedium),
      ],
    );
  }
}

class _TodayAverageCard extends StatelessWidget {
  const _TodayAverageCard({required this.todayTelemetry});

  final AsyncValue<({double? avgEc, double? avgPh})> todayTelemetry;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;

    return Card(
      elevation: 0,
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AgRadius.all(AgRadius.r20),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.s16),
        child: AsyncValueView<({double? avgEc, double? avgPh})>(
          value: todayTelemetry,
          data: (data) {
            final phStr =
                data.avgPh != null ? data.avgPh!.toStringAsFixed(2) : '--';
            final ecStr = data.avgEc != null
                ? '${data.avgEc!.toStringAsFixed(2)} mS/cm'
                : '--';

            return Row(
              children: [
                Expanded(
                  child: _TargetItem(label: 'Today Avg pH', value: phStr),
                ),
                Expanded(
                  child: _TargetItem(label: 'Today Avg EC', value: ecStr),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
