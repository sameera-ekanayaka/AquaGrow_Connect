import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/app/shell/tab_header.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/care/presentation/widgets/care_reminders_card.dart';
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
    final colors = context.ag;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AgSpace.screen),
        children: [
          const TabHeader(overline: 'LOOK AFTER YOUR PODS', title: 'Care'),
          Card(
            child: Column(
              children: [
                _CareTile(
                  icon: Icons.storefront_outlined,
                  title: 'Hydroponic suppliers',
                  subtitle: 'Nutrients and parts near you',
                  onTap: () => context.push(AppRoutes.supplierMap),
                ),
                Divider(color: colors.border, height: 1),
                _CareTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'Account and sign out',
                  onTap: () => context.push(AppRoutes.profile),
                ),
                Divider(color: colors.border, height: 1),
                _CareTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Theme, privacy and about',
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: AgSpace.s16),
          Padding(
            padding:
                const EdgeInsets.only(left: AgSpace.s4, bottom: AgSpace.s8),
            child: Text(
              'Demo tools',
              style: textTheme.titleSmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(
            child: _CareTile(
              icon: Icons.science_outlined,
              title: 'Pod simulator',
              subtitle: 'Trigger pH crashes, low water and more',
              onTap: () => context.push(AppRoutes.simulator),
            ),
          ),
          const SizedBox(height: AgSpace.s16),
          const CareRemindersCard(),
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
    return ListTile(
      minVerticalPadding: AgSpace.s12,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
