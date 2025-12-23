import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  DateTime parseTimestamp(String ts) {
    // Format: "2025-9-12 11:9:9"
    try {
      final parts = ts.split(' ');
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (e) {
      return DateTime(1970); // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref().child("logs");

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final dataSnapshot = snapshot.data!.snapshot;
        if (dataSnapshot.value == null) {
          return const Center(child: Text("No logs available"));
        }

        final rawData = dataSnapshot.value as Map<dynamic, dynamic>;

        final logs = rawData.entries.map((entry) {
          final val = entry.value;
          if (val is Map) {
            final mapVal = Map<String, dynamic>.from(val);
            return {
              "time": mapVal["time"] ?? "",
              "event": mapVal["event"] ?? "",
              "dateTime": parseTimestamp(mapVal["time"] ?? ""),
            };
          } else {
            return {
              "time": "",
              "event": val.toString(),
              "dateTime": DateTime(1970),
            };
          }
        }).toList();

        // Sort by DateTime descending (latest first)
        logs.sort((a, b) => b["dateTime"].compareTo(a["dateTime"]));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: Text(log["event"]!),
                subtitle: Text(log["time"]!),
              ),
            );
          },
        );
      },
    );
  }
}
