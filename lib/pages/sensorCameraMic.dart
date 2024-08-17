import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraMicPage extends StatefulWidget {
  @override
  _CameraMicPageState createState() => _CameraMicPageState();
}

class _CameraMicPageState extends State<CameraMicPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  bool _isRecording = false;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final permissionStatus = await Permission.camera.request();
    if (permissionStatus.isGranted) {
      _cameras = await availableCameras();
      _initializeCameraController(_currentLensDirection);
    } else {
      print('Camera permission denied');
    }
  }

  Future<void> _initializeCameraController(
      CameraLensDirection direction) async {
    final selectedCamera =
        _cameras.firstWhere((camera) => camera.lensDirection == direction);

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _cameraController.initialize();
    setState(() {});
  }

  Future<void> _switchCamera() async {
    _currentLensDirection = _currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    await _initializeCameraController(_currentLensDirection);
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      setState(() {
        _imageFile = image;
      });
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      try {
        await _cameraController.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        print('Error starting video recording: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController.value.isRecordingVideo) {
      try {
        final video = await _cameraController.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _imageFile = XFile(video.path); // Use the recorded video file
        });
        print('Video recorded: ${video.path}');
      } catch (e) {
        print('Error stopping video recording: $e');
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_cameraController);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          if (_imageFile != null)
            _isRecording
                ? Text('Recording...')
                : Image.file(File(_imageFile!.path)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: _isRecording ? _stopRecording : _takePicture,
                child: Icon(_isRecording ? Icons.stop : Icons.camera),
              ),
              SizedBox(width: 20),
              FloatingActionButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
