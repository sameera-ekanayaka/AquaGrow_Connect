class SimulatorState {
  final double ph;
  final double ec;
  final double waterTemp;
  final double waterLevel;
  final double ambientTemp;
  final double humidity;

  const SimulatorState({
    this.ph = 6.0,
    this.ec = 1.2,
    this.waterTemp = 22.0,
    this.waterLevel = 100.0,
    this.ambientTemp = 25.0,
    this.humidity = 60.0,
  });

  SimulatorState copyWith({
    double? ph,
    double? ec,
    double? waterTemp,
    double? waterLevel,
    double? ambientTemp,
    double? humidity,
  }) {
    return SimulatorState(
      ph: ph ?? this.ph,
      ec: ec ?? this.ec,
      waterTemp: waterTemp ?? this.waterTemp,
      waterLevel: waterLevel ?? this.waterLevel,
      ambientTemp: ambientTemp ?? this.ambientTemp,
      humidity: humidity ?? this.humidity,
    );
  }
}
