import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/alerts/application/alerts_providers.dart';
import 'package:aquagrow_mobile/features/alerts/domain/alert_groups.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Every alert, grouped into Today and Earlier, newest first.
///
/// Swipe an unread alert to mark it read, or tap it. A colour bar on the
/// left shows the severity: red for critical, amber for warning.
///
/// OWNER: Tharindu (see docs/tasks/tharindu.md).
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadAlertCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(alertRepositoryProvider).acknowledgeAll(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: AsyncValueView<List<AlertGroup>>(
        value: ref.watch(groupedAlertsProvider),
        isEmpty: (groups) => groups.isEmpty,
        empty: const EmptyView(
          icon: Icons.notifications_none,
          title: 'No alerts',
          message: 'Your pods are healthy. Alerts appear here when a reading '
              'leaves its safe range.',
        ),
        data: (groups) {
          final rows = [
            for (final group in groups) ...[
              group.label,
              ...group.alerts,
            ],
          ];
          return ListView.builder(
            padding: const EdgeInsets.all(AgSpace.screen),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              return row is PodAlert
                  ? _AlertRow(key: ValueKey(row.id), alert: row)
                  : SectionHeader(title: row as String);
            },
          );
        },
      ),
    );
  }
}

class _AlertRow extends ConsumerWidget {
  const _AlertRow({required this.alert, super.key});

  final PodAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final color =
        alert.severity == SensorStatus.critical ? c.critical : c.warning;
    void markRead() => ref.read(alertRepositoryProvider).acknowledge(alert.id);

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: AgSpace.s4, color: color),
            Expanded(
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: color),
                title: Text(
                  alert.title,
                  // Unread alerts use the stronger card-title style.
                  style: alert.acknowledged ? text.bodyLarge : text.titleMedium,
                ),
                subtitle: Text(
                  '${alert.message}\n'
                  '${DateFormat.MMMd().add_jm().format(alert.createdAt)}',
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
                isThreeLine: true,
                trailing: alert.acknowledged
                    ? null
                    : Semantics(
                        label: 'Unread',
                        child:
                            Icon(Icons.circle, size: AgSpace.s8, color: color),
                      ),
                onTap: alert.acknowledged ? null : markRead,
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.s12),
      child: alert.acknowledged
          ? card
          : Dismissible(
              key: ValueKey('swipe-${alert.id}'),
              direction: DismissDirection.endToStart,
              background: _SwipeBackground(color: c.brandSurface),
              // Marks the alert read but keeps it in the list.
              confirmDismiss: (_) async {
                markRead();
                return false;
              },
              child: card,
            ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AgRadius.r16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AgSpace.s20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Mark read', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: AgSpace.s8),
            const Icon(Icons.done_all),
          ],
        ),
      ),
    );
  }
}
