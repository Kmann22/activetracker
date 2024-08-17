import 'package:activetracker/pages/payment.dart';
import 'package:activetracker/pages/sensorBattery.dart';
import 'package:activetracker/pages/sensorBiometric.dart';
import 'package:activetracker/pages/sensorBluetooth.dart';
import 'package:activetracker/pages/sensorLight.dart';
import 'package:activetracker/pages/sensorMagnet.dart';
import 'package:activetracker/pages/sensorMic.dart';
import 'package:activetracker/pages/sensorProximity.dart';
import 'package:flutter/material.dart';
import 'package:activetracker/pages/sensorCameraMic.dart';
// Import other pages as needed

// Page for displaying the hardware features menu
class HardwareFeaturesMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hardware Features Menu'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildFeatureButton(
                context, 'Microphone', () => _onMicroPressed(context)),
            _buildFeatureButton(
                context, 'Magnetometer', () => _onMagnetometerPressed(context)),
            _buildFeatureButton(context, 'Proximity Sensor',
                () => _onProximitySensorPressed(context)),
            _buildFeatureButton(
                context, 'Light Sensor', () => _onLightSensorPressed(context)),
            _buildFeatureButton(
                context, 'Camera', () => _onCameraMicrophonePressed(context)),
            _buildFeatureButton(context, 'GPS', _onGPSPressed),
            _buildFeatureButton(context, 'Bluetooth/NFC',
                () => _onBluetoothNFCPressed(context)),
            _buildFeatureButton(context, 'Battery and Power Management',
                () => _onBatteryPowerManagementPressed(context)),
            _buildFeatureButton(context, 'Biometric Sensors',
                () => _onBiometricSensorsPressed(context)),
            _buildFeatureButton(
                context, 'Payment', () => _onPaymentPressed(context)),
          ],
        ),
      ),
    );
  }

  // Function to build each feature button
  Widget _buildFeatureButton(
      BuildContext context, String featureName, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
        child: Text(
          featureName,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  // Function to handle Accelerometer
  void _onMicroPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AudioRecorderPage()),
    );
  }

  // Function to handle Magnetometer
  void _onMagnetometerPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MagnetometerPage()),
    );
  }

  // Function to handle Proximity Sensor
  void _onProximitySensorPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProximitySensorPage()),
    );
  }

  // Function to handle Light Sensor
  void _onLightSensorPressed(BuildContext context) {
    print('Light Sensor feature selected.');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LightPage()),
    );
  }

  // Function to handle Camera and Microphone
  void _onCameraMicrophonePressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraMicPage()),
    );
  }

  // Function to handle GPS
  void _onGPSPressed() {
    print('GPS feature selected.');
    // Implement navigation to GPS page if available
  }

  // Function to handle Bluetooth/NFC
  void _onBluetoothNFCPressed(BuildContext context) {
    print('Bluetooth/NFC feature selected.');
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => BluetoothPage()),
    // );
  }

  // Function to handle Battery and Power Management
  void _onBatteryPowerManagementPressed(BuildContext context) {
    print('Battery and Power Management feature selected.');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BatteryPage()),
    );
  }

  void _onPaymentPressed(BuildContext context) {
    print('Battery and Power Management feature selected.');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen()),
    );
  }

  // Function to handle Biometric Sensors
  void _onBiometricSensorsPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BiometricSensorPage()),
    );
  }
}
