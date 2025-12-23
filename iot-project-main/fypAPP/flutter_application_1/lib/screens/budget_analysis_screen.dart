import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetAnalysisScreen extends StatefulWidget {
  final double monthlyBudget;

  const BudgetAnalysisScreen({super.key, required this.monthlyBudget});

  @override
  State<BudgetAnalysisScreen> createState() => _BudgetAnalysisScreenState();
}

class _BudgetAnalysisScreenState extends State<BudgetAnalysisScreen> {
  final double unitRate = 55;

  final Map<String, double> devicePower = {
    'Bulb': 20,
    'Fan': 75,
    'Pump': 750,
    'Bell': 10,
  };

  final Map<String, double> weeklyHours = {
    'Bulb': 40,
    'Fan': 56,
    'Pump': 14,
    'Bell': 2,
  };

  late double weeklyBudget;
  late Map<String, double> weeklyUnits;
  late Map<String, String> recommendations;
  late double totalWeeklyBill;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    weeklyBudget = widget.monthlyBudget / 4;
    weeklyUnits = {};
    recommendations = {};
    totalWeeklyBill = 0;
    _calculateUsage();

    // Simulate real-time updates every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateDataUpdate();
    });
  }

  void _calculateUsage() {
    weeklyUnits.clear();
    recommendations.clear();
    totalWeeklyBill = 0;

    devicePower.forEach((device, power) {
      final hours = weeklyHours[device]!;
      final units = (power * hours) / 1000;
      weeklyUnits[device] = units;
      totalWeeklyBill += units * unitRate;
    });

    final thresholdPerDevice = weeklyBudget / weeklyUnits.length;

    weeklyUnits.forEach((device, units) {
      final cost = units * unitRate;
      recommendations[device] =
          cost > thresholdPerDevice ? 'Exceeding budget' : 'Within budget';
    });

    setState(() {});
  }

  void _simulateDataUpdate() {
    weeklyUnits.forEach((device, units) {
      // small random fluctuation for simulation
      final change = ([-1, 0, 1]..shuffle()).first * 0.5;
      weeklyUnits[device] = (units + change).clamp(0, double.infinity);
    });

    totalWeeklyBill =
        weeklyUnits.values.fold(0, (sum, units) => sum + units * unitRate);

    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8DBCC7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0ABAB5),
        title: const Text('Budget Analysis'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryCard(),
            const SizedBox(height: 20),
            Expanded(child: _barChart()),
            const SizedBox(height: 12),
            Expanded(child: _recommendationList()),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Monthly Budget',
                'PKR ${widget.monthlyBudget.toStringAsFixed(0)}'),
            _row('Weekly Budget', 'PKR ${weeklyBudget.toStringAsFixed(0)}'),
            _row(
                'Estimated Weekly Bill', 'PKR ${totalWeeklyBill.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _barChart() {
    final devices = weeklyUnits.keys.toList();
    final values = weeklyUnits.values.toList();
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (v, _) => Text(
                    v.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(devices[v.toInt()],
                        style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ),
            ),
            barGroups: List.generate(devices.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFF4FC3F7),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _recommendationList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: recommendations.entries.map((e) {
          final isHigh = e.value.contains('Exceeding');
          return ListTile(
            leading: Icon(
              isHigh ? Icons.warning : Icons.check_circle,
              color: isHigh ? Colors.red : Colors.green,
            ),
            title: Text(e.key),
            subtitle: Text(e.value),
            trailing: Text(
              '${(weeklyUnits[e.key]! * unitRate).toStringAsFixed(0)} PKR',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }
}
