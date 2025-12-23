import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/device_model.dart';

class DeviceDetailScreen extends StatelessWidget {
  final DeviceModel device;

  const DeviceDetailScreen({Key? key, required this.device}) : super(key: key);

  Widget _buildGraphCard(String title, List<double> data, String yLabel) {
    double interval = _calculateYAxisInterval(data);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        // Map index (0..N-1) to 1..24 hours
                        double hour = 1 + (23 * e.key / (data.length - 1));
                        return FlSpot(hour, e.value);
                      }).toList(),
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(yLabel),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(1));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Hour'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int hour = value.round();
                          if (hour >= 1 && hour <= 24) return Text(hour.toString());
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic Y-axis interval to prevent label overlapping
  double _calculateYAxisInterval(List<double> data) {
    if (data.isEmpty) return 1;
    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double range = maxVal - minVal;
    if (range == 0) return 1; // avoid zero interval
    return range / 5; // ~5 labels on Y-axis
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGraphCard('Voltage (V)', device.voltageHistory, 'Voltage (V)'),
            _buildGraphCard('Current (A)', device.currentHistory, 'Current (A)'),
            _buildGraphCard('Power (W)', device.powerHistory, 'Power (W)'),
          ],
        ),
      ),
    );
  }
}
