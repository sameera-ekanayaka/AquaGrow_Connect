import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/controls/presentation/pod_controls_card.dart';
import 'package:aquagrow_mobile/features/dashboard/application/home_clock.dart';
import 'package:aquagrow_mobile/features/dashboard/domain/priority_task.dart';
import 'package:aquagrow_mobile/features/dashboard/domain/time_ago.dart';
import 'package:aquagrow_mobile/features/dashboard/presentation/widgets/pod_selector.dart';
import 'package:aquagrow_mobile/features/dashboard/presentation/widgets/priority_task_card.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _log = AppLogger('dashboard');

/// Home tab, from the Figma frame "Home · Light", top to bottom: header,
/// pod selector, the most urgent task, the crop hero, growing conditions,
/// pod controls and the plants in every pod.
///
/// OWNER: Osanda (see docs/tasks/osanda.md).
class HomeScreen extends ConsumerWidget {
  /// Creates the Home tab.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(homeClockProvider)();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AgSpace.screen),
        children: [
          TabHeader(overline: greeting(now), title: 'Your garden'),
          AsyncValueView(
            value: ref.watch(podsProvider),
            onRetry: () => ref.invalidate(podsProvider),
            isEmpty: (pods) => pods.isEmpty,
            empty: const EmptyView(
              title: 'No pods yet',
              message: 'Add a pod to see its plants and readings here.',
            ),
            data: (_) {
              final pod = ref.watch(selectedPodProvider);
              return pod == null ? const LoadingView() : _PodHome(pod: pod);
            },
          ),
        ],
      ),
    );
  }

  /// "Good morning", "Good afternoon" or "Good evening" for [now].
  static String greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

/// Everything below the header for one pod.
class _PodHome extends ConsumerWidget {
  const _PodHome({required this.pod});

  final Pod pod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(homeClockProvider)();
    final reading = ref.watch(latestReadingProvider(pod.id)).valueOrNull;
    final online = pod.isOnline;

    final lastAt =
        online ? reading?.recordedAt ?? pod.lastSeenAt : pod.lastSeenAt;
    final ago = timeAgo(now.difference(lastAt));
    final task = online && reading != null
        ? priorityTaskFor(reading, podName: pod.name)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PodSelector(
          pod: pod,
          updated: online ? 'updated $ago' : 'last seen $ago',
        ),
        if (task != null) ...[
          const SizedBox(height: AgSpace.s16),
          PriorityTaskCard(
            task: task,
            onAction: () => _runAction(context, ref, task),
          ),
        ],
        const SizedBox(height: AgSpace.s24),
        _Hero(pod: pod, now: now),
        const SizedBox(height: AgSpace.s32),
        SectionHeader(
          title: 'Growing conditions',
          caption: online ? 'Updated $ago' : 'Last reading $ago',
        ),
        _ReadingsGrid(podId: pod.id, online: online),
        const SizedBox(height: AgSpace.s32),
        const SectionHeader(title: 'Pod controls'),
        PodControlsCard(pod: pod),
        const SizedBox(height: AgSpace.s32),
        _YourPlants(now: now),
      ],
    );
  }

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref,
    PriorityTask task,
  ) async {
    switch (task.action) {
      case PriorityAction.markRefilled:
        final ok = await showConfirmDialog(
          context,
          title: 'Mark ${pod.name} as refilled?',
          message: 'Only do this after you have topped up the water tank.',
          confirmLabel: 'Mark refilled',
        );
        if (!ok || !context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref.read(controlRepositoryProvider).markRefilled(pod.id);
          messenger.showSnackBar(
            SnackBar(content: Text('${pod.name} marked as refilled')),
          );
        } on AppFailure catch (e) {
          _log.warning('markRefilled failed for ${pod.id}', e);
          messenger.showSnackBar(SnackBar(content: Text(e.message)));
        }
      case null:
        return;
    }
  }
}

/// The crop hero, or a quiet empty state when nothing is planted.
class _Hero extends StatelessWidget {
  const _Hero({required this.pod, required this.now});

  final Pod pod;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final batch = pod.batch;
    if (batch == null) {
      return EmptyView(
        title: '${pod.name} is empty',
        message: 'Plant a crop to track its growth here.',
      );
    }
    final left = batch.daysLeft(now);
    return CropHero(
      name: batch.cropName,
      badgeLabel: 'Day ${batch.dayNumber(now)} · ${batch.stage(now).label}',
      caption: left > 0 ? 'Harvest in about $left days' : 'Ready to harvest',
      imageAsset: batch.imageAsset,
      onTap: () => context.push(AppRoutes.cropDetail(pod.id)),
    );
  }
}

class _ReadingsGrid extends ConsumerWidget {
  const _ReadingsGrid({required this.podId, required this.online});

  final String podId;
  final bool online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(latestReadingProvider(podId)),
      onRetry: () => ref.invalidate(latestReadingProvider(podId)),
      data: (reading) => LayoutBuilder(
        builder: (context, constraints) {
          // Two columns on phones, four on tablets and landscape.
          final columns = constraints.maxWidth >= 600 ? 4 : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AgSpace.s12,
            crossAxisSpacing: AgSpace.s12,
            childAspectRatio: 1.15,
            children: [
              for (final metric in SensorMetric.values)
                SensorTile(
                  label: metric.label,
                  value: metric.format(metric.valueOf(reading)),
                  // An offline pod's numbers are stale, so do not grade them.
                  caption: online ? metric.targetLabel : 'Last known value',
                  status: online
                      ? metric.statusOf(metric.valueOf(reading))
                      : SensorStatus.normal,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// "Your plants": one [CropTile] per planted pod, and a link to Crops.
class _YourPlants extends ConsumerWidget {
  const _YourPlants({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pods = (ref.watch(podsProvider).valueOrNull ?? const <Pod>[])
        .where((p) => p.batch != null)
        .toList();
    if (pods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Your plants',
          actionLabel: 'View crops',
          onAction: () => context.go(AppRoutes.crops),
        ),
        // A handful of pods at most, so a scrolling row is enough here.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, pod) in pods.indexed) ...[
                if (i > 0) const SizedBox(width: AgSpace.s12),
                CropTile(
                  title: pod.batch!.cropName,
                  detail: '${pod.room}, day ${pod.batch!.dayNumber(now)}',
                  imageAsset: pod.batch!.imageAsset,
                  onTap: () => context.push(AppRoutes.cropDetail(pod.id)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
