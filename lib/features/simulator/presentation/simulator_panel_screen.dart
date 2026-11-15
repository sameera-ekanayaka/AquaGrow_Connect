import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/simulator/domain/scenario_groups.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presenter tools: push a pod into a scenario during the demo.
///
/// The selected pod's live pH, water level and water temperature sit at the
/// top, so the audience sees a scenario take effect without leaving the
/// panel. Scenarios are grouped as Water, Nutrients and Device, with a reset
/// to healthy above them.
///
/// This is the ONLY screen allowed to talk to the simulator directly.
class SimulatorPanelScreen extends ConsumerStatefulWidget {
  /// Creates the simulator panel.
  const SimulatorPanelScreen({super.key});

  @override
  ConsumerState<SimulatorPanelScreen> createState() =>
      _SimulatorPanelScreenState();
}

class _SimulatorPanelScreenState extends ConsumerState<SimulatorPanelScreen> {
  void _apply(PodSimulator sim, String podId, SimScenario scenario) {
    setState(() => sim.applyScenario(podId, scenario));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${scenario.label} applied')));
  }

  @override
  Widget build(BuildContext context) {
    final sim = ref.watch(podSimulatorProvider);
    final pods = ref.watch(podsProvider).valueOrNull ?? const <Pod>[];
    final selectedId = ref.watch(selectedPodIdProvider);
    final pod = ref.watch(selectedPodProvider);
    final active = sim.scenarioOf(selectedId);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pod simulator')),
      // A short, fixed set of controls: built all at once so every scenario
      // is ready to tap (and to find in the demo test).
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AgSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Readings come from a software model of the pod. Trigger a '
              'scenario and watch the values below change.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AgSpace.s16),
            if (pods.length > 1)
              SegmentedButton<String>(
                segments: [
                  for (final p in pods)
                    ButtonSegment(value: p.id, label: Text(p.name)),
                ],
                selected: {selectedId},
                onSelectionChanged: (s) =>
                    ref.read(selectedPodIdProvider.notifier).state = s.first,
              ),
            const SizedBox(height: AgSpace.s16),
            if (pod != null) _LiveReadings(pod: pod),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Live readings'),
              subtitle: const Text('Pause to freeze the values on screen'),
              value: sim.isRunning,
              onChanged: (on) => setState(() => on ? sim.start() : sim.stop()),
            ),
            const SizedBox(height: AgSpace.s8),
            OutlinedButton.icon(
              onPressed: active == resetScenario
                  ? null
                  : () => _apply(sim, selectedId, resetScenario),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(
                active == resetScenario
                    ? 'Pod is healthy'
                    : 'Reset to ${resetScenario.label.toLowerCase()}',
              ),
            ),
            for (final group in ScenarioGroup.values) ...[
              const SizedBox(height: AgSpace.s16),
              SectionHeader(title: group.label),
              for (final scenario in group.scenarios)
                Padding(
                  padding: const EdgeInsets.only(bottom: AgSpace.s8),
                  child: _ScenarioTile(
                    scenario: scenario,
                    active: scenario == active,
                    onTap: () => _apply(sim, selectedId, scenario),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// pH, water level and water temperature of [pod], live.
class _LiveReadings extends ConsumerWidget {
  const _LiveReadings({required this.pod});

  final Pod pod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView(
      value: ref.watch(latestReadingProvider(pod.id)),
      onRetry: () => ref.invalidate(latestReadingProvider(pod.id)),
      data: (reading) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final metric in panelMetrics) ...[
            if (metric != panelMetrics.first) const SizedBox(width: AgSpace.s8),
            Expanded(
              child: Builder(
                builder: (context) {
                  final value = metric.valueOf(reading);
                  final status = pod.isOnline
                      ? metric.statusOf(value)
                      : SensorStatus.normal;
                  return SensorTile(
                    label: metric.label,
                    value: metric.format(value),
                    caption: pod.isOnline ? statusInWords(status) : 'Offline',
                    status: status,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One scenario button, with an "Active" badge on the one running now.
class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.scenario,
    required this.active,
    required this.onTap,
  });

  final SimScenario scenario;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ag;
    return Material(
      color: active ? c.brandSurface : c.surface,
      borderRadius: AgRadius.all(AgRadius.r20),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minVerticalPadding: AgSpace.s12,
        title: Text(scenario.label),
        subtitle: Text(scenario.description),
        trailing: active
            ? const StatusBadge(label: 'Active', tone: BadgeTone.brand)
            : const Icon(Icons.play_arrow_rounded),
        onTap: onTap,
      ),
    );
  }
}
