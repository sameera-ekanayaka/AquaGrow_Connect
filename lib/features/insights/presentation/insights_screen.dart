import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Insights tab: charts of past readings, plus weather and VPD advice.
///
/// OWNER: Imasha (see docs/tasks/imasha.md).
/// Placeholder: links to the existing microclimate screen. Charts go here.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AgSpace.screen),
        children: [
          const TabHeader(overline: 'HOW YOUR PODS ARE DOING', title: 'Insights'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Weather and VPD'),
              subtitle: const Text('Local weather and growing advice'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.microclimate),
            ),
          ),
          const SizedBox(height: AgSpace.s20),
          const EmptyView(
            icon: Icons.show_chart,
            title: 'Charts are on the way',
            message: 'pH and temperature history for 1 day and 1 week.',
          ),
        ],
      ),
    );
  }
}
