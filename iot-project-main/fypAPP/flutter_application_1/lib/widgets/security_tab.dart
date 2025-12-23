// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/device_model.dart';

class SecurityTab extends StatefulWidget {
  final List<DeviceModel> appliances;
  const SecurityTab({super.key, this.appliances = const []});

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab> {
  final alertsRef = FirebaseDatabase.instance.ref("alerts"); // Current status
  final alertsHistoryRef = FirebaseDatabase.instance.ref("alerts_history"); // Full history
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  String selectedFilter = "All"; // Filter dropdown

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  Color getAlertColor(String text) {
    text = text.toLowerCase();
    if (text.contains("smoke")) return Colors.red;
    if (text.contains("flame")) return Colors.deepOrange;
    if (text.contains("motion")) return Colors.green;
    return Colors.blueGrey;
  }

  IconData getAlertIcon(String text) {
    text = text.toLowerCase();
    if (text.contains("smoke")) return Icons.local_fire_department;
    if (text.contains("flame")) return Icons.warning;
    if (text.contains("motion")) return Icons.motion_photos_on;
    return Icons.notifications;
  }

  Map<String, dynamic> safeMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Appliances Section
        if (widget.appliances.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: const Text(
              "Monitored Appliances",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 0,
            child: Column(
              children: widget.appliances.map((device) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: device.isOn ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        device.isOn ? Icons.power : Icons.power_off,
                        color: device.isOn ? Colors.green : Colors.red,
                      ),
                      title: Text(device.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Type: ${device.type}, Power: ${device.power} W"),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Filter Dropdown
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Text("Filter: ", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedFilter,
                items: ["All", "Smoke", "Flame", "Motion"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedFilter = val);
                },
              ),
            ],
          ),
        ),

        // Alerts & History Section
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Current Alerts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                StreamBuilder(
                  stream: alertsRef.onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final raw = (snapshot.data! as DatabaseEvent).snapshot.value;
                    final data = safeMap(raw);
                    if (data.isEmpty) return const Text("No active alerts");

                    final filtered = data.entries.where((e) {
                      if (selectedFilter == "All") return true;
                      return e.key.toLowerCase().contains(selectedFilter.toLowerCase());
                    }).toList();

                    return Column(
                      children: filtered.map((entry) {
                        final name = entry.key;
                        final value = entry.value.toString();
                        final color = getAlertColor(value);
                        final icon = getAlertIcon(value);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [color.withOpacity(0.2), Colors.white]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(2, 2))
                              ],
                            ),
                            child: ListTile(
                              leading: Icon(icon, color: color, size: 32),
                              title: Text(name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(value),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text("Alert History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                StreamBuilder(
                  stream: alertsHistoryRef.onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text("Loading history...");
                    final raw = (snapshot.data! as DatabaseEvent).snapshot.value;
                    final data = safeMap(raw);
                    if (data.isEmpty) return const Text("No history available");

                    final entries = data.entries.toList().reversed.toList();
                    final filtered = entries.where((e) {
                      final event = safeMap(e.value);
                      if (selectedFilter == "All") return true;
                      return (event['event'] ?? "")
                          .toLowerCase()
                          .contains(selectedFilter.toLowerCase());
                    }).toList();

                    return Column(
                      children: filtered.map((entry) {
                        final event = safeMap(entry.value);
                        final color = getAlertColor(event['event'] ?? "");
                        final icon = getAlertIcon(event['event'] ?? "");

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [color.withOpacity(0.2), Colors.white]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(2, 2))
                              ],
                            ),
                            child: ListTile(
                              leading: Icon(icon, color: color, size: 28),
                              title: Text(event['event'] ?? "Unknown",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(event['time'] ?? "-"),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
