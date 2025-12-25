import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class SecurityTab extends StatefulWidget {
  const SecurityTab({super.key});

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab>
    with AutomaticKeepAliveClientMixin {
  // ignore: unused_field
  static const Color primaryBlue = Color(0xFF154F73);

  late final DatabaseReference alertsRef;
  late final Query historyQuery;

  late final Stream<DatabaseEvent> alertsStream;
  late final Stream<DatabaseEvent> historyStream;

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();

  final Set<String> _spokenAlerts = {}; // prevent repeat alerts

  @override
  void initState() {
    super.initState();

    alertsRef = FirebaseDatabase.instance.ref("alerts");
    historyQuery =
        FirebaseDatabase.instance.ref("alerts_history").limitToLast(50);

    alertsStream = alertsRef.onValue;
    historyStream = historyQuery.onValue;

    // 🔊 MAX PERCEIVED LOUDNESS SETTINGS
    _tts.setLanguage("en-US");
    _tts.setVolume(1.0);          // max allowed
    _tts.setPitch(1.35);          // higher pitch = more noticeable
    _tts.setSpeechRate(0.38);     // slower = sounds louder
    _tts.awaitSpeakCompletion(true);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const _SectionTitle("Current Alerts"),
        _CurrentAlertsGrid(
          stream: alertsStream,
          onAlert: _handleAlert,
          spokenCache: _spokenAlerts,
        ),
        const SizedBox(height: 28),
        const _SectionTitle("Alert History"),
        _AlertHistory(stream: historyStream),
      ],
    );
  }

  /// 🚨 SOUND + VOICE + VIBRATION (EMERGENCY GRADE)
  Future<void> _handleAlert(String type) async {
    // 🔔 Play loud alert sound first
    await _player.play(
      AssetSource("sounds/alert.wav"),
      volume: 1.0,
    );

    // 📳 Strong vibration
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 1200);
    }

    // 🗣️ Emergency voice message
    switch (type) {
      case "flame":
        await _tts.speak(
          "Emergency! Fire detected. Please take action immediately.",
        );
        break;
      case "smoke":
        await _tts.speak(
          "Warning! Smoke detected.",
        );
        break;
      case "motion":
        await _tts.speak(
          "Alert! Motion detected.",
        );
        break;
    }
  }
}

////////////////////////////////////////////////////////////
/// CURRENT ALERTS GRID
////////////////////////////////////////////////////////////

class _CurrentAlertsGrid extends StatelessWidget {
  final Stream<DatabaseEvent> stream;
  final Function(String type) onAlert;
  final Set<String> spokenCache;

  const _CurrentAlertsGrid({
    required this.stream,
    required this.onAlert,
    required this.spokenCache,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final raw = snapshot.data!.snapshot.value;
        if (raw == null) {
          return const _EmptyText("No active alerts");
        }
final data = Map<String, dynamic>.from(raw as Map);

// only ACTIVE alerts
final items = data.entries
    .where((e) => e.value == true)
    .toList();

if (items.isEmpty) {
  return const _EmptyText("No active alerts");
}


        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
   itemBuilder: (context, index) {
  final type = items[index].key.toLowerCase();

  // 🔊 Speak ONLY when alert becomes active
  if (!spokenCache.contains(type)) {
    spokenCache.add(type);
    onAlert(type);
  }

  return _AlertSquareCard(
    title: items[index].key,
  );
},

        );
      },
    );
  }
}

////////////////////////////////////////////////////////////
/// ALERT CARD (SEVERITY COLORS)
////////////////////////////////////////////////////////////

class _AlertSquareCard extends StatelessWidget {
  final String title;

  const _AlertSquareCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final severity = _severity(title);

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: severity.bg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(severity.icon, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  _Severity _severity(String text) {
    final t = text.toLowerCase();
    if (t.contains("flame")) {
      return _Severity(Icons.local_fire_department, Colors.red.shade700);
    }
    if (t.contains("smoke")) {
      return _Severity(Icons.smoke_free, Colors.red.shade600);
    }
    if (t.contains("motion")) {
      return _Severity(Icons.directions_run, Colors.orange.shade700);
    }
    return _Severity(Icons.warning, Colors.grey);
  }
}

class _Severity {
  final IconData icon;
  final Color bg;
  _Severity(this.icon, this.bg);
}

////////////////////////////////////////////////////////////
/// ALERT HISTORY
////////////////////////////////////////////////////////////

class _AlertHistory extends StatelessWidget {
  final Stream<DatabaseEvent> stream;
  const _AlertHistory({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final raw = snapshot.data!.snapshot.value;
        if (raw == null) return const _EmptyText("No history");

        final data = Map<String, dynamic>.from(raw as Map);
        final entries = data.entries.toList().reversed.toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final e = Map<String, dynamic>.from(entries[index].value);
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(e['event'] ?? ''),
              subtitle: Text(e['time'] ?? ''),
            );
          },
        );
      },
    );
  }
}

////////////////////////////////////////////////////////////
/// SECTION TITLE / EMPTY
////////////////////////////////////////////////////////////

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}
