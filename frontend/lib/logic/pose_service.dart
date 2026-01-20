import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class PoseService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  bool _isBusy = false;

  Future<List<Pose>?> processImage(InputImage inputImage) async {
    if (_isBusy) return null;
    _isBusy = true;
    try {
      final poses = await _poseDetector.processImage(inputImage);
      return poses;
    } catch (e) {
      debugPrint("Error detecting pose: $e");
      return null;
    } finally {
      _isBusy = false;
    }
  }

  void close() {
    _poseDetector.close();
  }

  // Helper to convert CameraImage to InputImage (Standard Boilerplate)
  // Note: This logic depends on platform (Android/iOS). 
  // For brevity in this generated code, we assume standard usage.
  // In a full implementation, you need the 'transform' logic here.
}
