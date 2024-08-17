import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricSensorPage extends StatefulWidget {
  @override
  _BiometricSensorPageState createState() => _BiometricSensorPageState();
}

class _BiometricSensorPageState extends State<BiometricSensorPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } catch (e) {
      canCheckBiometrics = false;
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint (or face) to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
        _authorized = authenticated ? 'Authorized' : 'Not Authorized';
      });
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error: $e';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _authorized = authenticated ? 'Authorized' : 'Not Authorized';
    });
  }

  void _cancelAuthentication() {
    _localAuth.stopAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biometric Authentication'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAuthenticating)
              ElevatedButton(
                onPressed: _cancelAuthentication,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel),
                    SizedBox(width: 10),
                    Text('Cancel Authentication'),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: _authenticate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fingerprint),
                    SizedBox(width: 10),
                    Text('Authenticate'),
                  ],
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Biometrics Available: $_canCheckBiometrics',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Authorization Status: $_authorized',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
