import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:optimize_battery/optimize_battery.dart';

class BatteryPage extends StatefulWidget {
  const BatteryPage({Key? key}) : super(key: key);

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  final Battery _battery = Battery();
  BatteryState? _batteryState;
  int? _batteryLevel;
  String _isBatteryIgnoredText = 'Unknown';

  @override
  void initState() {
    super.initState();
    _updateBatteryInfo();
    _checkBatteryOptimization();

    _battery.onBatteryStateChanged.listen((BatteryState state) {
      setState(() {
        _batteryState = state;
      });
    });
  }

  Future<void> _updateBatteryInfo() async {
    final int level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });
  }

  Future<void> _checkBatteryOptimization() async {
    final bool isIgnored =
        await OptimizeBattery.isIgnoringBatteryOptimizations();
    setState(() {
      _isBatteryIgnoredText = isIgnored ? "Ignored" : "Not Ignored";
    });
  }

  Future<void> _openOptimizationSettings() async {
    await OptimizeBattery.openBatteryOptimizationSettings();
  }

  Future<void> _stopOptimizingBatteryUsage() async {
    await OptimizeBattery.stopOptimizingBatteryUsage();
    setState(() {
      _isBatteryIgnoredText = "Unknown";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Battery and Optimization Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Battery Level: ${_batteryLevel ?? 'Unknown'}%'),
              Text('Battery State: ${_batteryState ?? 'Unknown'}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateBatteryInfo,
                child: const Text('Refresh Battery Info'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _checkBatteryOptimization();
                },
                child: const Text('Check if Battery Optimization is Enabled'),
              ),
              Text('Battery Optimization is $_isBatteryIgnoredText'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openOptimizationSettings,
                child: const Text('Open Battery Optimization Settings'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _stopOptimizingBatteryUsage,
                child: const Text('Attempt to Stop Optimizing Battery Usage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
