import 'package:aquagrow_mobile/core/config/app_config.dart';
import 'package:aquagrow_mobile/core/config/app_info.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/auth/application/app_lock_controller.dart';
import 'package:aquagrow_mobile/features/settings/application/theme_mode_controller.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = AppLogger('settings');

/// Settings: theme, app facts, the app lock, the privacy note and the team.
///
/// OWNER: Tharindu (see docs/tasks/tharindu.md, item 4).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AgSpace.screen),
          children: const [
            SectionHeader(title: 'Appearance'),
            _ThemeCard(),
            SizedBox(height: AgSpace.s20),
            SectionHeader(title: 'App'),
            _AppCard(),
            SizedBox(height: AgSpace.s20),
            SectionHeader(title: 'Privacy'),
            _AppLockCard(),
            SizedBox(height: AgSpace.s12),
            _PrivacyCard(),
            SizedBox(height: AgSpace.s20),
            SectionHeader(title: 'About'),
            _AboutCard(),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends ConsumerWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.s12),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.phone_android_outlined),
                label: Text('System'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).select(selection.first),
          ),
        ),
      ),
    );
  }
}

class _AppCard extends ConsumerWidget {
  const _AppCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appConfigProvider).dataMode;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Data mode'),
            subtitle: Text(
              mode == DataMode.live
                  ? 'Your pods, from the cloud'
                  : 'Built-in pod simulator, no network needed',
            ),
            trailing: Text(mode == DataMode.live ? 'Live' : 'Simulation'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text(AppInfo.versionLabel),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends ConsumerWidget {
  const _PrivacyCard();

  /// What is stored, and where. Shown as a short list.
  static const _facts = [
    (
      Icons.phone_android_outlined,
      'On this phone',
      'Up to 72 hours of pod readings for offline use, readings waiting to '
          'upload, and your app settings such as the theme.',
    ),
    (
      Icons.lock_outline,
      'In secure storage',
      'Your sign-in tokens only, protected by the Android Keystore.',
    ),
    (
      Icons.cloud_outlined,
      'In the cloud (live mode)',
      'Your account, your pods and their readings. Only you can read them.',
    ),
    (
      Icons.location_on_outlined,
      'Location',
      'Used only to look up local weather and nearby suppliers. Never saved.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = context.ag;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (icon, title, body) in _facts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon),
                title: Text(title),
                subtitle: Text(body),
              ),
            const SizedBox(height: AgSpace.s8),
            Text(
              'Deleting local data does not touch your account or cloud data.',
              style: text.bodySmall?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AgSpace.s12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.critical,
                  side: BorderSide(color: c.critical),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete my local data'),
                onPressed: () => _delete(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete local data?',
      message: 'This removes saved readings, readings waiting to upload and '
          'your app settings from this phone. Readings that were not uploaded '
          'yet are lost. Your account and cloud data stay as they are.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    var message = 'Local data deleted';
    try {
      await ref.read(localDataEraserProvider).eraseAll();
      ref.read(themeModeProvider.notifier).reload();
      ref.read(appLockProvider.notifier).reload();
    } catch (e, st) {
      _log.error('Deleting local data failed', e, st);
      message = 'Could not delete local data. Please try again.';
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The optional app lock, like WhatsApp's fingerprint lock. Turning it on
/// or off asks for the phone's fingerprint, face or PIN first.
class _AppLockCard extends ConsumerStatefulWidget {
  const _AppLockCard();

  @override
  ConsumerState<_AppLockCard> createState() => _AppLockCardState();
}

class _AppLockCardState extends ConsumerState<_AppLockCard> {
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    final lock = ref.read(appLockProvider.notifier);
    final problem = on ? await lock.enable() : await lock.disable();
    if (!mounted) return;
    setState(() => _busy = false);
    // Replace any earlier message instead of queueing behind it.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(problem ?? (on ? 'App lock is on' : 'App lock is off')),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(appLockProvider.select((s) => s.enabled));
    return Card(
      child: SwitchListTile(
        key: const Key('settings-app-lock'),
        secondary: const Icon(Icons.fingerprint_rounded),
        title: const Text('App lock'),
        subtitle: const Text(
          'Ask for your fingerprint, face or phone PIN when you open '
          'AquaGrow, and after 1 minute away.',
        ),
        value: enabled,
        onChanged: _busy ? null : _toggle,
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Built by'),
            subtitle: Text(AppInfo.team.join(', ')),
          ),
          const ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('Module'),
            subtitle: Text(AppInfo.module),
          ),
        ],
      ),
    );
  }
}
