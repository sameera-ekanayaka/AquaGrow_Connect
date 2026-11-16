import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/features/auth/application/app_lock_controller.dart';
import 'package:aquagrow_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puts the lock screen over the whole app while the optional app lock is
/// locked, and tells the lock when the app leaves and returns
/// (lecture 4: the app lifecycle).
///
/// Wrap the router's output once, in `AquaGrowApp`, so pushed screens such
/// as Crop detail and Settings are covered too. It only locks while
/// [active], i.e. while someone is signed in.
class AppLockGate extends ConsumerStatefulWidget {
  /// Wraps [child], locking it while [active] and the lock is on.
  const AppLockGate({required this.child, required this.active, super.key});

  /// The whole app.
  final Widget child;

  /// True while signed in. The sign-in screens are never locked.
  final bool active;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    final lock = ref.read(appLockProvider.notifier);
    // `inactive` also fires while the fingerprint dialog is showing, so only
    // a real trip to the background counts.
    if (lifecycle == AppLifecycleState.paused) lock.onBackground();
    if (lifecycle == AppLifecycleState.resumed) lock.onForeground();
  }

  @override
  Widget build(BuildContext context) {
    final locked =
        widget.active && ref.watch(appLockProvider.select((s) => s.locked));
    return Stack(
      children: [
        // Screen readers must not read the hidden app either.
        ExcludeSemantics(excluding: locked, child: widget.child),
        if (locked) const Positioned.fill(child: AppLockScreen()),
      ],
    );
  }
}

/// "AquaGrow is locked": asks for the fingerprint as soon as it appears,
/// with an Unlock button to try again.
class AppLockScreen extends ConsumerStatefulWidget {
  /// Creates the lock screen.
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() => ref.read(appLockProvider.notifier).unlock();

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;
    return Material(
      color: c.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AgSpace.screen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kAuthFormMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthLogo(alignment: Alignment.center),
                  const SizedBox(height: AgSpace.s24),
                  Icon(Icons.lock_outline_rounded, color: c.textSecondary),
                  const SizedBox(height: AgSpace.s12),
                  Semantics(
                    header: true,
                    child: Text(
                      'AquaGrow is locked',
                      style: text.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AgSpace.s8),
                  Text(
                    'Use your fingerprint, face or phone PIN to open it.',
                    style: text.bodyMedium?.copyWith(color: c.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AgSpace.s32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('app-lock-unlock'),
                      onPressed: _unlock,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Unlock'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
