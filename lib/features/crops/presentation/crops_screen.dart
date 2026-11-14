import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Crops tab ("My Pods" in Figma): every pod and what is growing in it.
///
/// OWNER: Udeshika (see docs/tasks/udeshika.md).
/// Starting point only: replace the simple rows with the Figma pod cards.
class CropsScreen extends ConsumerWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: AsyncValueView<List<Pod>>(
        value: ref.watch(podsProvider),
        isEmpty: (pods) => pods.isEmpty,
        empty: const EmptyView(title: 'No pods yet', message: 'Add a pod to start growing.'),
        data: (pods) => ListView.builder(
          padding: const EdgeInsets.all(AgSpace.screen),
          itemCount: pods.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return const TabHeader(overline: 'YOUR GROWING SPACES', title: 'My Pods');
            }
            final pod = pods[i - 1];
            final batch = pod.batch;
            final now = DateTime.now();
            return Padding(
              padding: const EdgeInsets.only(bottom: AgSpace.s12),
              child: Card(
                child: ListTile(
                  minVerticalPadding: AgSpace.s12,
                  title: Text(batch?.cropName ?? 'Empty pod'),
                  subtitle: Text(pod.displayName),
                  trailing: batch == null
                      ? null
                      : StatusBadge(label: '${batch.stage(now).label} · Day ${batch.dayNumber(now)}'),
                  onTap: () => context.push(AppRoutes.cropDetail(pod.id)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
