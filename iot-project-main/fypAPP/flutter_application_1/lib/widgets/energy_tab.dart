import 'package:flutter/material.dart';
import '../models/device_model.dart';

class EnergyTab extends StatelessWidget {
  final List<DeviceModel> appliancesList;

  const EnergyTab({super.key, required this.appliancesList}); // 👈 fix yahan

  @override
  Widget build(BuildContext context) {
    double totalEnergy = 0;
    for (var device in appliancesList) {
      totalEnergy += device.energy;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Energy Analytics",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Text(
            "Total Energy Usage: ${totalEnergy.toStringAsFixed(2)} kWh",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: appliancesList.length,
              itemBuilder: (context, index) {
                final device = appliancesList[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      device.isOn ? Icons.power : Icons.power_off,
                      color: device.isOn ? Colors.green : Colors.red,
                    ),
                    title: Text(device.name),
                    subtitle: Text(
                      "Power: ${device.power}W | Current: ${device.current}A",
                    ),
                    trailing: Text(
                      "${device.energy.toStringAsFixed(2)} kWh",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
