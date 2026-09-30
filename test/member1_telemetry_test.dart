import 'package:flutter_test/flutter_test.dart';
import 'package:aquagrow_connect/features/simulator/domain/simulator_state.dart';
import 'package:aquagrow_connect/features/simulator/services/simulation_engine.dart';

void main() {
  group('SimulationEngine Tests', () {
    late SimulationEngine engine;

    setUp(() {
      engine = SimulationEngine();
    });

    test('Initial state should have default values', () {
      expect(engine.currentState.ph, 6.0);
      expect(engine.currentState.waterLevel, 100.0);
    });

    test('simulateLowWaterAlarm updates waterLevel to 10.0', () {
      engine.simulateLowWaterAlarm();
      expect(engine.currentState.waterLevel, 10.0);
    });

    test('simulateAcidicSpike updates ph to 4.8', () {
      engine.simulateAcidicSpike();
      expect(engine.currentState.ph, 4.8);
    });

    test('simulateNutrientDepletion updates ec to 0.4', () {
      engine.simulateNutrientDepletion();
      expect(engine.currentState.ec, 0.4);
    });
  });
}
