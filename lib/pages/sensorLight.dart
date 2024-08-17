import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

class LightPage extends StatefulWidget {
  const LightPage({super.key});

  @override
  State<LightPage> createState() => _LightPageState();
}

class _LightPageState extends State<LightPage> {
  Timer? _timer;
  double _brightness = 0.5; // Default brightness

  @override
  void initState() {
    super.initState();
    _updateBrightness();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateBrightness();
    });
  }

  Future<void> _updateBrightness() async {
    final now = DateTime.now();
    double brightness;

    // Example logic for adjusting brightness based on the time of day
    if (now.hour >= 7 && now.hour < 19) {
      // Daytime: brighter screen
      brightness = 0.8;
    } else {
      // Nighttime: dimmer screen
      brightness = 0.3;
    }

    // Only update brightness if it hasn't been manually adjusted
    if (_brightness == 0.5) {
      setState(() {
        _brightness = brightness;
      });
      await ScreenBrightness().setScreenBrightness(_brightness);
    }
  }

  Future<void> _setBrightness(double brightness) async {
    setState(() {
      _brightness = brightness;
    });
    await ScreenBrightness().setScreenBrightness(_brightness);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automatic Brightness Adjustment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Current Brightness: ${(_brightness * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _brightness,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                _setBrightness(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
