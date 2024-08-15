import 'package:activetracker/pages/leaderboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class Pedometer extends StatefulWidget {
  @override
  _PedometerState createState() => _PedometerState();
}

class _PedometerState extends State<Pedometer> {
  int _stepCount = 0;
  bool _tracking = false;
  late StreamSubscription _accelerometerSubscription;
  late StreamSubscription _gyroscopeSubscription;
  CameraController? _cameraController;

  double _previousMagnitude = 0.0;
  bool _isStep = false;

  String? _capturedImagePath;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeNotifications();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController =
        CameraController(cameras.first, ResolutionPreset.medium);
    await _cameraController?.initialize();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _startTracking() async {
    _startTime = DateTime.now();

    final hasAccelerometer =
        await SensorManager().isSensorAvailable(Sensors.ACCELEROMETER);
    final hasGyroscope =
        await SensorManager().isSensorAvailable(Sensors.GYROSCOPE);

    if (hasAccelerometer) {
      final accelerometerStream = await SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        interval: Sensors.SENSOR_DELAY_NORMAL,
      );
      _accelerometerSubscription = accelerometerStream.listen((event) {
        _processAccelerometerData(event.data[0], event.data[1], event.data[2]);
      });
    }

    if (hasGyroscope) {
      final gyroscopeStream = await SensorManager().sensorUpdates(
        sensorId: Sensors.GYROSCOPE,
        interval: Sensors.SENSOR_DELAY_NORMAL,
      );
      _gyroscopeSubscription = gyroscopeStream.listen((event) {
        _processGyroscopeData(event.data[0], event.data[1], event.data[2]);
      });
    }

    setState(() {
      _tracking = true;
    });
  }

  void _stopTracking() async {
    _endTime = DateTime.now();

    // Save data to Firebase
    await _sendDataToFirebase();

    // Cancel sensor subscriptions
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();

    // Reset the step count
    setState(() {
      _stepCount = 0; // Reset the step count
      _tracking = false; // Update the tracking state
    });
  }

  void _processAccelerometerData(double x, double y, double z) {
    double magnitude = sqrt(x * x + y * y + z * z);
    double delta = magnitude - _previousMagnitude;

    if (delta > 2.0 && !_isStep) {
      setState(() {
        _stepCount++;
        _isStep = true;
      });

      if (_stepCount == 10) {
        _capturePhoto();
        _showStepCompletionNotification();
      }
    } else if (delta < 1.0) {
      _isStep = false;
    }

    _previousMagnitude = magnitude;
  }

  void _processGyroscopeData(double x, double y, double z) {
    print('Gyroscope - x: $x, y: $y, z: $z');
  }

  Future<void> _capturePhoto() async {
    try {
      final image = await _cameraController?.takePicture();
      if (image != null) {
        // Upload photo to Firebase Storage
        final file = File(image.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(file);

        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Save the download URL in the Firestore document
        setState(() {
          _capturedImagePath = downloadUrl;
        });

        print('Photo captured and uploaded: $downloadUrl');
      }
    } catch (e) {
      print("Error capturing or uploading photo: $e");
    }
  }

  Future<void> _showStepCompletionNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'step_channel_id',
      'step_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Congratulations!',
      'You have completed $_stepCount steps.',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> _sendDataToFirebase() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final user = FirebaseAuth.instance.currentUser;
    String timestampString =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    await firestore
        .collection('users') // Users collection
        .doc(user?.email) // Document corresponding to the user's email
        .collection('steps')
        .doc(timestampString) // New collection named as the timestamp
        .set({
      'stepCount': _stepCount,
      'startTime': _startTime?.toIso8601String(),
      'endTime': _endTime?.toIso8601String(),
      'photoUrl': _capturedImagePath, // Store the photo URL
      'timestamp': FieldValue.serverTimestamp(),
    });

    final DocumentReference globalStepsRef =
        firestore.collection('users').doc(user?.email);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(globalStepsRef);
      if (!snapshot.exists) {
        transaction.set(globalStepsRef, {'totalSteps': _stepCount});
      } else {
        int newTotalSteps = (snapshot['totalSteps'] ?? 0) + _stepCount;
        transaction.update(globalStepsRef, {'totalSteps': newTotalSteps});
      }
    });
  }

  void _showProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch the total steps from Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentSnapshot userDoc =
          await firestore.collection('users').doc(user.email).get();

      int totalSteps = userDoc['totalSteps'] ?? 0;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${user.displayName ?? 'N/A'}'),
                Text('Email: ${user.email ?? 'N/A'}'),
                Text('Total Steps: $totalSteps'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the profile dialog
                  _showLeaderboard(); // Open the leaderboard
                },
                child: Text('Leaderboard'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => LeaderboardScreen()),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pop(); // Go back to the login screen
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activity Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.person),
          onPressed: _showProfile,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Displaying the steps count in a card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps Today',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_stepCount',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Icon(
                          Icons.directions_walk,
                          size: 48,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Start/Stop tracking button
            ElevatedButton(
              onPressed: _tracking ? _stopTracking : _startTracking,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor: _tracking ? Colors.redAccent : Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _tracking ? 'Stop Tracking' : 'Start Tracking',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),

            // Display the captured image if available
            if (_capturedImagePath != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Captured Image:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _capturedImagePath!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
