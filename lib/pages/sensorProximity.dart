import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'dart:async';
import 'package:proximity_sensor/proximity_sensor.dart';

////////////////////////////////////////////////////////////////////////////////
class ProximitySensorPage extends StatefulWidget {
  @override
  _ProximitySensorPageState createState() => _ProximitySensorPageState();
}

////////////////////////////////////////////////////////////////////////////////
class _ProximitySensorPageState extends State<ProximitySensorPage> {
  bool _isNear = false;
  late StreamSubscription<dynamic> _streamSubscription;

  @override
  void initState() {
    super.initState();
    listenSensor();
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
  }

  Future<void> listenSensor() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (foundation.kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // --------------------------------------------------------------------
    // You only need to make this call if you want to turn off the screen.
    await ProximitySensor.setProximityScreenOff(true)
        .onError((error, stackTrace) {
      print("could not enable screen off functionality");
      return null;
    });
    // --------------------------------------------------------------------

    _streamSubscription = ProximitySensor.events.listen((int event) {
      print(event);
      setState(() {
        _isNear = (event > 0) ? true : false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proximity Sensor Example'),
      ),
      body: Center(
        child: Text('proximity sensor, is near ?  $_isNear \n'),
      ),
    );
  }
}
