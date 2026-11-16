import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pill at the top of Home from the Figma component "PodSelector":
/// crop thumbnail, pod name, "Kitchen · updated 12s ago", a Live or Offline
/// badge and a chevron. Tapping it opens [PodPickerSheet].
class PodSelector extends StatelessWidget {
  /// Creates the selector for [pod]. [updated] is the age text, for example
  /// "updated 12s ago" or "last seen 9 min ago".
  const PodSelector({required this.pod, required this.updated, super.key});

  /// The pod Home is showing.
  final Pod pod;

  /// Age of the latest reading, already worded.
  final String updated;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final status = pod.isOnline ? 'Live' : 'Offline';

    return Semantics(
      label: '${pod.name}, ${pod.room}, $status, $updated. Change pod',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => PodPickerSheet.show(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AgSpace.s8,
              AgSpace.s8,
              AgSpace.s16,
              AgSpace.s8,
            ),
            child: Row(
              children: [
                _Thumb(imageAsset: pod.batch?.imageAsset),
                const SizedBox(width: AgSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pod.name,
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${pod.room} · $updated',
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AgSpace.s8),
                StatusBadge(
                  label: status,
                  tone: pod.isOnline ? BadgeTone.brand : BadgeTone.neutral,
                ),
                const SizedBox(width: AgSpace.s4),
                Icon(Icons.expand_more_rounded, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet "Choose a pod". Picking a row sets [selectedPodIdProvider]
/// and closes the sheet.
class PodPickerSheet extends ConsumerWidget {
  /// Creates the sheet body. Use [show] to open it.
  const PodPickerSheet({super.key});

  /// Opens the sheet over [context].
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      // Above the bottom navigation bar, as in the Figma "Pod picker" frame.
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.ag.background,
      builder: (_) => const PodPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final selectedId = ref.watch(selectedPodProvider)?.id;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AgSpace.s16,
          0,
          AgSpace.s16,
          AgSpace.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AgSpace.s8,
                vertical: AgSpace.s12,
              ),
              child: Text('Choose a pod', style: text.titleLarge),
            ),
            Flexible(
              child: AsyncValueView(
                value: ref.watch(podsProvider),
                onRetry: () => ref.invalidate(podsProvider),
                isEmpty: (pods) => pods.isEmpty,
                empty: const EmptyView(
                  title: 'No pods yet',
                  message: 'Add a pod to start growing.',
                ),
                data: (pods) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: pods.length,
                  itemBuilder: (context, i) => _PodRow(
                    pod: pods[i],
                    selected: pods[i].id == selectedId,
                    onTap: () {
                      ref.read(selectedPodIdProvider.notifier).state =
                          pods[i].id;
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodRow extends StatelessWidget {
  const _PodRow({
    required this.pod,
    required this.selected,
    required this.onTap,
  });

  final Pod pod;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final crop = pod.batch?.cropName ?? 'Empty';

    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? c.brandSurface : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AgSpace.s8),
            child: Row(
              children: [
                _Thumb(imageAsset: pod.batch?.imageAsset),
                const SizedBox(width: AgSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pod.name, style: text.titleMedium),
                      Text('${pod.room} · $crop', style: text.bodySmall),
                    ],
                  ),
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: AgSpace.s8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: c.text,
                      semanticLabel: 'Selected',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 48 px round crop photo used in the selector and the picker rows.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageAsset});

  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: kMinTouchTarget,
      child: CropPhoto(imageAsset: imageAsset, radius: AgRadius.pill),
    );
  }
}
