import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'dart:io';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation, {this.isFrontCamera = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Correct scaling logic considering rotation
    final double scaleX = size.width / 
        (Platform.isAndroid && (rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg) 
          ? absoluteImageSize.height 
          : absoluteImageSize.width);
    final double scaleY = size.height / 
        (Platform.isAndroid && (rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg) 
          ? absoluteImageSize.width 
          : absoluteImageSize.height);

    double translateX(double x) {
      if (isFrontCamera) {
        return size.width - x * scaleX;
      }
      return x * scaleX;
    }

    double translateY(double y) {
      return y * scaleY;
    }

    // --- COLORS ---
    final Color leftColor = AppTheme.neonCyan;
    final Color rightColor = const Color(0xFFFF4081); // Neon Pink/Red
    final Color centerColor = Colors.white;

    // Helper for paint styles
    Paint getPaint(Color color, {bool isGlow = false}) {
       return Paint()
        ..style = isGlow ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = isGlow ? 6.0 : 2.0
        ..color = isGlow ? color.withOpacity(0.6) : color
        ..maskFilter = isGlow ? const MaskFilter.blur(BlurStyle.normal, 4.0) : null;
    }

    for (final pose in poses) {
      // Draw Line Helper
      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Color color) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        final PoseLandmark joint2 = pose.landmarks[type2]!;
        final p1 = Offset(translateX(joint1.x), translateY(joint1.y));
        final p2 = Offset(translateX(joint2.x), translateY(joint2.y));
        
        // Draw Glow
        canvas.drawLine(p1, p2, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..color = color.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0));
          
        // Draw Core
        canvas.drawLine(p1, p2, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = color);
      }

      // Draw Connection Lines (Left = Cyan, Right = Pink, Center = White)
      // Arms
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftColor);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftColor);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, rightColor);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightColor);
      
      // Torso
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, centerColor);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftColor);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, rightColor);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, centerColor);
      
      // Legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftColor);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftColor);
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightColor);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightColor);

      // Draw Joints (Dots)
      pose.landmarks.forEach((type, landmark) {
        // Determine color based on side
        Color jointColor = centerColor;
        if (type.name.contains('left')) jointColor = leftColor;
        if (type.name.contains('right')) jointColor = rightColor;

        final center = Offset(translateX(landmark.x), translateY(landmark.y));
        
        // Outer Glow
        canvas.drawCircle(center, 8.0, Paint()..color = jointColor.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0));
        // Core Dot
        canvas.drawCircle(center, 5.0, Paint()..color = jointColor);
        // White Highlight
        canvas.drawCircle(center, 2.0, Paint()..color = Colors.white);
      });
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses;
  }
}
