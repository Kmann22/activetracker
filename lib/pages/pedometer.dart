import 'package:activetracker/pages/leaderboard.dart';
import 'package:activetracker/pages/login.dart';
import 'package:activetracker/pages/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:camera/camera.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:path_provider/path_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class ActivityTracker extends StatefulWidget {
  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late Box activityBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
    _initializeCamera();
    _initializeNotifications();
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeHive() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
    activityBox = await Hive.openBox('activityData');
    _loadActivityDataFromLocalStorage();
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

  Future<void> _initializeFirebaseMessaging() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Message title: ${message.notification?.title}');
        print('Message body: ${message.notification?.body}');
      }
    });

    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
  }

  Future<void> _startTracking() async {
    setState(() {
      _tracking = true;
    });

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
  }

  void _stopTracking() async {
    _endTime = DateTime.now();
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    await _sendDataToFirebase();
    setState(() {
      _tracking = false;
      _stepCount = 0;
    });
    _clearLocalData();
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
        _sendNotification();
        // _saveActivityDataToLocalStorage();
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
        final file = File(image.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(file);

        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _capturedImagePath = downloadUrl;
        });

        print('Photo captured and uploaded: $downloadUrl');
      }
    } catch (e) {
      print("Error capturing or uploading photo: $e");
    }
  }

  Future<void> _sendNotification() async {
    try {
      RemoteMessage message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Congratulations!',
          body: 'You have completed $_stepCount steps.',
        ),
      );

      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.sendMessage();
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<void> _sendDataToFirebase() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    String timestampString =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    print("OK2");
    await firestore
        .collection('users')
        .doc(user?.email)
        .collection('steps')
        .doc(timestampString)
        .set({
      'stepCount': _stepCount,
      'startTime': _startTime?.toIso8601String(),
      'endTime': _endTime?.toIso8601String(),
      'photoUrl': _capturedImagePath,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("OK");
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
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Fetch user's total steps
      final DocumentSnapshot userDoc =
          await firestore.collection('users').doc(user.email).get();
      int totalSteps = userDoc['totalSteps'] ?? 0;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${user.displayName ?? 'N/A'}'),
                  Text('Email: ${user.email ?? 'N/A'}'),
                  Text('Total Steps: $totalSteps'),
                ],
              ),
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
                  Navigator.of(context).pop(); // Close the dialog
                  _showLeaderboard();
                },
                child: Text('View Leaderboard'),
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _saveActivityDataToLocalStorage() {
    activityBox.put('stepCount', _stepCount);
    activityBox.put('startTime', _startTime?.toIso8601String());
    activityBox.put('endTime', _endTime?.toIso8601String());
    activityBox.put('photoPath', _capturedImagePath);
  }

  void _loadActivityDataFromLocalStorage() {
    setState(() {
      _stepCount = activityBox.get('stepCount', defaultValue: 0);
      _startTime = DateTime.parse(activityBox.get('startTime',
          defaultValue: DateTime.now().toIso8601String()));
      _endTime = DateTime.parse(activityBox.get('endTime',
          defaultValue: DateTime.now().toIso8601String()));
      _capturedImagePath = activityBox.get('photoPath');
    });
  }

  void _clearLocalData() {
    activityBox.clear();
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    _cameraController?.dispose();
    activityBox.close();
    super.dispose();
  }

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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => HardwareFeaturesMenu()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Hardware Features',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
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
