import 'package:activetracker/pages/login.dart';
import 'package:activetracker/pages/pedometer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core package
import 'package:activetracker/pages/login.dart';
import 'package:activetracker/pages/pedometer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
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
            return Pedometer(); // User is signed in
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
