import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_model.dart';
import 'package:fl_chart/fl_chart.dart';

class OverviewTab extends StatefulWidget {
  final List<DeviceModel> appliances;
  final Function(DeviceModel device) onDeviceTap;

  const OverviewTab({
    super.key,
    required this.appliances,
    required this.onDeviceTap,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final db = FirebaseDatabase.instance.ref('appliances');
  final int maxPoints = 50;

  final Map<String, List<double>> v = {};
  final Map<String, List<double>> c = {};
  final Map<String, List<double>> p = {};

  @override
  void initState() {
    super.initState();
    for (final d in widget.appliances) {
      v[d.type] = [];
      c[d.type] = [];
      p[d.type] = [];
      _listen(d.type);
    }
  }

  void _listen(String type) {
    db.child(type).onValue.listen((e) {
      if (e.snapshot.value is! Map) return;
      final m = Map<String, dynamic>.from(e.snapshot.value as Map);

      setState(() {
        v[type]!.add((m['voltage'] ?? 0).toDouble());
        c[type]!.add((m['current'] ?? 0).toDouble());
        p[type]!.add((m['power'] ?? 0).toDouble());

        if (v[type]!.length > maxPoints) v[type]!.removeAt(0);
        if (c[type]!.length > maxPoints) c[type]!.removeAt(0);
        if (p[type]!.length > maxPoints) p[type]!.removeAt(0);
      });
    });
  }

  Widget chart(List<double> d, Color color) {
    if (d.isEmpty) return const SizedBox(height: 60);
    return SizedBox(
      height: 60,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(d.length, (i) => FlSpot(i.toDouble(), d[i])),
              isCurved: true,
              color: color,
              dotData: FlDotData(show: false),
            )
          ],
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: widget.appliances.map((d) {
        return GestureDetector(
          onTap: () => widget.onDeviceTap(d),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  chart(v[d.type] ?? [], Colors.orange),
                  chart(c[d.type] ?? [], Colors.green),
                  chart(p[d.type] ?? [], Colors.blue),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
