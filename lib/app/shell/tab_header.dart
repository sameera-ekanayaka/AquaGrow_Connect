import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The header at the top of every tab, from Figma:
/// a small overline ("Good morning, Tharindu"), a big title ("Your garden"),
/// and the alerts bell with an unread count.
///
/// Use it as the first child of a tab's scroll view:
/// ```dart
/// const TabHeader(overline: 'YOUR GROWING SPACES', title: 'My Pods')
/// ```
class TabHeader extends ConsumerWidget {
  const TabHeader({required this.title, this.overline, super.key});

  final String title;
  final String? overline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final unread = ref.watch(unreadAlertCountProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.s20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) Text(overline!, style: text.bodySmall),
                const SizedBox(height: AgSpace.s4),
                Text(title, style: text.headlineMedium),
              ],
            ),
          ),
          Semantics(
            label: unread == 0 ? 'Alerts' : 'Alerts, $unread unread',
            button: true,
            child: Material(
              color: context.ag.subtle,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push(AppRoutes.alerts),
                child: SizedBox.square(
                  dimension: kMinTouchTarget,
                  child: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    backgroundColor: context.ag.critical,
                    alignment: const AlignmentDirectional(0.6, -0.6),
                    child: const Center(child: Icon(Icons.notifications_none)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
