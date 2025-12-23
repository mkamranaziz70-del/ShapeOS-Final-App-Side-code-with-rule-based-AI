import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/device_model.dart';

class ControlTab extends StatefulWidget {
  final List<DeviceModel> appliances;
  final void Function(DeviceModel device) onToggle;

  const ControlTab({
    super.key,
    required this.appliances,
    required this.onToggle,
  });

  @override
  State<ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends State<ControlTab> {
  late Map<String, bool> _states;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _buildStatesFromWidget();
    _speech = stt.SpeechToText();
  }

  @override
  void didUpdateWidget(covariant ControlTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildStatesFromWidget();
  }

  void _buildStatesFromWidget() {
    _states = {for (var d in widget.appliances) d.id: d.isOn};
  }

  void _onSwitchToggle(DeviceModel device, bool val) {
    setState(() => _states[device.id] = val);
    widget.onToggle(device);
  }

  void _startListening(DeviceModel device) async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          String command = val.recognizedWords.toLowerCase();
          _handleVoiceCommand(command, device);
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _handleVoiceCommand(String command, DeviceModel device) {
    final name = device.name.toLowerCase();
    if (command.contains(name)) {
      if (command.contains("on") && !device.isOn)
        widget.onToggle(device);
      else if (command.contains("off") && device.isOn)
        widget.onToggle(device);
    }
    _stopListening();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appliances.isEmpty) {
      return const Center(
        child: Text(
          "✨ No appliances found ✨",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFFDE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.appliances.length,
        itemBuilder: (context, index) {
          final device = widget.appliances[index];
          final bool value = _states[device.id] ?? device.isOn;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: value
                    ? [
                        Colors.yellow.shade200.withOpacity(0.5),
                        Colors.yellow.shade100.withOpacity(0.3),
                      ]
                    : [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.02),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
              border: Border.all(
                color: value ? Colors.black : Colors.black54,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  leading: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: value ? 1.2 : 1.0,
                    child: Icon(
                      _getIcon(device.type),
                      size: 40,
                      color: value ? Colors.black : Colors.grey.shade700,
                    ),
                  ),
                  title: Text(
                    device.name.isNotEmpty ? device.name : "Unnamed",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    device.type.isNotEmpty ? device.type : "Unknown type",
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Switch(
                          value: value,
                          activeColor: Colors.black,
                          activeTrackColor: Colors.yellow.shade300,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                          onChanged: (val) => _onSwitchToggle(device, val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                        color: Colors.black87,
                        onPressed: () => _startListening(device),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case "fan":
        return Icons.toys;
      case "bulb":
        return Icons.lightbulb_outline;
      case "pump":
        return Icons.water_drop;
      case "bell":
        return Icons.notifications_active;
      case "door":
        return Icons.sensor_door;
      case "window":
        return Icons.window;
      default:
        return Icons.devices_other;
    }
  }
}
