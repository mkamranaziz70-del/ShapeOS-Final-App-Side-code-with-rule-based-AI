// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/device_model.dart';

class VoiceTab extends StatefulWidget {
  final List<DeviceModel> appliances;
  final void Function(DeviceModel device) onToggle;

  const VoiceTab({super.key, required this.appliances, required this.onToggle});

  @override
  State<VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<VoiceTab> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = "";

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'voice_control_channel',
          'Voice Control',
          channelDescription: 'Notifications for Voice Control actions',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
    );
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() => _lastWords = val.recognizedWords);
          _parseCommand(_lastWords);
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _parseCommand(String command) {
    command = command.toLowerCase();
    bool turnOn = command.contains("on");
    bool turnOff = command.contains("off");

    for (var device in widget.appliances) {
      if (command.contains(device.name.toLowerCase())) {
        bool newState = turnOn
            ? true
            : turnOff
            ? false
            : device.isOn;
        if (newState != device.isOn) {
          widget.onToggle(device); // ✅ Toggle device state
          _showNotification(
            "Device ${newState ? 'ON' : 'OFF'}",
            "${device.name} turned ${newState ? 'ON' : 'OFF'} via voice command",
          );
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _lastWords.isEmpty ? "Say a command" : _lastWords,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FloatingActionButton(
            onPressed: _isListening ? _stopListening : _startListening,
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
        ],
      ),
    );
  }
}
