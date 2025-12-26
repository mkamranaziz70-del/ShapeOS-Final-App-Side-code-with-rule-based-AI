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

  // 🔹 History for graphs / AI
  final List<double> voltageHistory;
  final List<double> currentHistory;
  final List<double> powerHistory;

  const DeviceModel({
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
    this.voltageHistory = const [],
    this.currentHistory = const [],
    this.powerHistory = const [],
  });

  // =========================================================
  // 🔹 COPY WITH (BACKWARD + FORWARD COMPATIBLE)
  // =========================================================
  DeviceModel copyWith({
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
      id: id,
      name: name,
      type: type,
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

  // =========================================================
  // 🔹 FIREBASE SERIALIZATION
  // =========================================================
  Map<String, dynamic> toMap() => {
        "name": name,
        "type": type,
        "isOn": isOn,
        "power": power,
        "voltage": voltage,
        "current": current,
        "currentLeakage": currentLeakage,
        "voltageLeakage": voltageLeakage,
        "energy": energy,
        "voltageHistory": voltageHistory,
        "currentHistory": currentHistory,
        "powerHistory": powerHistory,
      };

  // =========================================================
  // 🔹 FIREBASE DESERIALIZATION (SAFE FOR OLD DATA)
  // =========================================================
  factory DeviceModel.fromMap(Map<dynamic, dynamic> map, String id) {
    if (!map.containsKey('name') || !map.containsKey('type')) {
      throw Exception("Not a device node");
    }

    return DeviceModel(
      id: id,
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      isOn: map['isOn'] == true,
      power: _toDouble(map['power']),
      voltage: _toDouble(map['voltage']),
      current: _toDouble(map['current']),
      currentLeakage: _toDouble(map['currentLeakage']),
      voltageLeakage: _toDouble(map['voltageLeakage']),
      energy: _toDouble(map['energy']),
      voltageHistory: _toDoubleList(map['voltageHistory']),
      currentHistory: _toDoubleList(map['currentHistory']),
      powerHistory: _toDoubleList(map['powerHistory']),
    );
  }

  // =========================================================
  // 🔹 SAFE PARSERS
  // =========================================================
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static List<double> _toDoubleList(dynamic value) {
    if (value == null || value is! List) return [];
    return value.map((e) => _toDouble(e)).toList();
  }
}
