import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/device_model.dart';

class DeviceDetailScreen extends StatefulWidget {
  final DeviceModel device;

  const DeviceDetailScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late DatabaseReference _deviceRef;
  StreamSubscription<DatabaseEvent>? _subscription;

  final List<FlSpot> _voltageSpots = [];
  final List<FlSpot> _currentSpots = [];
  final List<FlSpot> _powerSpots = [];

  double _timeIndex = 0;
  static const int maxPoints = 50;

  @override
  void initState() {
    super.initState();
    _deviceRef = FirebaseDatabase.instance
        .ref('appliances_by_type/${widget.device.type}');
    _subscription = _deviceRef.onValue.listen(_onData);
  }

  void _onData(DatabaseEvent event) {
    if (!mounted || event.snapshot.value == null) return;

    final raw = Map<String, dynamic>.from(event.snapshot.value as Map);

    final voltage = (raw['voltage'] as num?)?.toDouble() ?? 0;
    final current = (raw['current'] as num?)?.toDouble() ?? 0;
    final power = (raw['power'] as num?)?.toDouble() ?? 0;

    setState(() {
      _timeIndex++;

      _voltageSpots.add(FlSpot(_timeIndex, voltage));
      _currentSpots.add(FlSpot(_timeIndex, current));
      _powerSpots.add(FlSpot(_timeIndex, power));

      if (_voltageSpots.length > maxPoints) {
        _voltageSpots.removeAt(0);
        _currentSpots.removeAt(0);
        _powerSpots.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name.toUpperCase()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildChart('Voltage (V)', Colors.blue, _voltageSpots),
            _buildChart('Current (A)', Colors.green, _currentSpots),
            _buildChart('Power (W)', Colors.red, _powerSpots),
          ],
        ),
      ),
    );
  }

  // ───────────────── CHART ─────────────────

  Widget _buildChart(String title, Color color, List<FlSpot> spots) {
    if (spots.isEmpty) {
      return _emptyCard(title);
    }

    final values = spots.map((e) => e.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);

    // 🔥 CLEAN & STABLE AXIS
    final padding = (maxY - minY) * 0.2 + 0.01;
    final axisMin = (minY - padding);
    final axisMax = (maxY + padding);
    final interval = (axisMax - axisMin) / 4;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: spots.first.x,
                  maxX: spots.last.x,
                  minY: axisMin,
                  maxY: axisMax,
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: interval,
                        getTitlesWidget: (value, _) {
                          return Text(
                            value.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, _) =>
                            Text(value.toInt().toString()),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 160,
        child: Center(
          child: Text(
            '$title\nWaiting for data...',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
