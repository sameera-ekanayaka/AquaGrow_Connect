import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/logging/app_logger.dart';
import 'package:aquagrow_mobile/core/models/new_pod.dart';
import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/crops/domain/new_pod_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _log = AppLogger('crops');

/// Opens [AddPodScreen] full screen. Completes with the new pod, or null if
/// the user closed it.
Future<Pod?> showAddPodScreen(BuildContext context) {
  return showDialog<Pod>(
    context: context,
    useSafeArea: false,
    builder: (_) => const Dialog.fullscreen(child: AddPodScreen()),
  );
}

/// "Add a pod" from Figma: name, room, serial number and system type.
///
/// Saves through `podRepositoryProvider`, so it works in simulation mode
/// (the pod lasts for the session) and live mode (a Supabase `devices` row).
/// The new pod becomes the selected pod. Adding is not risky and can be
/// undone, so there is no confirm dialog.
class AddPodScreen extends ConsumerStatefulWidget {
  /// Creates the Add a pod form.
  const AddPodScreen({super.key});

  @override
  ConsumerState<AddPodScreen> createState() => _AddPodScreenState();
}

class _AddPodScreenState extends ConsumerState<AddPodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _room = TextEditingController();
  final _serial = TextEditingController();
  PodSystemType _type = PodSystemType.nft;
  bool _busy = false;

  /// After the first try, errors update as the user types.
  bool _tried = false;

  /// "Already registered", from the repository, shown under the serial field.
  String? _serialTaken;

  /// Any other failure, shown above the button.
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    _serial.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _tried = true;
      _serialTaken = null;
      _error = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      final pod = await ref.read(podRepositoryProvider).addPod(
            NewPod(
              name: _name.text,
              room: _room.text,
              serialNumber: _serial.text,
              systemType: _type,
            ),
          );
      ref.read(selectedPodIdProvider.notifier).state = pod.id;
      // Live mode: read the list again in case realtime is slow.
      ref.invalidate(podsProvider);
      if (mounted) Navigator.of(context).pop(pod);
    } on ValidationFailure catch (e) {
      setState(() => _serialTaken = e.message);
      _formKey.currentState?.validate();
    } on AppFailure catch (e) {
      _log.warning('Add pod failed: ${e.message}');
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Add a pod'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _tried
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.all(AgSpace.screen),
            children: [
              Text(
                'Find the serial number on the label under your pod.',
                style: text.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AgSpace.s24),
              TextFormField(
                key: const Key('add-pod-name'),
                controller: _name,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Pod name',
                  helperText: 'Shown on Home and My Pods.',
                  prefixIcon: Icon(Icons.spa_outlined),
                ),
                validator: NewPodRules.name,
              ),
              const SizedBox(height: AgSpace.s16),
              TextFormField(
                key: const Key('add-pod-room'),
                controller: _room,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  helperText: 'Where the pod sits, for example Kitchen.',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: NewPodRules.room,
              ),
              const SizedBox(height: AgSpace.s16),
              TextFormField(
                key: const Key('add-pod-serial'),
                controller: _serial,
                enabled: !_busy,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_serialTaken != null) setState(() => _serialTaken = null);
                },
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Serial number',
                  helperText: 'On the label under the pod.',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
                validator: (v) => NewPodRules.serialNumber(v) ?? _serialTaken,
              ),
              const SizedBox(height: AgSpace.s24),
              Text('System type', style: text.labelLarge),
              const SizedBox(height: AgSpace.s8),
              SegmentedButton<PodSystemType>(
                segments: [
                  for (final t in PodSystemType.values)
                    ButtonSegment(value: t, label: Text(t.code)),
                ],
                selected: {_type},
                onSelectionChanged:
                    _busy ? null : (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: AgSpace.s8),
              Text(
                '${_type.code}: ${_type.description}',
                style: text.bodySmall,
              ),
              const SizedBox(height: AgSpace.s32),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: text.bodyMedium?.copyWith(color: c.critical),
                ),
                const SizedBox(height: AgSpace.s12),
              ],
              FilledButton(
                key: const Key('add-pod-submit'),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: AgSpace.s20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add pod'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
