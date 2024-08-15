import 'package:activetracker/pages/pedometer.dart';
import 'package:activetracker/pages/signup.dart';
import 'package:activetracker/services/authentication.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email TextField
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),

            // Password TextField
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              onPressed: () async {
                try {
                  // Sign in using AuthService
                  await AuthService.signIn(
                    _emailController.text,
                    _passwordController.text,
                  );

                  // If sign-in is successful, navigate to PedometerPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Pedometer()),
                  );
                } catch (e) {
                  // Show error message
                  _showErrorDialog(context, e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Login',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),

            // Sign Up Navigation Text
            TextButton(
              onPressed: () {
                // Navigate to the signup page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
              child: Text(
                'Don\'t have an account? Sign up',
                style: TextStyle(color: Colors.deepPurple, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
