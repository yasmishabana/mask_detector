import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'mask_detector_service.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late CameraController _controller;
  late MaskDetector _maskDetector;
  String _label = "Loading...";
  bool _isCameraInitialized = false; // Track initialization state

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize the mask detector
      _maskDetector = MaskDetector();
      await _maskDetector.loadModel();

      // Get available cameras
      final cameras = await availableCameras();
      _controller = CameraController(cameras[0], ResolutionPreset.medium);

      // Initialize the camera
      await _controller.initialize();

      // Update state after successful initialization
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Error during camera initialization: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mask Detection")),
      body: _isCameraInitialized
          ? Column(
              children: [
                Expanded(
                  child: CameraPreview(_controller), // Show camera preview
                ),
                _label =="1 Without_Mask"?
               const Text(
                  "Without_Mask",
                  style: const TextStyle(fontSize: 20),
                )
                :const Text(
                  "With_Mask",
                  style: const TextStyle(fontSize: 20),
                ),
                ElevatedButton(
                  onPressed: _captureImage,
                  child: const Text("Capture & Detect"),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(), // Show loading indicator
            ),
    );
  }

  Future<void> _captureImage() async {
    try {
      // Capture image
      final image = await _controller.takePicture();
      final imgBytes = await File(image.path).readAsBytes();
      final decodedImage = img.decodeImage(imgBytes)!;

      // Run mask detection
      final result = await _maskDetector.runModel(decodedImage);

      setState(() {
        _label = result;
        log("label==="+_label);
      });
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up resources
    _maskDetector.close();
    super.dispose();
  }
}

