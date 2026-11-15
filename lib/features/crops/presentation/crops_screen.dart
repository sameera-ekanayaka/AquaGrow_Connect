import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/pod_card.dart';
import 'package:aquagrow_mobile/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Crops tab ("My Pods" in Figma): every pod and what is growing in it.
///
/// OWNER: Udeshika (see docs/tasks/udeshika.md).
/// Displays all pods using [PodCard] with a responsive layout.
class CropsScreen extends ConsumerWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podsAsync = ref.watch(podsProvider);

    return SafeArea(
      child: AsyncValueView<List<Pod>>(
        value: podsAsync,
        isEmpty: (pods) => pods.isEmpty,
        empty: const EmptyView(
          title: 'No pods yet',
          message: 'Add a pod to start growing hydroponic crops.',
        ),
        data: (pods) {
          final now = DateTime.now();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final crossAxisCount = isWide ? 2 : 1;

              return ListView(
                padding: const EdgeInsets.all(AgSpace.screen),
                children: [
                  const TabHeader(
                    overline: 'YOUR GROWING SPACES',
                    title: 'My Pods',
                  ),
                  const SizedBox(height: AgSpace.s16),
                  if (crossAxisCount == 1)
                    ...pods.map(
                      (pod) => Padding(
                        padding: const EdgeInsets.only(bottom: AgSpace.s16),
                        child: _buildPodCard(context, pod, now),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AgSpace.s16,
                        mainAxisSpacing: AgSpace.s16,
                        mainAxisExtent: 370,
                      ),
                      itemCount: pods.length,
                      itemBuilder: (context, index) {
                        return _buildPodCard(context, pods[index], now);
                      },
                    ),
                  const SizedBox(height: AgSpace.s20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showAddPodDialog(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add a pod'),
                    ),
                  ),
                  const SizedBox(height: AgSpace.s16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPodCard(BuildContext context, Pod pod, DateTime now) {
    final batch = pod.batch;

    final String stageLabel = batch == null ? 'Empty' : batch.stage(now).label;
    final String harvestLine = batch == null
        ? 'No active crop growing'
        : 'Day ${batch.dayNumber(now)} · Harvest est. in ${batch.daysLeft(now)} days';

    return PodCard(
      cropName: batch?.cropName ?? 'Empty pod',
      location: pod.displayName,
      stageLabel: stageLabel,
      harvestLine: harvestLine,
      imageAsset: batch?.imageAsset,
      onTap: () => context.push(AppRoutes.cropDetail(pod.id)),
    );
  }

  void _showAddPodDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add a Pod'),
          content: const Text(
            'Coming soon: Bluetooth and Wi-Fi pod pairing will be available in a future update.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
