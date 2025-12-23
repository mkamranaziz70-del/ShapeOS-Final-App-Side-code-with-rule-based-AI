import 'dart:async';
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
  final DatabaseReference _recommendationsRef =
      FirebaseDatabase.instance.ref('ai/ml_recommendation');

  late final StreamSubscription _appliancesSub;
  late final StreamSubscription _recommendationsSub;

  List<DeviceModel> appliancesList = [];
  Map<String, Map<String, dynamic>> firebaseRecommendations = {};
  final List<String> targetDevices = ['bulb', 'bell', 'pump', 'fan'];

  @override
  void initState() {
    super.initState();
    _listenToDevices();
    _listenToRecommendations();
  }

  void _listenToDevices() {
    _appliancesSub = _appliancesRef.onValue.listen((event) {
      if (!mounted) return;
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;

      final List<DeviceModel> list = [];

      raw.forEach((key, value) {
        if (value is! Map) return;
        final device = key.toString().toLowerCase();
        if (!targetDevices.contains(device)) return;

        list.add(
          DeviceModel(
            id: device,
            name: device,
            type: device,
            isOn: false,
            power: (value['power'] as num?)?.toDouble() ?? 0,
            voltage: (value['voltage'] as num?)?.toDouble() ?? 0,
            current: (value['current'] as num?)?.toDouble() ?? 0,
            currentLeakage: 0,
            voltageLeakage: 0,
            energy: 0,
            powerHistory: _toList(value['power_history']),
            voltageHistory: _toList(value['voltage_history']),
            currentHistory: _toList(value['current_history']),
          ),
        );
      });

      setState(() => appliancesList = list);
    });
  }

  List<double> _toList(dynamic raw) {
    if (raw == null) return <double>[];
    if (raw is List) {
      return raw
          .map<double>((e) =>
              e is num ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
          .toList();
    }
    if (raw is Map) {
      final keys = raw.keys.map((e) => e.toString()).toList()..sort();
      return keys
          .map<double>((k) =>
              raw[k] is num ? raw[k].toDouble() : double.tryParse(raw[k].toString()) ?? 0)
          .toList();
    }
    return <double>[];
  }

  void _listenToRecommendations() {
    _recommendationsSub = _recommendationsRef.onValue.listen((event) {
      if (!mounted) return;
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;

      final Map<String, Map<String, dynamic>> recs = {};
      raw.forEach((k, v) {
        if (v is Map && targetDevices.contains(k.toLowerCase())) {
          recs[k.toString()] = Map<String, dynamic>.from(v);
        }
      });

      setState(() => firebaseRecommendations = recs);
    });
  }

  void _toggleDevice(DeviceModel device) {}

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    GoRouter.of(context).go('/login');
  }

  Future<void> _showBudgetInputDialog() async {
    final TextEditingController controller = TextEditingController();
    double? monthlyBudget;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g. 1000',
            prefixText: 'PKR ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                monthlyBudget = value;
                Navigator.pop(ctx);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (monthlyBudget != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BudgetAnalysisScreen(monthlyBudget: monthlyBudget!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _appliancesSub.cancel();
    _recommendationsSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Overview',
      'Control',
      'Energy Analytics',
      'Security',
      'Logs',
      'Voice Control',
      'AI Recommendations',
      'Budget',
      'Sign Out',
    ];

    final tabs = [
      OverviewTab(
        appliances: appliancesList,
        onDeviceTap: (device) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceDetailScreen(device: device),
            ),
          );
        },
      ),
      ControlTab(appliances: appliancesList, onToggle: _toggleDevice),
      EnergyTab(appliancesList: appliancesList),
      SecurityTab(appliances: appliancesList), // ✅ fixed
      const LogsTab(),
      VoiceTab(appliances: appliancesList, onToggle: _toggleDevice),
      _buildRecommendationTab(),
      Center(
        child: ElevatedButton(
          onPressed: _showBudgetInputDialog,
          child: const Text('Enter Monthly Budget'),
        ),
      ),
      const SizedBox.shrink(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF8DBCC7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0ABAB5),
        title: Text(titles[_currentIndex]),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0ABAB5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.home, size: 36, color: Color(0xFF0ABAB5)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Smart Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < titles.length; i++)
              ListTile(
                leading: _getDrawerIcon(i),
                title: Text(titles[i]),
                selected: i == _currentIndex,
                selectedTileColor: const Color(0xFFE3F2FD),
                onTap: () {
                  Navigator.pop(context);
                  if (i == titles.length - 1) {
                    _signOut();
                  } else {
                    setState(() => _currentIndex = i);
                  }
                },
              ),
          ],
        ),
      ),
      body: tabs[_currentIndex],
    );
  }

  Icon _getDrawerIcon(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.dashboard);
      case 1:
        return const Icon(Icons.settings);
      case 2:
        return const Icon(Icons.show_chart);
      case 3:
        return const Icon(Icons.security);
      case 4:
        return const Icon(Icons.history);
      case 5:
        return const Icon(Icons.mic);
      case 6:
        return const Icon(Icons.lightbulb);
      case 7:
        return const Icon(Icons.attach_money);
      case 8:
        return const Icon(Icons.logout);
      default:
        return const Icon(Icons.device_unknown);
    }
  }

  Widget _buildRecommendationTab() {
    if (firebaseRecommendations.isEmpty) {
      return const Center(
        child: Text(
          'No AI recommendations available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: firebaseRecommendations.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.0,
        ),
        itemBuilder: (context, index) {
          final device = firebaseRecommendations.keys.elementAt(index);
          final data = firebaseRecommendations[device]!;
          final confidence = ((data['confidence'] ?? 0) as num).toDouble();

          Color statusColor = Colors.grey;
          if (data['status'] == 'high_usage') statusColor = Colors.red;
          if (data['status'] == 'normal_usage') statusColor = Colors.green;
          if (data['status'] == 'low_usage') statusColor = Colors.orange;

          IconData deviceIcon = Icons.device_unknown;
          switch (device.toLowerCase()) {
            case 'bulb':
              deviceIcon = Icons.lightbulb;
              break;
            case 'fan':
              deviceIcon = Icons.toys;
              break;
            case 'pump':
              deviceIcon = Icons.water;
              break;
            case 'bell':
              deviceIcon = Icons.notifications;
              break;
          }

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(deviceIcon, size: 24, color: statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          device.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Power: ${data['power']} W',
                      style: const TextStyle(fontSize: 12)),
                  Text('Status: ${data['status']}',
                      style: const TextStyle(fontSize: 12)),
                  Text('Recommendation: ${data['recommendation']}',
                      style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: confidence,
                        color: statusColor,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
