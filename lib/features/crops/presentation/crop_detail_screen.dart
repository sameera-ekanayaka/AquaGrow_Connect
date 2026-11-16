import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/models/crop_batch.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/crops/application/crop_detail_providers.dart';
import 'package:aquagrow_mobile/features/crops/domain/crop_recipes.dart';
import 'package:aquagrow_mobile/features/crops/presentation/delete_pod.dart';
import 'package:aquagrow_mobile/shared/widgets/confirm_dialog.dart';
import 'package:aquagrow_mobile/shared/widgets/crop_photo.dart';
import 'package:aquagrow_mobile/shared/widgets/state_views.dart';
import 'package:aquagrow_mobile/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detail of the crop growing in one pod.
///
/// OWNER: Udeshika (see docs/tasks/udeshika.md).
class CropDetailScreen extends ConsumerWidget {
  Pod? _podOf(List<Pod>? pods) {
    for (final pod in pods ?? const <Pod>[]) {
      if (pod.id == podId) return pod;
    }
    return null;
  }

  /// Creates the screen for the pod with [podId].
  const CropDetailScreen({required this.podId, super.key});

  /// The pod whose crop is shown.
  final String podId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podsAsync = ref.watch(podsProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_podOf(podsAsync.valueOrNull) case final pod?)
            IconButton(
              tooltip: 'Delete pod',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                if (await confirmDeletePod(context, ref, pod) &&
                    context.mounted) {
                  context.pop();
                }
              },
            ),
        ],
      ),
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
            final stage = batch.stage(now);
            final recipe = CropRecipes.findForCrop(batch.cropName);
            final avg =
                ref.watch(cropTodayTelemetryProvider(podId)).valueOrNull;
            final canHarvest = stage == GrowthStage.readyToHarvest ||
                stage == GrowthStage.growing;

            return ListView(
              padding: const EdgeInsets.all(AgSpace.screen),
              children: [
                // Minimal UI: photo with the stage badge, then the name.
                SizedBox(
                  height: 280,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CropPhoto(
                        radius: AgRadius.r24,
                        imageAsset: batch.imageAsset,
                      ),
                      Positioned(
                        top: AgSpace.s12,
                        left: AgSpace.s12,
                        child: StatusBadge(
                          label: 'Day ${batch.dayNumber(now)} · ${stage.label}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AgSpace.s20),
                Text(batch.cropName, style: text.headlineMedium),
                Text(
                  '${pod.room} · ${pod.name}',
                  style: text.bodyMedium
                      ?.copyWith(color: context.ag.textSecondary),
                ),
                const SizedBox(height: AgSpace.s16),
                _StageCards(current: stage),
                const SizedBox(height: AgSpace.s16),
                _Progress(batch: batch, now: now),
                const SizedBox(height: AgSpace.s20),
                Text('Recipe targets', style: text.titleLarge),
                const SizedBox(height: AgSpace.s12),
                Row(
                  children: [
                    Expanded(
                      child: _Tile(
                        icon: Icons.science_rounded,
                        label: 'pH',
                        value:
                            '${recipe.minPh.toStringAsFixed(1)}–${recipe.maxPh.toStringAsFixed(1)}',
                        note: avg?.avgPh == null
                            ? 'Today --'
                            : 'Today ${avg!.avgPh!.toStringAsFixed(1)}',
                      ),
                    ),
                    const SizedBox(width: AgSpace.s12),
                    Expanded(
                      child: _Tile(
                        icon: Icons.bolt_rounded,
                        label: 'Nutrients (EC)',
                        value: recipe.targetEc.toStringAsFixed(1),
                        note: avg?.avgEc == null
                            ? 'Today --'
                            : 'Today ${avg!.avgEc!.toStringAsFixed(1)} mS/cm',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AgSpace.s12),
                Row(
                  children: [
                    Expanded(
                      child: _Tile(
                        icon: Icons.thermostat_rounded,
                        label: 'Water temp',
                        value:
                            '${recipe.targetWaterTempC.toStringAsFixed(0)}°C',
                        note: 'Target',
                      ),
                    ),
                    const SizedBox(width: AgSpace.s12),
                    Expanded(
                      child: _Tile(
                        icon: Icons.lightbulb_rounded,
                        label: 'Light',
                        value: '${recipe.lightHoursPerDay} h',
                        note: 'Per day',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AgSpace.s24),
                FilledButton(
                  onPressed: canHarvest
                      ? () => _onHarvest(context, ref, batch, stage)
                      : null,
                  child: Text(
                    stage == GrowthStage.harvested
                        ? 'Already harvested'
                        : 'Harvest crop',
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
    WidgetRef ref,
    CropBatch batch,
    GrowthStage stage,
  ) async {
    final isEarly = stage == GrowthStage.growing;
    final confirmed = await showConfirmDialog(
      context,
      title: isEarly ? 'Harvest early?' : 'Harvest crop?',
      message: isEarly
          ? '${batch.cropName} is still in the growing stage. Are you sure you want to harvest early?'
          : 'Are you ready to harvest ${batch.cropName} and generate its Harvest Passport?',
      confirmLabel: isEarly ? 'Harvest early' : 'Harvest',
    );

    if (!confirmed || !context.mounted) return;
    // The passport reads the growing batch, so the pod empties after it.
    await context.push(AppRoutes.harvestPassport(podId));
    try {
      await ref.read(podRepositoryProvider).harvest(podId);
      ref.invalidate(podsProvider);
    } on AppFailure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${batch.cropName} harvested. The pod is empty.'),
        ),
      );
    context.pop();
  }
}

class _StageCards extends StatelessWidget {
  const _StageCards({required this.current});

  final GrowthStage current;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (GrowthStage.seedling, 'Seedling'),
      (GrowthStage.growing, 'Growing'),
      (GrowthStage.readyToHarvest, 'Ready to harvest'),
    ];

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: AgSpace.s8),
          Expanded(
            child: _StageCard(
              label: steps[i].$2,
              isCurrent: current == steps[i].$1,
              isPast: current.index > steps[i].$1.index,
            ),
          ),
        ],
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.label,
    required this.isCurrent,
    required this.isPast,
  });

  final String label;
  final bool isCurrent;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AgSpace.s12,
        horizontal: AgSpace.s8,
      ),
      decoration: BoxDecoration(
        color: isCurrent ? c.brand : c.surface,
        borderRadius: AgRadius.all(AgRadius.r16),
      ),
      child: Column(
        children: [
          Icon(
            isPast ? Icons.check_circle_rounded : Icons.eco_rounded,
            size: 20,
            color: isCurrent ? c.text : c.textSecondary,
          ),
          const SizedBox(height: AgSpace.s8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: text.bodySmall?.copyWith(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? c.text : c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.batch, required this.now});

  final CropBatch batch;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Day ${batch.dayNumber(now)} of ${batch.daysToHarvest}',
              style: text.titleMedium,
            ),
            Text(
              '${batch.daysLeft(now)} days left',
              style: text.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AgSpace.s8),
        ClipRRect(
          borderRadius: AgRadius.all(AgRadius.r16),
          child: LinearProgressIndicator(
            value: batch.progress(now),
            minHeight: 8,
            backgroundColor: c.subtle,
            color: c.brand,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AgSpace.s16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.all(AgRadius.r20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: c.background,
            foregroundColor: c.text,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: AgSpace.s16),
          Text(label, style: text.bodySmall?.copyWith(color: c.textSecondary)),
          const SizedBox(height: AgSpace.s4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: text.displaySmall),
          ),
          const SizedBox(height: AgSpace.s4),
          Text(note, style: text.bodySmall?.copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}
