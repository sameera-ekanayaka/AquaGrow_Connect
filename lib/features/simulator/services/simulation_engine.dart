import 'dart:async';
import '../domain/simulator_state.dart';

class SimulationEngine {
  SimulatorState _currentState = const SimulatorState();
  final _stateController = StreamController<SimulatorState>.broadcast();

  Stream<SimulatorState> get stateStream => _stateController.stream;
  SimulatorState get currentState => _currentState;

  void updateState(SimulatorState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }

  void simulateLowWaterAlarm() {
    updateState(_currentState.copyWith(waterLevel: 10.0));
  }

  void simulateAcidicSpike() {
    updateState(_currentState.copyWith(ph: 4.8));
  }

  void simulateNutrientDepletion() {
    updateState(_currentState.copyWith(ec: 0.4));
  }

  void dispose() {
    _stateController.close();
  }
}
