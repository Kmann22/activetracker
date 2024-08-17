import 'package:activetracker/consts.dart';
import 'package:activetracker/pages/login.dart';
import 'package:activetracker/pages/pedometer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core package
import 'package:activetracker/pages/login.dart';
import 'package:activetracker/pages/pedometer.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('activityData'); // Open Hive box for activity data
  await Firebase.initializeApp(); // Initialize Firebase
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print(fcmToken);

  await _setupStripe();

  runApp(MyApp());
}

Future<void> _setupStripe() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = stripePublishableKey;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Active Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthCheck(), // Use AuthCheck to determine initial page
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return ActivityTracker(); // User is signed in
          } else {
            return LoginPage(); // User is not signed in
          }
        }
        return Center(
            child: CircularProgressIndicator()); // Waiting for connection state
      },
    );
  }
}
