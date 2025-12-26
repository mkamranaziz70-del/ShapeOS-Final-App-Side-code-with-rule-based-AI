import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';

import '../models/device_model.dart';
import '../widgets/overview_tab.dart';
import '../widgets/control_tab.dart';
import '../widgets/energy_tab.dart';
import '../widgets/security_tab.dart';
import '../widgets/logs_tab.dart';
import '../widgets/voice_tab.dart';
import '../widgets/ai_monitor_tab.dart'; // ✅ RESTORED
import '../screens/budget_analysis_screen.dart';
import '../screens/device_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final DatabaseReference _appliancesRef =
      FirebaseDatabase.instance.ref('appliances_by_type');
  final DatabaseReference _aiRef =
      FirebaseDatabase.instance.ref('ai/ml_recommendation');

  late StreamSubscription _applianceSub;
  late StreamSubscription _aiSub;

  List<DeviceModel> appliances = [];
  Map<String, Map<String, dynamic>> aiData = {};

  final List<String> targetDevices = ['bulb', 'fan', 'pump', 'bell'];

  @override
  void initState() {
    super.initState();
    _listenAppliances();
    _listenAI();
  }

  void _listenAppliances() {
    _applianceSub = _appliancesRef.onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;

      final List<DeviceModel> list = [];

      raw.forEach((k, v) {
        if (v is! Map) return;
        final id = k.toString().toLowerCase();
        if (!targetDevices.contains(id)) return;

        list.add(DeviceModel(
          id: id,
          name: id.toUpperCase(),
          type: id,
          isOn: v['isOn'] == true,
          power: _toDouble(v['power']),
          voltage: _toDouble(v['voltage']),
          current: _toDouble(v['current']),
          currentLeakage: 0,
          voltageLeakage: 0,
          energy: _toDouble(v['energy']),
          powerHistory: _toList(v['power_history']),
          voltageHistory: _toList(v['voltage_history']),
          currentHistory: _toList(v['current_history']),
        ));
      });

      if (mounted) setState(() => appliances = list);
    });
  }

  void _listenAI() {
    _aiSub = _aiRef.onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;

      final Map<String, Map<String, dynamic>> parsed = {};
      raw.forEach((k, v) {
        if (v is Map) {
          parsed[k.toString()] = Map<String, dynamic>.from(v);
        }
      });

      if (mounted) setState(() => aiData = parsed);
    });
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  List<double> _toList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => _toDouble(e)).toList();
    }
    if (raw is Map) {
      final keys = raw.keys.toList()..sort();
      return keys.map((k) => _toDouble(raw[k])).toList();
    }
    return [];
  }

  Future<void> _openBudget() async {
    final controller = TextEditingController();
    double? budget;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: 'PKR '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              budget = double.tryParse(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (budget != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BudgetAnalysisScreen(monthlyBudget: budget!),
        ),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) GoRouter.of(context).go('/login');
  }

  @override
  void dispose() {
    _applianceSub.cancel();
    _aiSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      OverviewTab(
        appliances: appliances,
        onDeviceTap: (d) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: d)),
        ),
      ),
      ControlTab(appliances: appliances, onToggle: (_) {}),
      const EnergyTab(),
      const SecurityTab(),
      const LogsTab(),
      VoiceTab(appliances: appliances, onToggle: (_) {}),
      _aiTab(), // ML AI (unchanged)
      AIMonitorTab(appliances: appliances), // ✅ REAL RULE-BASED AI RESTORED
      Center(child: ElevatedButton(onPressed: _openBudget, child: const Text('Enter Monthly Budget'))),
      const SizedBox.shrink(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 9) {
            _logout();
          } else {
            setState(() => _currentIndex = i);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.toggle_on), label: 'Control'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Energy'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Security'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'AI Monitor'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Budget'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }

  Widget _aiTab() {
    if (aiData.isEmpty) {
      return const Center(child: Text('No AI recommendations'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: aiData.entries.map((e) {
        final d = e.value;
        final double confidence = _toDouble(d['confidence']).clamp(0.0, 1.0);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CustomPaint(
                  size: const Size(60, 60),
                  painter: _CirclePainter(confidence),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Power: ${d['power']} W'),
                      Text('Status: ${d['status']}'),
                      Text(d['recommendation'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double value;
  _CirclePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final fg = Paint()
      ..color = Colors.blue
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * value,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
