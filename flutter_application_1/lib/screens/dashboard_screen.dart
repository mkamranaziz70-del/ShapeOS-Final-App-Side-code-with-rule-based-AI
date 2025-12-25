// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../models/device_model.dart';
import '../widgets/overview_tab.dart';
import '../widgets/control_tab.dart';
import '../widgets/energy_tab.dart';
import '../widgets/security_tab.dart';
import '../widgets/logs_tab.dart';
import '../widgets/voice_tab.dart';
import '../widgets/ai_monitor_tab.dart';

import '../services/device_monitor_service.dart';
import '../services/voice_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref("appliances");

  List<DeviceModel> appliancesList = [];

  final List<String> _titles = [
    "Home",
    "Control",
    "AI Monitor",
    "Energy Analytics",
    "Security",
    "Logs",
    "Voice Control",
  ];

  @override
  void initState() {
    super.initState();
    _listenToRealtimeDB();
    _ensureTodayEnergyDoc();
    _startGlobalMonitoring();
  }

  // ───────────────── ENERGY DOC INIT ─────────────────

  Future<void> _ensureTodayEnergyDoc() async {
    try {
      final now = DateTime.now();
      final dateId =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final ref = FirebaseFirestore.instance
          .collection("energy_daily")
          .doc(dateId);

      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          "date": dateId,
          "day": _dayName(now.weekday),
          "hourlyUsage": {},
          "devices": {},
          "totalEnergy": 0.0,
          "suggestions": ["Energy data collection started"],
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Energy init failed: $e");
    }
  }

  String _dayName(int d) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];
    return days[d - 1];
  }

  // ───────────────── GLOBAL AI MONITOR ─────────────────

  void _startGlobalMonitoring() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));

      if (!mounted) return false;

      for (final d in appliancesList) {
        final result = DeviceMonitorService.check(d.id);

        if (result.hasAlert) {
          VoiceService.speak(result.message);
          _showMonitorPopup(d, result.message);

          if (result.autoOff) {
            _toggleDevice(d, source: "AI Monitor");
          }
        }
      }
      return mounted;
    });
  }

  void _showMonitorPopup(DeviceModel d, String msg) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return AlertDialog(
          title: const Text("Device Alert"),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ignore"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleDevice(d, source: "AI Monitor");
              },
              child: const Text("Turn OFF"),
            ),
          ],
        );
      },
    );
  }

  // ───────────────── RTDB LISTENER ─────────────────

  void _listenToRealtimeDB() {
    _dbRef.onValue.listen((event) {
      final snapshot = event.snapshot.value;
      final List<DeviceModel> updated = [];

      if (snapshot is List) {
        for (int i = 0; i < snapshot.length; i++) {
          final value = snapshot[i];
          if (value is! Map) continue;

          final map = Map<dynamic, dynamic>.from(value);
          final name = map['name'];
          final type = map['type'];

          if (name == null || type == null) continue;

          updated.add(DeviceModel(
            id: i.toString(),
            name: name,
            type: type,
            isOn: map['isOn'] == true,
            power: (map['power'] ?? 0).toDouble(),
            voltage: (map['voltage'] ?? 0).toDouble(),
            current: (map['current'] ?? 0).toDouble(),
            energy: (map['energy'] ?? 0).toDouble(),
            currentLeakage:
                (map['currentLeakage'] ?? 0).toDouble(),
            voltageLeakage:
                (map['voltageLeakage'] ?? 0).toDouble(),
          ));
        }
      }

      if (!mounted) return;
      setState(() => appliancesList = updated);
    });
  }

  // ───────────────── DEVICE TOGGLE ─────────────────

  Future<void> _toggleDevice(
    DeviceModel device, {
    required String source,
  }) async {
    final newState = !device.isOn;

    await _dbRef.child(device.id).update({
      'isOn': newState,
    });

    FirebaseDatabase.instance.ref("logs").push().set({
      "event":
          "${device.name} turned ${newState ? "ON" : "OFF"} via $source",
      "time": DateTime.now().toString(),
    });
  }

  // ───────────────── SIGN OUT ─────────────────

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sign Out"),
        content:
            const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.go('/login');
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    final tabs = [
      OverviewTab(
        appliances: appliancesList,
        onDeviceTap: (d) =>
            context.push('/dashboard/device-detail', extra: d),
      ),
      ControlTab(
        appliances: appliancesList,
        onToggle: (d) => _toggleDevice(d, source: "App"),
      ),
      AIMonitorTab(appliances: appliancesList),
      const EnergyTab(), // ✅ CORRECT
      SecurityTab(),
      const LogsTab(),
      VoiceTab(
        appliances: appliancesList,
        onToggle: (d) => _toggleDevice(d, source: "Voice"),
      ),
    ];

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
   appBar: PreferredSize(
  preferredSize: const Size.fromHeight(64),
  child: AppBar(
    elevation: 0,
    backgroundColor: const Color(0xFF154F73),
    centerTitle: false,
    titleSpacing: 20,
    automaticallyImplyLeading: false,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "Smart Home Dashboard",
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: IconButton(
          tooltip: "Logout",
          icon: const Icon(Icons.logout_rounded),
          color: Colors.white,
          onPressed: _signOut,
        ),
      ),
    ],
  ),
),

        body: tabs[_currentIndex],
        bottomNavigationBar: TelenorBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// 🔥 TELENOR STYLE CUSTOM BOTTOM NAV BAR
////////////////////////////////////////////////////////////////

class TelenorBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  static const Color primaryBlue = Color(0xFF154F73);

  const TelenorBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
@override
Widget build(BuildContext context) {
  return SafeArea(
    top: false,
    child: SizedBox(
      height: 78,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(icon: Icons.home_rounded, label: "Home", index: 0),
            _navItem(icon: Icons.settings_rounded, label: "Control", index: 1),
            _navItem(icon: Icons.psychology_rounded, label: "AI", index: 2),
            _navItem(icon: Icons.show_chart_rounded, label: "Energy", index: 3),
            _navItem(icon: Icons.security_rounded, label: "Security", index: 4),
            _navItem(icon: Icons.history_rounded, label: "Logs", index: 5),
            _navItem(icon: Icons.mic_rounded, label: "Voice", index: 6),
          ],
        ),
      ),
    ),
  );
}


  // 🔹 PROFESSIONAL NAV ITEM
  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool active = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: active ? 24 : 22,
              color: active
                  ? primaryBlue
                  : Colors.grey.withOpacity(0.55),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 0.2,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? primaryBlue
                    : Colors.grey.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

