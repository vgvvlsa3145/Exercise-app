import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseUtils {
  static const double alpha = 0.1; // Highly responsive (was 0.4)
  static final Map<String, double> _angleHistory = {};

  /// Calculates and smooths the angle between three points.
  static double getSmoothedAngle(String key, PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    double currentAngle = calculateAngle(a, b, c);
    double prevAngle = _angleHistory[key] ?? currentAngle;
    
    // EMA: Smoothed = (alpha * current) + ((1 - alpha) * previous)
    double smoothedAngle = (alpha * currentAngle) + ((1.0 - alpha) * prevAngle);
    _angleHistory[key] = smoothedAngle;
    return smoothedAngle;
  }

  /// Calculates the angle between three points (A-B-C) where B is the vertex.
  /// Returns degrees (0-180).
  static double calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final double radians = math.atan2(
          c.y - b.y,
          c.x - b.x,
        ) -
        math.atan2(
          a.y - b.y,
          a.x - b.x,
        );

    double angle = radians * 180.0 / math.pi;
    angle = angle.abs(); // Absolute value
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  /// Returns the landmark with higher likelihood (left or right side).
  static PoseLandmark getBestLandmark(Pose pose, PoseLandmarkType left, PoseLandmarkType right) {
    final lmLeft = pose.landmarks[left]!;
    final lmRight = pose.landmarks[right]!;
    return lmLeft.likelihood > lmRight.likelihood ? lmLeft : lmRight;
  }

  /// Checks if a pose is likely facing the camera mainly front-on or side-on.
  /// This helps decide which joints to check.
  /// Threshold depends on distance, simplified here.
  static bool isSideView(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final widthIdx = (leftShoulder.x - rightShoulder.x).abs();
    return widthIdx < 60; 
  }

  /// Returns true if the user is in a horizontal (prone) position.
  /// Robust version: uses hip if ankle is missing.
  static bool isProne(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final hip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle]!;
    
    // Choose furthest visible point
    final lowerPoint = ankle.likelihood > 0.5 ? ankle : hip;

    double xDiff = (shoulder.x - lowerPoint.x).abs();
    double yDiff = (shoulder.y - lowerPoint.y).abs();
    
    // Body is significantly horizontal
    return xDiff > yDiff * 0.6; 
  }

  /// Returns true if the user is in a vertical (upright) position.
  static bool isUpright(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final hip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle]!;
    
    final lowerPoint = ankle.likelihood > 0.5 ? ankle : hip;

    double xDiff = (shoulder.x - lowerPoint.x).abs();
    double yDiff = (shoulder.y - lowerPoint.y).abs();
    
    // Body is primarily vertical
    return yDiff > xDiff * 0.6;
  }
}
