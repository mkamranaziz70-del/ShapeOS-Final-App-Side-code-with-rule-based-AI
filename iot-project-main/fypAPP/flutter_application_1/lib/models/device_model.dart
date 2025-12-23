class DeviceModel {
  final String id;
  final String name;
  final String type;
  final bool isOn;
  final double power;
  final double voltage;
  final double current;
  final double currentLeakage;
  final double voltageLeakage;
  final double energy;
  final List<double> voltageHistory;
  final List<double> currentHistory;
  final List<double> powerHistory;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.isOn,
    required this.power,
    required this.voltage,
    required this.current,
    required this.currentLeakage,
    required this.voltageLeakage,
    required this.energy,
    List<double>? voltageHistory,
    List<double>? currentHistory,
    List<double>? powerHistory,
  })  : voltageHistory = voltageHistory ?? [],
        currentHistory = currentHistory ?? [],
        powerHistory = powerHistory ?? [];

  DeviceModel copyWith({
    String? id,
    String? name,
    String? type,
    bool? isOn,
    double? power,
    double? voltage,
    double? current,
    double? currentLeakage,
    double? voltageLeakage,
    double? energy,
    List<double>? voltageHistory,
    List<double>? currentHistory,
    List<double>? powerHistory,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isOn: isOn ?? this.isOn,
      power: power ?? this.power,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      currentLeakage: currentLeakage ?? this.currentLeakage,
      voltageLeakage: voltageLeakage ?? this.voltageLeakage,
      energy: energy ?? this.energy,
      voltageHistory: voltageHistory ?? List.from(this.voltageHistory),
      currentHistory: currentHistory ?? List.from(this.currentHistory),
      powerHistory: powerHistory ?? List.from(this.powerHistory),
    );
  }
}
