import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetAnalysisScreen extends StatefulWidget {
  final double monthlyBudget;

  const BudgetAnalysisScreen({super.key, required this.monthlyBudget});

  @override
  State<BudgetAnalysisScreen> createState() => _BudgetAnalysisScreenState();
}

class _BudgetAnalysisScreenState extends State<BudgetAnalysisScreen> {
  final double unitRate = 55; // PKR per unit (kWh)

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('appliances_by_type');

  StreamSubscription<DatabaseEvent>? _subscription;

  /// live calculated values
  Map<String, double> dailyUnits = {};
  Map<String, String> recommendations = {};

  double totalDailyUnits = 0;
  double projectedMonthlyBill = 0;

  late DateTime today;
  late int daysInMonth;
  late int daysPassed;
  late int daysRemaining;

  @override
  void initState() {
    super.initState();
    _initDateLogic();
    _listenFirebase();
  }

  // ================= DATE LOGIC =================
  void _initDateLogic() {
    today = DateTime.now();

    daysInMonth = DateTime(
      today.year,
      today.month + 1,
      0,
    ).day;

    daysPassed = today.day;
    daysRemaining = daysInMonth - daysPassed;
  }

  void _listenFirebase() {
    _subscription = _dbRef.onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;

      dailyUnits.clear();
      recommendations.clear();
      totalDailyUnits = 0;

      final Map data = raw;

      data.forEach((device, value) {
        if (value is Map && value['power'] != null) {
          final double powerWatt =
              (value['power'] as num).toDouble();

          /// daily energy = power × 24 / 1000
          final double unitsPerDay = (powerWatt * 24) / 1000;

          dailyUnits[device.toString()] = unitsPerDay;
          totalDailyUnits += unitsPerDay;
        }
      });

      final totalMonthlyUnits = totalDailyUnits * daysInMonth;
      projectedMonthlyBill = totalMonthlyUnits * unitRate;

      final perDeviceBudget =
          widget.monthlyBudget / (dailyUnits.length == 0 ? 1 : dailyUnits.length);

      dailyUnits.forEach((device, units) {
        final cost = units * daysInMonth * unitRate;
        recommendations[device] =
            cost > perDeviceBudget ? 'Exceeding budget' : 'Within budget';
      });

      if (mounted) setState(() {});
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
      backgroundColor: const Color(0xFFF4F7FA),
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
            const SizedBox(height: 16),
            Expanded(child: _barChart()),
            const SizedBox(height: 12),
            Expanded(child: _recommendationList()),
          ],
        ),
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Today', '${today.day}/${today.month}/${today.year}'),
            _row('Days in Month', '$daysInMonth'),
            _row('Days Passed', '$daysPassed'),
            _row('Days Remaining', '$daysRemaining'),
            const Divider(),
            _row('Monthly Budget',
                'PKR ${widget.monthlyBudget.toStringAsFixed(0)}'),
            _row('Projected Month Bill',
                'PKR ${projectedMonthlyBill.toStringAsFixed(0)}'),
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
    if (dailyUnits.isEmpty) {
      return const Center(child: Text('No data from Firebase'));
    }

    final devices = dailyUnits.keys.toList();
    final values =
        dailyUnits.values.map((e) => e * daysInMonth).toList();

    final maxY =
        (values.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

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
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY / 4,
                  getTitlesWidget: (v, _) => Text(
                    v.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    if (v.toInt() >= devices.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        devices[v.toInt()].toUpperCase(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
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
                    color: Colors.blue,
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
            title: Text(e.key.toUpperCase()),
            subtitle: Text(e.value),
            trailing: Text(
              'PKR ${(dailyUnits[e.key]! * daysInMonth * unitRate).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }
}
