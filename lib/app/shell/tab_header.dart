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
/// const TabHeader(title: 'My Pods', subtitle: '2 pods growing')
/// ```
class TabHeader extends ConsumerWidget {
  const TabHeader({required this.title, this.subtitle, super.key});

  final String title;

  /// Grey line under the title, for example "2 pods growing".
  final String? subtitle;

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
                Text(title, style: text.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AgSpace.s4),
                  Text(
                    subtitle!,
                    style: text.bodyMedium
                        ?.copyWith(color: context.ag.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Semantics(
            label: unread == 0 ? 'Alerts' : 'Alerts, $unread unread',
            button: true,
            child: Material(
              color: context.ag.background,
              shape: CircleBorder(side: BorderSide(color: context.ag.border)),
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
