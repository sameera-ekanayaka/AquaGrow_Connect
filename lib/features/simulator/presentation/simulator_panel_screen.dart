import 'package:aquagrow_mobile/core/models/pod.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/core/theme/app_tokens.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presenter tools: push a pod into a scenario during the demo.
///
/// OWNER: Osanda (see docs/tasks/osanda.md). Works now; polish the layout.
/// This is the ONLY screen allowed to talk to the simulator directly.
class SimulatorPanelScreen extends ConsumerStatefulWidget {
  const SimulatorPanelScreen({super.key});

  @override
  ConsumerState<SimulatorPanelScreen> createState() => _SimulatorPanelScreenState();
}

class _SimulatorPanelScreenState extends ConsumerState<SimulatorPanelScreen> {
  @override
  Widget build(BuildContext context) {
    final sim = ref.watch(podSimulatorProvider);
    final pods = ref.watch(podsProvider).valueOrNull ?? const <Pod>[];
    final selectedId = ref.watch(selectedPodIdProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pod simulator')),
      body: ListView(
        padding: const EdgeInsets.all(AgSpace.screen),
        children: [
          Text(
            'Readings come from a software model of the pod. '
            'Trigger a scenario, then go back to Home to see the app react.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AgSpace.s16),
          if (pods.isNotEmpty)
            SegmentedButton<String>(
              segments: [
                for (final p in pods) ButtonSegment(value: p.id, label: Text(p.name)),
              ],
              selected: {selectedId},
              onSelectionChanged: (s) => ref.read(selectedPodIdProvider.notifier).state = s.first,
            ),
          const SizedBox(height: AgSpace.s8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Live readings'),
            subtitle: const Text('Pause to freeze the values on screen'),
            value: sim.isRunning,
            onChanged: (on) => setState(() => on ? sim.start() : sim.stop()),
          ),
          const SizedBox(height: AgSpace.s8),
          const SectionHeader(title: 'Scenarios'),
          for (final scenario in SimScenario.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AgSpace.s12),
              child: Card(
                child: ListTile(
                  title: Text(scenario.label),
                  subtitle: Text(scenario.description),
                  trailing: sim.scenarioOf(selectedId) == scenario
                      ? const StatusBadge(label: 'Active', tone: BadgeTone.brand)
                      : null,
                  onTap: () {
                    setState(() => sim.applyScenario(selectedId, scenario));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${scenario.label} applied')),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
