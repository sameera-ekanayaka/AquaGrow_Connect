import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detail of the crop growing in one pod.
///
/// OWNER: Udeshika (see docs/tasks/udeshika.md).
/// Placeholder: shows the crop name and stage so navigation can be tested.
class CropDetailScreen extends ConsumerWidget {
  const CropDetailScreen({required this.podId, super.key});

  final String podId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pods = ref.watch(podsProvider).valueOrNull ?? const [];
    final matches = pods.where((p) => p.id == podId);
    final pod = matches.isEmpty ? null : matches.first;
    final batch = pod?.batch;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(batch?.cropName ?? 'Crop')),
      body: batch == null
          ? const EmptyView(title: 'Nothing growing', message: 'Start a batch in this pod.')
          : ListView(
              padding: const EdgeInsets.all(AgSpace.screen),
              children: [
                Text(pod!.displayName, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AgSpace.s8),
                Text(
                  '${batch.stage(now).label} · Day ${batch.dayNumber(now)} · '
                  'Harvest in ${batch.daysLeft(now)} days',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AgSpace.s12),
                LinearProgressIndicator(value: batch.progress(now)),
              ],
            ),
    );
  }
}
