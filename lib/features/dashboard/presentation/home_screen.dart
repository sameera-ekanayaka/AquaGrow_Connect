import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home tab: the selected pod's live readings.
///
/// OWNER: Osanda (see docs/tasks/osanda.md).
/// This is a working starting point that shows the project's patterns:
/// read providers, render the four states, use shared widgets and tokens.
/// Still to build: priority task card, crop hero, controls, pod switcher.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pod = ref.watch(selectedPodProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AgSpace.screen),
        children: [
          TabHeader(overline: _greeting(DateTime.now()), title: 'Your garden'),
          if (pod == null)
            const LoadingView()
          else ...[
            _SelectedPodCard(pod: pod),
            const SizedBox(height: AgSpace.s20),
            const SectionHeader(title: 'Growing conditions', caption: 'Live'),
            _ReadingsGrid(podId: pod.id),
          ],
        ],
      ),
    );
  }

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _SelectedPodCard extends StatelessWidget {
  const _SelectedPodCard({required this.pod});

  final Pod pod;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.s12),
        child: Row(
          children: [
            Expanded(
              child: Text(pod.displayName, style: Theme.of(context).textTheme.labelLarge),
            ),
            StatusBadge(
              label: pod.isOnline ? 'Live' : 'Offline',
              tone: pod.isOnline ? BadgeTone.brand : BadgeTone.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingsGrid extends ConsumerWidget {
  const _ReadingsGrid({required this.podId});

  final String podId;

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
                  caption: metric.targetLabel,
                  status: metric.statusOf(metric.valueOf(reading)),
                ),
            ],
          );
        },
      ),
    );
  }
}
