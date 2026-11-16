import 'package:aquagrow_mobile/app/router/app_routes.dart';
import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:aquagrow_mobile/core/models/user_profile.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/auth/domain/initials.dart';
import 'package:aquagrow_mobile/features/auth/presentation/auth_providers.dart';
import 'package:aquagrow_mobile/features/auth/presentation/widgets/delete_account_dialog.dart';
import 'package:aquagrow_mobile/features/sync/application/sync_providers.dart';
import 'package:aquagrow_mobile/features/sync/application/sync_service.dart';
import 'package:aquagrow_mobile/features/sync/domain/last_synced_label.dart';
import 'package:aquagrow_mobile/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen displaying user profile, active farm statistics, security status,
/// and profile/account actions.
class ProfileScreen extends ConsumerWidget {
  /// Creates the profile screen.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final mode = ref.watch(appConfigProvider).dataMode;
    final sync = ref.watch(syncServiceProvider);
    final now = ref.watch(syncClockProvider).valueOrNull ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AgSpace.screen),
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: AgSpace.s16),
            const _ProfileStatsRow(),
            const SizedBox(height: AgSpace.s24),
            _RowGroup(
              children: [
                _ProfileRow(
                  key: const Key('profile-edit-row'),
                  icon: Icons.person_outline,
                  title: 'Edit profile',
                  subtitle: 'Update your name, farm name, and phone',
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                _ProfileRow(
                  key: const Key('profile-password-row'),
                  icon: Icons.lock_outline,
                  title: 'Change password',
                  subtitle: 'Update your account credentials',
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
              ],
            ),
            const SizedBox(height: AgSpace.s16),
            _RowGroup(
              children: [
                _ProfileRow(
                  key: const Key('profile-last-synced'),
                  icon: Icons.sync_rounded,
                  title: 'Last synced',
                  subtitle: _syncSubtitle(sync, now),
                ),
                _ProfileRow(
                  icon: Icons.storage_rounded,
                  title: 'Data mode',
                  subtitle: mode == DataMode.live
                      ? 'Live · Supabase'
                      : 'Simulation · built-in pods',
                  onTap: () => context.push(AppRoutes.settings),
                ),
                _ProfileRow(
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  subtitle: 'Your pods are private to your account.',
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
            const SizedBox(height: AgSpace.s16),
            _RowGroup(
              children: [
                _ProfileRow(
                  key: const Key('profile-sign-out'),
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  subtitle: 'You will need to sign in again',
                  destructive: true,
                  onTap: () => _confirmSignOut(context, ref),
                ),
                _ProfileRow(
                  key: const Key('profile-delete-account'),
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete account',
                  subtitle:
                      'Permanently remove your account and all pod history',
                  destructive: true,
                  onTap: () => showDeleteAccountFlow(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _syncSubtitle(SyncStatus sync, DateTime now) {
    final when = lastSyncedLabel(sync.lastSyncedAt, now: now);
    if (sync.pending > 0) {
      final waiting = '${sync.pending} '
          '${sync.pending == 1 ? 'reading' : 'readings'} waiting';
      return sync.offline ? 'Offline · $waiting' : '$when · $waiting';
    }
    if (sync.lastSyncedAt == null) return when;
    return '$when · ${sync.lastSyncedCount} '
        '${sync.lastSyncedCount == 1 ? 'reading' : 'readings'}';
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You will need your email and password to sign back in.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (ok) await ref.read(authControllerProvider.notifier).signOut();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final name = user?.fullName?.trim();
    final shownName = (name == null || name.isEmpty) ? 'AquaGrow grower' : name;
    final farm = user?.farmName?.trim();

    return Row(
      children: [
        CircleAvatar(
          radius: kMinTouchTarget / 2 + AgSpace.s4,
          backgroundColor: c.brand,
          child: Text(
            initialsFor(fullName: user?.fullName, email: user?.email),
            style: text.titleMedium?.copyWith(color: AgColors.light.text),
          ),
        ),
        const SizedBox(width: AgSpace.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shownName, style: text.titleLarge),
              if (farm != null && farm.isNotEmpty)
                Text(
                  farm,
                  style: text.bodyMedium?.copyWith(color: c.brand),
                ),
              if (user != null)
                Text(
                  user!.email,
                  style: text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStatsRow extends ConsumerWidget {
  const _ProfileStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pods = ref.watch(podsProvider).valueOrNull ?? const [];
    final unreadAlerts = ref.watch(unreadAlertCountProvider);
    final cropsCount = pods.where((p) => p.batch != null).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Pods',
            value: '${pods.length}',
            icon: Icons.grain_outlined,
          ),
        ),
        const SizedBox(width: AgSpace.s8),
        Expanded(
          child: _StatCard(
            label: 'Crops',
            value: '$cropsCount',
            icon: Icons.eco_outlined,
          ),
        ),
        const SizedBox(width: AgSpace.s8),
        Expanded(
          child: _StatCard(
            label: 'Alerts',
            value: '$unreadAlerts',
            icon: Icons.notifications_none,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AgSpace.s12,
        vertical: AgSpace.s8,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.all(AgRadius.r16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(height: AgSpace.s4),
          Text(value, style: text.titleMedium),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _RowGroup extends StatelessWidget {
  const _RowGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AgRadius.all(AgRadius.r20),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    final tone = destructive ? c.critical : c.text;

    return ListTile(
      onTap: onTap,
      minVerticalPadding: AgSpace.s12,
      leading: CircleAvatar(
        backgroundColor: destructive ? c.criticalSurface : c.subtle,
        child: Icon(icon, color: tone),
      ),
      title: Text(title, style: text.titleMedium?.copyWith(color: tone)),
      subtitle: Text(subtitle, style: text.bodySmall),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right_rounded, color: c.textSecondary),
    );
  }
}
