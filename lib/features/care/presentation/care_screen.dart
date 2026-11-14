import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Care tab: suppliers, reminders, account and demo tools.
///
/// OWNERS: Imasha (suppliers, reminders) and Tharindu (profile, settings).
/// See docs/tasks/imasha.md and docs/tasks/tharindu.md.
class CareScreen extends StatelessWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AgSpace.screen),
        children: [
          const TabHeader(overline: 'LOOK AFTER YOUR PODS', title: 'Care'),
          _CareTile(
            icon: Icons.storefront_outlined,
            title: 'Hydroponic suppliers',
            subtitle: 'Nutrients and parts near you',
            onTap: () => context.push(AppRoutes.supplierMap),
          ),
          _CareTile(
            icon: Icons.person_outline,
            title: 'Profile and settings',
            subtitle: 'Account, theme and sign out',
            onTap: () => context.push(AppRoutes.profile),
          ),
          _CareTile(
            icon: Icons.science_outlined,
            title: 'Pod simulator',
            subtitle: 'Demo tools: trigger pH crashes, low water and more',
            onTap: () => context.push(AppRoutes.simulator),
          ),
        ],
      ),
    );
  }
}

class _CareTile extends StatelessWidget {
  const _CareTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.s12),
      child: Card(
        child: ListTile(
          minVerticalPadding: AgSpace.s12,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
