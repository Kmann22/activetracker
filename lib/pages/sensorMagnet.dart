import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MagnetometerPage extends StatefulWidget {
  const MagnetometerPage({super.key});

  @override
  State<MagnetometerPage> createState() => _MagnetometerPageState();
}

class _MagnetometerPageState extends State<MagnetometerPage> {
  static const Duration _ignoreDuration = Duration(milliseconds: 20);

  MagnetometerEvent? _magnetometerEvent;
  DateTime? _magnetometerUpdateTime;
  int? _magnetometerLastInterval;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Duration sensorInterval = SensorInterval.normalInterval;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magnetometer Example'),
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Magnetometer Sensor Data'),
              const SizedBox(height: 20),
              Text('X: ${_magnetometerEvent?.x.toStringAsFixed(1) ?? '?'}'),
              Text('Y: ${_magnetometerEvent?.y.toStringAsFixed(1) ?? '?'}'),
              Text('Z: ${_magnetometerEvent?.z.toStringAsFixed(1) ?? '?'}'),
              Text(
                'Interval: ${_magnetometerLastInterval?.toString() ?? '?'} ms',
              ),
              const SizedBox(height: 20),
              const Text('Update Interval:'),
              DropdownButton<Duration>(
                value: sensorInterval,
                items: [
                  DropdownMenuItem(
                    value: SensorInterval.gameInterval,
                    child: Text(
                        'Game (${SensorInterval.gameInterval.inMilliseconds}ms)'),
                  ),
                  DropdownMenuItem(
                    value: SensorInterval.uiInterval,
                    child: Text(
                        'UI (${SensorInterval.uiInterval.inMilliseconds}ms)'),
                  ),
                  DropdownMenuItem(
                    value: SensorInterval.normalInterval,
                    child: Text(
                        'Normal (${SensorInterval.normalInterval.inMilliseconds}ms)'),
                  ),
                  const DropdownMenuItem(
                    value: Duration(milliseconds: 500),
                    child: Text('500ms'),
                  ),
                  const DropdownMenuItem(
                    value: Duration(seconds: 1),
                    child: Text('1s'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      sensorInterval = value;
                      _updateMagnetometerStream();
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _updateMagnetometerStream();
  }

  void _updateMagnetometerStream() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }

    _streamSubscriptions.add(
      magnetometerEventStream(samplingPeriod: sensorInterval).listen(
        (MagnetometerEvent event) {
          final now = DateTime.now();
          setState(() {
            _magnetometerEvent = event;
            if (_magnetometerUpdateTime != null) {
              final interval = now.difference(_magnetometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _magnetometerLastInterval = interval.inMilliseconds;
              }
            }
          });
          _magnetometerUpdateTime = now;
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Sensor Not Found"),
                content: Text(
                  "It seems that your device doesn't support Magnetometer Sensor",
                ),
              );
            },
          );
        },
        cancelOnError: true,
      ),
    );
  }
}
