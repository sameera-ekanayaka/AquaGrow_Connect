import 'package:aquagrow_mobile/core/models/pod_alert.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Every alert, newest first.
///
/// OWNER: Tharindu (see docs/tasks/tharindu.md).
/// Lists what is stored. The alert engine that raises alerts is still to build.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          TextButton(
            onPressed: () => ref.read(alertRepositoryProvider).acknowledgeAll(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: AsyncValueView<List<PodAlert>>(
        value: ref.watch(alertsProvider),
        isEmpty: (alerts) => alerts.isEmpty,
        empty: const EmptyView(
          icon: Icons.notifications_none,
          title: 'No alerts',
          message: 'Your pods are healthy. Alerts appear here when a reading leaves its safe range.',
        ),
        data: (alerts) => ListView.builder(
          padding: const EdgeInsets.all(AgSpace.screen),
          itemCount: alerts.length,
          itemBuilder: (context, i) => _AlertRow(alert: alerts[i]),
        ),
      ),
    );
  }
}

class _AlertRow extends ConsumerWidget {
  const _AlertRow({required this.alert});

  final PodAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ag;
    final color = alert.severity == SensorStatus.critical ? c.critical : c.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.s12),
      child: Card(
        child: ListTile(
          leading: Icon(Icons.warning_amber_rounded, color: color),
          title: Text(alert.title),
          subtitle: Text('${alert.message}\n${DateFormat.MMMd().add_jm().format(alert.createdAt)}'),
          isThreeLine: true,
          trailing: alert.acknowledged ? null : Icon(Icons.circle, size: 10, color: color),
          onTap: () => ref.read(alertRepositoryProvider).acknowledge(alert.id),
        ),
      ),
    );
  }
}
