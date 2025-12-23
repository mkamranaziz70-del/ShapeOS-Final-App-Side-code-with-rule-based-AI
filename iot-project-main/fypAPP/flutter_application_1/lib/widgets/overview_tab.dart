import 'package:flutter/material.dart';
import '../models/device_model.dart';

class OverviewTab extends StatelessWidget {
  final List<DeviceModel> appliances;
  final Function(DeviceModel) onDeviceTap;

  const OverviewTab({
    super.key,
    required this.appliances,
    required this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (appliances.isEmpty) {
      return const Center(
        child: Text('No devices available'),
      );
    }

    // 🔹 REMOVE DUPLICATES (by device type)
    final Map<String, DeviceModel> uniqueMap = {};
    for (final device in appliances) {
      uniqueMap.putIfAbsent(device.type.toLowerCase(), () => device);
    }
    final uniqueAppliances = uniqueMap.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: uniqueAppliances.length,
      itemBuilder: (context, index) {
        final device = uniqueAppliances[index];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 24), // 🔹 increased spacing between cards
          child: InkWell(
            onTap: () => onDeviceTap(device),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // 🔹 more vertical padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    device.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
