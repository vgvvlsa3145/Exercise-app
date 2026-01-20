import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_utils.dart';
import 'dart:math' as math;
import '../data/local_exercise_data.dart';

// ==============================================================================
// BASE CLASSES & ENUMS
// ==============================================================================

enum ExerciseState { neutral, initiating, eccentric, bottom, concentric, completed }

class EvaluationResult {
  final String feedback;
  final String? voiceMessage;
  final bool isRepCompleted;
  final double? currentMetric;
  EvaluationResult({this.feedback = "", this.voiceMessage, this.isRepCompleted = false, this.currentMetric});
}

abstract class ExerciseEvaluator {
  int repCount = 0;
  ExerciseState state = ExerciseState.neutral;
  int cooldownFrames = 0; 
  int stabilityCounter = 0;

  EvaluationResult evaluate(Pose pose);

  bool checkCooldown() {
    if (cooldownFrames > 0) {
      cooldownFrames--;
      return true;
    }
    return false;
  }

  void triggerCooldown({int newFrames = 10}) {
    cooldownFrames = newFrames;
  }

  void reset() {
    repCount = 0;
    state = ExerciseState.neutral;
    cooldownFrames = 0;
    stabilityCounter = 0;
  }

  // ==========================================================================
  // FACTORY: 46 EXERCISES MAPPED
  // ==========================================================================
  static ExerciseEvaluator getEvaluator(String exerciseName) {
    final n = exerciseName.toLowerCase();
    
    // --- WEIGHT LOSS ---
    if (n.contains("burpee")) return BurpeeEvaluator();
    if (n.contains("jumping jack")) return JumpingJackEvaluator();
    if (n.contains("high knee")) return HighKneesEvaluator();
    if (n.contains("mountain")) return MountainClimberEvaluator();
    if (n.contains("jump squat")) return JumpSquatEvaluator();
    if (n.contains("skater")) return SkaterEvaluator();
    if (n.contains("butt kick")) return ButtKickEvaluator();
    if (n.contains("tuck jump")) return TuckJumpEvaluator();
    if (n.contains("plank jack")) return PlankJackEvaluator();
    if (n.contains("sprint")) return SprintEvaluator();

    // --- WEIGHT GAIN / MUSCLE ---
    if (n.contains("push-up") || n.contains("push up") || n.contains("pushup")) return PushupEvaluator();
    
    if (n.contains("glute bridge")) return GluteBridgeEvaluator();
    
    if (n.contains("squat")) return SquatEvaluator();
    if (n.contains("lunge")) return LungeEvaluator();
    if (n.contains("calf")) return CalfRaiseEvaluator();
    if (n.contains("dip")) return DipEvaluator();
    if (n.contains("deadlift")) return DeadliftEvaluator();
    
    // --- CORE / STATIC / ABS ---
    if (n.contains("side plank")) return SidePlankEvaluator();
    if (n.contains("plank")) return PlankEvaluator(); // Static
    if (n.contains("superman")) return SupermanEvaluator(); // Static
    if (n.contains("hollow")) return HollowBodyEvaluator(); // Static
    if (n.contains("wall sit")) return WallSitEvaluator(); // Static
    if (n.contains("l-sit")) return LSitEvaluator(); // Static
    
    if (n.contains("bicycle")) return BicycleCrunchEvaluator();
    if (n.contains("crunch")) return CrunchesEvaluator();
    if (n.contains("leg raise")) return LegRaiseEvaluator();
    if (n.contains("v-up")) return VUpEvaluator();
    
    if (n.contains("nordic")) return NordicCurlEvaluator();
    
    if (n.contains("pull")) return PullupsEvaluator();
    return GenericEvaluator();
  }

  static List<String> getInstructions(String name) {
    try {
      final match = LocalExerciseData.exercises.firstWhere(
        (e) => e['name'] == name || e['title'] == name,
        orElse: () => {},
      );
      if (match.isNotEmpty && match['steps'] != null) {
        return List<String>.from(match['steps']);
      }
    } catch (e) {
      // Fallback
    }
    
    // Legacy generic fallback
    final n = name.toLowerCase();
    if (n.contains("squat")) return ["Feet width apart", "Hips back", "Chest up", "Drive up"];
    return ["Maintain Form", "Steady Pace", "Breathe"];
  }

  static bool hasEvaluator(String exerciseName) {
    // If it's in our list, we have it. The factory defaults to Generic, so strictly speaking everything 'has' one.
    // But for UI checks, we might want to know if it's "special". 
    // For now, return true as we cover everything.
    return true; 
  }
}

// ==============================================================================
// 1. PUSH & ARM LOGIC
// ==============================================================================

class PushupEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    // Landmarks
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final elbow = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow);
    final wrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist);

    // DEBUG LOG
    double angle = PoseUtils.getSmoothedAngle("pushup", shoulder, elbow, wrist);
    print("PUSHUP_DEBUG: Ang=$angle | State=$state"); // Debug output

    if (shoulder.likelihood < 0.2 || elbow.likelihood < 0.2) {
      return EvaluationResult(feedback: "Show Arms");
    }

    // NO ORIENTATION CHECK (Allow all angles for now)

    // Thresholds:
    // Down: < 140 (Must bend elbows significantly)
    // Up: > 160 (Must lock out)

    if (angle > 160) {
      if (state == ExerciseState.bottom) {
        repCount++;
        triggerCooldown(newFrames: 15);
        state = ExerciseState.neutral;
        return EvaluationResult(feedback: "Good!", isRepCompleted: true, currentMetric: 180);
      }
    } else if (angle < 140) {
      state = ExerciseState.bottom;
      return EvaluationResult(feedback: "Push Up!", currentMetric: angle);
    }
    
    // GUIDE THE USER
    if (state == ExerciseState.neutral) {
        // User hasn't gone down yet
        return EvaluationResult(feedback: "Go Deeper!", currentMetric: angle);
    } else {
        // User is at bottom, needs to go up
        return EvaluationResult(feedback: "Straighten Arms!", currentMetric: angle);
    }
  }
}

class DiamondPushupEvaluator extends PushupEvaluator {} // Logic identical (elbow flexion), form visual is distinct
class WidePushupEvaluator extends PushupEvaluator {}
class DeclinePushupEvaluator extends PushupEvaluator {}
class ArcherPushupEvaluator extends PushupEvaluator {}
class PseudoPlancheEvaluator extends PushupEvaluator {}

class PikePushupEvaluator extends ExerciseEvaluator {
   @override
  EvaluationResult evaluate(Pose pose) {
     // Similar to pushup but checking hips high? Hard to detect hips high reliably without side view.
     // Fallback to arm flexion.
     return PushupEvaluator().evaluate(pose);
  }
}

class HandstandPushupEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final elbow = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow);
    final wrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist);
    
    double angle = PoseUtils.getSmoothedAngle("hspu", shoulder, elbow, wrist);
    // Arms overhead press. Extended = 180. Flexed < 100.
    if (angle > 160) {
       if (state == ExerciseState.bottom) {
         repCount++;
         triggerCooldown();
         state = ExerciseState.neutral;
         return EvaluationResult(feedback: "Good Press!", isRepCompleted: true);
       }
    } else if (angle < 100) {
       state = ExerciseState.bottom;
       return EvaluationResult(feedback: "Press Up");
    }
    return EvaluationResult(feedback: "Lower Head");
  }
}

class DipEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
     final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
     final elbow = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow);
     final wrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist);
     final leftShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftShoulder);
     final rightShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightShoulder);
     final leftElbow = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftElbow, PoseLandmarkType.leftElbow);
     final rightElbow = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightElbow, PoseLandmarkType.rightElbow);
     final leftWrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.leftWrist);
     final rightWrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightWrist, PoseLandmarkType.rightWrist);
     
     if (leftShoulder.likelihood < 0.3 || leftElbow.likelihood < 0.3 || rightShoulder.likelihood < 0.3 || rightElbow.likelihood < 0.3) return EvaluationResult(feedback: "Show Arm");
     
     // Metric: Elbow Angle
     // 180 = Straight Arm (Top)
     // Smoothed Elbow Angle
    double angle = (PoseUtils.calculateAngle(leftShoulder, leftElbow, leftWrist) + 
                    PoseUtils.calculateAngle(rightShoulder, rightElbow, rightWrist)) / 2;   if (angle < 100) { // Down
        state = ExerciseState.bottom;
        return EvaluationResult(feedback: "Push Up!", currentMetric: angle);
     } else if (angle > 160) { // Up (Straight Arm)
        if (state == ExerciseState.bottom) {
           repCount++;
           triggerCooldown(newFrames: 25);
           state = ExerciseState.neutral;
           return EvaluationResult(feedback: "Good Dip!", isRepCompleted: true, currentMetric: 180);
        }
     }
     
     if (state == ExerciseState.bottom) return EvaluationResult(feedback: "Drive Up!", currentMetric: angle);
     return EvaluationResult(feedback: "Dip Down", currentMetric: angle);
  }
}

// ==============================================================================
// 2. SQUAT & LEG LOGIC
// ==============================================================================

class SquatEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    // Robust: Use Best Landmarks
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
    final ankle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);
    
    if (hip.likelihood < 0.3 || knee.likelihood < 0.3) return EvaluationResult(feedback: "Show Full Body");

    // Metric: Hip Depth relative to Knee Y
    double depth = knee.y - hip.y; // Positive = Standing (Hip above Knee)
    
    bool isStanding = depth > 40; // Hip well above knee
    bool isDeep = depth < 10; // Parallel or below

    if (state == ExerciseState.neutral) {
        if (isDeep) {
           state = ExerciseState.eccentric;
           return EvaluationResult(feedback: "Drive Up!", currentMetric: 180);
        }
    } else if (state == ExerciseState.eccentric) {
        if (isStanding) {
           repCount++;
           triggerCooldown(newFrames: 25);
           state = ExerciseState.neutral;
           return EvaluationResult(feedback: "Good Squat!", isRepCompleted: true, currentMetric: 180);
        }
    }
    
    double metric = (1.0 - (depth / 100)) * 180;
    if (metric < 0) metric = 0; if (metric > 180) metric = 180;
    
    if (state == ExerciseState.eccentric) return EvaluationResult(feedback: "Push Up!", currentMetric: metric);
    return EvaluationResult(feedback: "Squat Down", currentMetric: metric);
  }
}

class JumpSquatEvaluator extends SquatEvaluator {
    @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Jump!");
    final res = super.evaluate(pose);
    if (res.isRepCompleted) {
       triggerCooldown(newFrames: 10);
       return EvaluationResult(feedback: "Explode!", isRepCompleted: true);
    }
    return res;
  }
}

class PistolSquatEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Good!");

    final lAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.leftAnkle);
    final rAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightAnkle, PoseLandmarkType.rightAnkle);
    
    // Determine which leg is "active" (bearing weight).
    // The active leg ankle is usually LOWER (grounded) than the pistol leg (lifted).
    bool useLeft = lAnkle.y > rAnkle.y ? true : false;
    
    // Safety fallback: if both are same height, maybe standard squat? 
    // Or check likelihood.
    if (lAnkle.likelihood < 0.3 && rAnkle.likelihood < 0.3) return EvaluationResult(feedback: "Show Legs");
    
    final activeAnkle = useLeft ? lAnkle : rAnkle;
    final activeKnee = useLeft 
        ? PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftKnee)
        : PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightKnee);
    final activeHip = useLeft
        ? PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftHip)
        : PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightHip, PoseLandmarkType.rightHip);

    // Now evaluate depth on Active Leg
    double depth = activeKnee.y - activeHip.y; // Positive = Standing
    
    bool isStanding = depth > 40;
    bool isDeep = depth < 10;

    if (state == ExerciseState.neutral) {
        if (isDeep) {
           state = ExerciseState.eccentric;
           return EvaluationResult(feedback: "Drive Up!", currentMetric: 180);
        }
    } else if (state == ExerciseState.eccentric) {
        if (isStanding) {
           repCount++;
           triggerCooldown(newFrames: 30); // Pistol needs more stability time
           state = ExerciseState.neutral;
           return EvaluationResult(feedback: "Good Pistol!", isRepCompleted: true, currentMetric: 180);
        }
    }
    
    return EvaluationResult(feedback: "Lower Hips", currentMetric: (1.0 - (depth/100)) * 180);
  }
} 
class BulgarianSplitSquatEvaluator extends SquatEvaluator {} // Knee bend track mainly

class LungeEvaluator extends ExerciseEvaluator {
  double? _standingHipY;

  @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Good!");
    
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    
    if (hip.likelihood < 0.2) {
       print("LUNGE DEBUG: Low Likelihood ${hip.likelihood}");
       return EvaluationResult(feedback: "Show Legs");
    }
    
    // Auto-calibrate standing
    if (_standingHipY == null || hip.y < _standingHipY!) {
      _standingHipY = hip.y;
    }

    // Threshold: similar to squat.
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    double torsoLen = (hip.y - shoulder.y).abs();
    if (torsoLen < 10) torsoLen = 100;

    double threshold = torsoLen * 0.2; // Relaxed from 0.25 to 0.2 (shallower lunge ok)

    double diff = hip.y - _standingHipY!; 
    print("LUNGE DEBUG: Y=${hip.y} Stand=$_standingHipY Diff=$diff Thresh=$threshold State=$state");

    if (diff > threshold) { // Down
      state = ExerciseState.bottom;
      return EvaluationResult(feedback: "Drive Up!", currentMetric: diff);
    } else if (diff < (threshold * 0.5)) { // Relaxed return from 0.2 to 0.5 (don't need to stand fully straight)
       if (state == ExerciseState.bottom) {
         repCount++;
         triggerCooldown();
         state = ExerciseState.neutral;
         return EvaluationResult(feedback: "Good Lunge!", isRepCompleted: true);
       }
    }
    return EvaluationResult(feedback: "Step Down", currentMetric: diff);
  }
}

class CalfRaiseEvaluator extends ExerciseEvaluator {
  double? _startY;
  
  @override
  EvaluationResult evaluate(Pose pose) {
    // Robustness: Track Average of Head + Shoulders
    final nose = PoseUtils.getBestLandmark(pose, PoseLandmarkType.nose, PoseLandmarkType.nose);
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    
    if (nose.likelihood < 0.2) return EvaluationResult(feedback: "Show Head");

    double currentY = (nose.y + shoulder.y) / 2.0;

    if (_startY == null) {
       _startY = currentY; 
       return EvaluationResult(feedback: "Stand Tall");
    }

    // Drift correction: if we go LOWER (higher Y) than start, update start.
    if (currentY > _startY!) _startY = currentY;

    // Threshold Calculation
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    double torso = (hip.y - shoulder.y).abs();
    if (torso < 10) torso = 100;
    
    // Increased threshold to 8% OR minimum 15 pixels to avoid noise
    double threshold = torso * 0.08; 
    if (threshold < 15.0) threshold = 15.0; 
    
    double diff = _startY! - currentY; // Positive = UP
    print("CALF DEBUG: Diff=$diff Thresh=$threshold Start=$_startY Cur=$currentY");
    
    // Up (Y decreases, Diff increases)
    if (diff > threshold) { 
       state = ExerciseState.concentric;
       return EvaluationResult(feedback: "Hold!", currentMetric: diff);
    } else if (diff < (threshold * 0.4)) { // Down / Return near start
       if (state == ExerciseState.concentric) {
          repCount++;
          triggerCooldown(newFrames: 20);
          state = ExerciseState.neutral;
          return EvaluationResult(feedback: "Good!", isRepCompleted: true);
       }
    }
    return EvaluationResult(feedback: "Raise Heels", currentMetric: diff);
  }
}

// ==============================================================================
// 3. CORE & FLOOR
// ==============================================================================

class CrunchesEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
    
    double angle = PoseUtils.getSmoothedAngle("crunch", shoulder, hip, knee);

    if (angle < 135) { // Crunched
      state = ExerciseState.concentric;
      return EvaluationResult(feedback: "Squeeze");
    } else {
      if (state == ExerciseState.concentric) {
        repCount++;
        triggerCooldown();
        state = ExerciseState.neutral;
        return EvaluationResult(feedback: "Good!", isRepCompleted: true);
      }
    }
    return EvaluationResult(feedback: "Crunch Up", currentMetric: angle);
  }
}

class LegRaiseEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
    
    // 1. Safety Check
    if (shoulder.likelihood < 0.3 || hip.likelihood < 0.3 || knee.likelihood < 0.3) {
      return EvaluationResult(feedback: "Show Full Body");
    }

    // 2. Horizontal Orientation Check (Prevent Ghost Reps while Standing)
    // If standing, Shoulder Y is much smaller (higher on screen) than Hip Y.
    // If lying flat, Shoulder Y and Hip Y are close.
    if ((shoulder.y - hip.y).abs() > 150) { // Large difference = Standing/Vertical
       return EvaluationResult(feedback: "Lie Flat!");
    }

    double hipAngle = PoseUtils.getSmoothedAngle("leg_raise", shoulder, hip, knee);
    
    // 180 = Flat. < 130 = Legs Up.
    if (hipAngle < 130) { 
       state = ExerciseState.concentric;
       return EvaluationResult(feedback: "Lower Slowly", currentMetric: hipAngle);
    } else {
       if (state == ExerciseState.concentric) {
         // Require a reasonable return (e.g. > 150) to avoid jitter counting
         if (hipAngle > 160) {
            repCount++;
            triggerCooldown(newFrames: 25);
            state = ExerciseState.neutral;
            return EvaluationResult(feedback: "Good Lift!", isRepCompleted: true, currentMetric: 180);
         }
       }
    }
    return EvaluationResult(feedback: "Lift Legs", currentMetric: hipAngle);
  }
}

class VUpEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    // Landmarks
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
    final ankle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);
    final wrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist);

    if (shoulder.likelihood < 0.3 || ankle.likelihood < 0.3) {
      return EvaluationResult(feedback: "Show Full Body");
    }

    // Metric 1: V-Shape (Hip Angle)
    // Flat ~ 180. V-Up ~ < 90.
    double hipAngle = PoseUtils.getSmoothedAngle("vup_hip", shoulder, hip, knee);

    // Metric 2: Touch (Wrist to Ankle distance)
    double touchDist = _dist(wrist, ankle);
    // Normalize touch distance relative to torso length for robustness
    double torsoLen = _dist(shoulder, hip);
    if (torsoLen < 20) torsoLen = 100;
    
    // Thresholds
    // Peak: Angle < 110 AND Hands close to feet
    bool isPeak = hipAngle < 110 && touchDist < (torsoLen * 0.5);
    
    // Flat: Angle > 150
    bool isFlat = hipAngle > 150;

    if (state == ExerciseState.neutral) {
        if (isPeak) {
           state = ExerciseState.concentric; 
           return EvaluationResult(feedback: "Hold!", currentMetric: 180);
        }
    } else if (state == ExerciseState.concentric) {
        if (isFlat) {
           repCount++;
           triggerCooldown(newFrames: 20);
           state = ExerciseState.neutral;
           return EvaluationResult(feedback: "Good V-Up!", isRepCompleted: true, currentMetric: 180);
        }
    }
    
    // Feedback
    if (state == ExerciseState.concentric) return EvaluationResult(feedback: "Lower Slowly", currentMetric: hipAngle);
    return EvaluationResult(feedback: "Reach for Toes!", currentMetric: (180 - hipAngle)); // Visualize closing the gap
  }

  double _dist(PoseLandmark p1, PoseLandmark p2) {
    return math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2));
  }
}

class GluteBridgeEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
    
    double angle = PoseUtils.getSmoothedAngle("bridge", shoulder, hip, knee);
    if (angle > 165) {
      if (state == ExerciseState.neutral) {
         state = ExerciseState.concentric;
         return EvaluationResult(feedback: "Squeeze!");
      }
    } else {
       if (state == ExerciseState.concentric) {
         repCount++;
         triggerCooldown();
         state = ExerciseState.neutral;
         return EvaluationResult(feedback: "Good Bridge!", isRepCompleted: true);
       }
    }
    return EvaluationResult(feedback: "Lift Hips", currentMetric: angle);
  }
}

class SingleLegBridgeEvaluator extends GluteBridgeEvaluator {}

class DeadliftEvaluator extends ExerciseEvaluator {
   @override
  EvaluationResult evaluate(Pose pose) {
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
    
    double angle = PoseUtils.getSmoothedAngle("deadlift", shoulder, hip, knee);
    
    if (angle < 130) {
       state = ExerciseState.bottom;
       return EvaluationResult(feedback: "Hinge Up");
    } else if (angle > 165) {
       if (state == ExerciseState.bottom) {
         repCount++;
         triggerCooldown();
         state = ExerciseState.neutral;
         return EvaluationResult(feedback: "Good Hinge!", isRepCompleted: true);
       }
    }
    return EvaluationResult(feedback: "Hinge Hips", currentMetric: angle);
  }
}



class NordicCurlEvaluator extends ExerciseEvaluator {
  double? _startTorsoAngle;

  @override
  EvaluationResult evaluate(Pose pose) {
     final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
     final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
     final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);

     if (shoulder.likelihood < 0.3 || hip.likelihood < 0.3 || knee.likelihood < 0.3) {
        return EvaluationResult(feedback: "Show Side Profile");
     }

     // 1. Check Straight Back (Shoulder-Hip-Knee ~ 180)
     double backAngle = PoseUtils.getSmoothedAngle("nordic_back", shoulder, hip, knee);
     if (backAngle < 150) {
        return EvaluationResult(feedback: "Straighten Back!", currentMetric: backAngle);
     }

     // 2. Track Forward Lean (Torso Angle relative to Vertical)
     // Vertical ~ 90 (if using atan2 logic dependent on orientation, or simply map Y/X)
     // Simplest: Angle of (Knee->Shoulder) vector.
     // Upright: Knee.x ~ Shoulder.x (Angle ~90 or ~270)
     // Down: Knee.x vs Shoulder.x delta increases.
     
     // Let's use getAngle logic (3 points).
     // Imaginary vertical point above knee?
     // Or just use Shoulder-Knee-Hip angle? No that's back straightness.
     
     // Use raw projection:
     // Upright: Shoulder.y is much smaller than Knee.y.
     // Flat (Bottom): Shoulder.y is close to Knee.y.
     
     double totalHeight = (knee.y - shoulder.y); // Positive when upright
     
     // Auto-calibrate 'Upright' max height
     // This exercise starts at top.
     // Metric: % of descent.
     
     // Heuristic: If Torso moves forward, X changes, Y changes.
     // Let's stick to Y delta.
     // 45 degrees lean is a good partial rep. 90 degrees (Parallel) is pro.
     
     double leanMetric = 0; // 0 = Upright, 100 = Flat
     // If Back is straight, we can assume Hip is hinge.
     // Check angle of Hip-Knee segment vs Vertical? No, Hip-Knee is fixed (thighs).
     // Wait, Nordic curl pivots at KNEES. Thighs move.
     // So we track angle of Thighs relative to vertical.
     // Knee is the pivot.
     
     // Construct a point directly above knee to measure angle?
     // Or just `(180 - smoothedAngle(VerticalPoint, Knee, Hip))`?
     // Actually, just checking Y diff of Shoulder relative to Knee is easiest.
     
     double currentH = (knee.y - shoulder.y);
     // If upright, H is max (e.g. 500px).
     // If flat, H is minimal (~0px).
     
     if (currentH < 50) currentH = 50; // clamp
     
     // State Machine
     // Start: Upright (Large H)
     // Eccentric: H decreases.
     // Bottom: H is small.
     // Concentric: H increases.

     // Thresholds depends on user height.
     // Let's look for relative change or absolute angle.
     // Angle of "Shoulder-Knee" line with vertical.
     double dx = (shoulder.x - knee.x).abs();
     double dy = (shoulder.y - knee.y).abs();
     double leanAngle = math.atan2(dx, dy) * (180 / math.pi); // 0 = Vertical, 90 = Horizontal
     
     if (leanAngle > 30) { // Leaning forward
        state = ExerciseState.eccentric;
        return EvaluationResult(feedback: "Control Fall!", currentMetric: leanAngle);
     } else {
        // Returned to vertical
        if (state == ExerciseState.eccentric && leanAngle < 15) {
           repCount++;
           triggerCooldown(newFrames: 30);
           state = ExerciseState.neutral;
           return EvaluationResult(feedback: "Good Curl!", isRepCompleted: true, currentMetric: 180);
        }
     }

     return EvaluationResult(feedback: "Lean Forward", currentMetric: leanAngle);
  }
}

// ==============================================================================
// 4. CARDIO & DYNAMIC -> Mostly Motion/Time Based
// ==============================================================================

class JumpingJackEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Jack!", currentMetric: 180);
    
    final wrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist);
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    // ... (keep logic same, just update returns)
    final lAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.leftAnkle);
    final rAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightAnkle, PoseLandmarkType.rightAnkle);
    final lShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftShoulder);
    final rShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightShoulder);

    bool handsUp = wrist.y < shoulder.y; 
    double shoulderWidth = (lShoulder.x - rShoulder.x).abs();
    if (shoulderWidth < 20) shoulderWidth = 50; 
    double legSpread = (lAnkle.x - rAnkle.x).abs();
    bool legsWide = legSpread > (shoulderWidth * 1.4); 

    // Metric: Spread Width Scaled (to show movement)
    double metric = (legSpread / shoulderWidth) * 100;
    if (metric > 180) metric = 180;

    if (handsUp && legsWide) {
      state = ExerciseState.concentric;
      return EvaluationResult(feedback: "Return!", currentMetric: metric);
    } else {
       if (state == ExerciseState.concentric && !handsUp && legSpread < (shoulderWidth * 1.2)) {
         repCount++;
         triggerCooldown();
         state = ExerciseState.neutral;
         return EvaluationResult(feedback: "Good!", isRepCompleted: true, currentMetric: 180);
       }
    }
    
    if (state == ExerciseState.concentric) return EvaluationResult(feedback: "Feet Together", currentMetric: metric);
    return EvaluationResult(feedback: "Jump Wide!", currentMetric: metric < 50 ? 50 : metric);
  }
}

class HighKneesEvaluator extends ExerciseEvaluator {
   @override
  EvaluationResult evaluate(Pose pose) {
     if (checkCooldown()) return EvaluationResult(feedback: "Fast!", currentMetric: 180);
     
     final lKnee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftKnee);
     final rKnee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightKnee);
     final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftHip);
     
     // 1. Safety Check: Visibility
     if (lKnee.likelihood < 0.6 || rKnee.likelihood < 0.6 || hip.likelihood < 0.6) {
        return EvaluationResult(feedback: "Show Knees!", currentMetric: 0);
     }

     // 2. Threshold: Relaxed slightly. 
     // Knee must be "High", but we allow it to be slightly below the exact hip line due to camera angles.
     // "Up" = Knee Y < Hip Y + 25 (Slightly below hip level is accepted)
     bool leftUp = lKnee.y < (hip.y + 25); 
     bool rightUp = rKnee.y < (hip.y + 25);
     
     // Metric for Gauge: Show progress as knee rises from the ground
     // Ground is roughly Hip + 300 (or more). Let's say we start showing "green" when it passes Hip + 100.
     double baseline = hip.y + 100;
     double currentHeight = lKnee.y < rKnee.y ? lKnee.y : rKnee.y; // Take highest knee
     double dist = baseline - currentHeight; 
     
     double metric = dist > 0 ? (dist * 1.5) : 0; 
     if (metric > 180) metric = 180;

     // 3. State Machine
     if (state == ExerciseState.neutral) {
        if (leftUp || rightUp) {
           state = ExerciseState.concentric; 
           repCount++;
           triggerCooldown(newFrames: 20); 
           return EvaluationResult(feedback: "High!", isRepCompleted: true, currentMetric: 180);
        }
     } else if (state == ExerciseState.concentric) {
        // Reset: Knee must drop significantly BELOW hip (Hip Y + 70)
        // Ensure user puts leg down.
        bool leftDown = lKnee.y > (hip.y + 70);
        bool rightDown = rKnee.y > (hip.y + 70);
        
        if (leftDown && rightDown) {
           state = ExerciseState.neutral; 
        }
     }

     if (state == ExerciseState.concentric) return EvaluationResult(feedback: "Switch!", currentMetric: 180);
     return EvaluationResult(feedback: "Knees Up!", currentMetric: metric);
  }
}

class SprintEvaluator extends HighKneesEvaluator {}

class BurpeeEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
     final lShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftShoulder);
     final rShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightShoulder);
     final lHip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftHip);
     final rHip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightHip, PoseLandmarkType.rightHip);
     final wrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist);
     
     if (lShoulder.likelihood < 0.3 || wrist.likelihood < 0.3) {
       return EvaluationResult(feedback: "Show Full Body", currentMetric: 0);
     }

     double shoulderY = (lShoulder.y + rShoulder.y) / 2;
     double hipY = (lHip.y + rHip.y) / 2;
     
     bool isStanding = (hipY - shoulderY) > 50; 
     bool isHorizontal = (hipY - shoulderY).abs() < 50;
     bool handsDown = wrist.y > hipY; 

     // Metric: Verticality (Distance between Shoulder and Hip)
     double verticality = (hipY - shoulderY).abs();
     double metric = verticality > 180 ? 180 : verticality;

     if (state == ExerciseState.neutral) {
        if (isHorizontal && handsDown) {
           state = ExerciseState.bottom; 
           return EvaluationResult(feedback: "Pushup Position!", currentMetric: 180);
        }
     } else if (state == ExerciseState.bottom) {
        if (isStanding) {
           repCount++;
           triggerCooldown(newFrames: 40); 
           state = ExerciseState.neutral;
           return EvaluationResult(feedback: "Good Burpee!", isRepCompleted: true, currentMetric: 180);
        }
        return EvaluationResult(feedback: "Stand Up!", currentMetric: 50); // Low metric when stuck at bottom?
     }

     if (state == ExerciseState.bottom) return EvaluationResult(feedback: "Get Up!", currentMetric: 50);
     return EvaluationResult(feedback: "Drop Down!", currentMetric: metric);
  }
}

class MountainClimberEvaluator extends ExerciseEvaluator {
   @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Climb", currentMetric: 180);
    
    final lKnee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftKnee);
    final rKnee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightKnee);
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip); 
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    
    // 1. Safety
    if (lKnee.likelihood < 0.4 || rKnee.likelihood < 0.4) {
       return EvaluationResult(feedback: "Show Legs!", currentMetric: 0);
    }

    // 2. Geometry: Distance Based (Rotation Independent)
    // Torso = Distance(Shoulder, Hip)
    double torsoLen = _dist(shoulder, hip);
    if (torsoLen < 20) torsoLen = 100; // Protection

    double lDist = _dist(lKnee, shoulder);
    double rDist = _dist(rKnee, shoulder);

    // "Up" (Compressed): Knee closer to shoulder than usual.
    // extended leg ~ Torso + Thigh. Compressed leg ~ < Torso.
    // Threshold: Knee is close to matching Torso length (meaning it's high up).
    // Let's say: Distance < TorsoLen * 0.9 (Knee passes hip line upwards)
    bool leftUp = lDist < (torsoLen * 0.85); 
    bool rightUp = rDist < (torsoLen * 0.85);

    // Metric: Normalize [Torso*1.2 (Far)] to [Torso*0.6 (Close)]
    double minDist = lDist < rDist ? lDist : rDist;
    double progress = (torsoLen * 1.2 - minDist) / (torsoLen * 0.6); // 0.0 to 1.0
    double metric = progress * 180;
    if (metric < 0) metric = 0; if (metric > 180) metric = 180;

    // 3. State Machine
    if (state == ExerciseState.neutral) {
        if (leftUp || rightUp) {
           state = ExerciseState.concentric; 
           repCount++;
           triggerCooldown(newFrames: 15);
           return EvaluationResult(feedback: "Go!", isRepCompleted: true, currentMetric: 180);
        }
    } else if (state == ExerciseState.concentric) {
        // Reset: Legs Extended BACK
        // Distance > Torso * 1.0
        bool leftDown = lDist > (torsoLen * 1.0);
        bool rightDown = rDist > (torsoLen * 1.0);

        if (leftDown && rightDown) {
           state = ExerciseState.neutral; 
        }
    }

    if (state == ExerciseState.concentric) return EvaluationResult(feedback: "Switch!", currentMetric: 180);
    return EvaluationResult(feedback: "Drive Knees!", currentMetric: metric);
  }

  double _dist(PoseLandmark p1, PoseLandmark p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return math.sqrt(dx*dx + dy*dy);
  }
}

class PlankJackEvaluator extends ExerciseEvaluator {
   @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Jump!", currentMetric: 180);
    
    final lAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.leftAnkle);
    final rAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightAnkle, PoseLandmarkType.rightAnkle);
    final lShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftShoulder);
    final rShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightShoulder);
    
    double width = (lAnkle.x - rAnkle.x).abs();
    double shoulderWidth = (lShoulder.x - rShoulder.x).abs();
    if (shoulderWidth < 20) shoulderWidth = 50;
    
    // Metric: Width relative to shoulder
    double metric = (width / shoulderWidth) * 100;
    if (metric > 180) metric = 180;

    if (width > (shoulderWidth * 1.3)) { 
       state = ExerciseState.eccentric; 
       return EvaluationResult(feedback: "In!", currentMetric: metric);
    } else if (width < (shoulderWidth * 1.1)) { 
       if (state == ExerciseState.eccentric) {
         repCount++;
         triggerCooldown(newFrames: 10);
         state = ExerciseState.neutral;
         return EvaluationResult(feedback: "Good!", isRepCompleted: true, currentMetric: 180);
       }
    }
    return EvaluationResult(feedback: "Jack!", currentMetric: metric);
  }
}

class SkaterEvaluator extends ExerciseEvaluator {
   @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Skate!", currentMetric: 180);
    
    final lAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.leftAnkle);
    final rAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightAnkle, PoseLandmarkType.rightAnkle);
    final lShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftShoulder);
    final rShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightShoulder);
    
    double shoulderWidth = (lShoulder.x - rShoulder.x).abs();
    if (shoulderWidth < 20) shoulderWidth = 50;

    double dist = (lAnkle.x - rAnkle.x).abs();
    double metric = (1.0 - (dist / shoulderWidth)) * 180;
    if (metric < 0) metric = 0;

    // Logic: 
    // Neutral = Feet Apart (Wide stance)
    // Concentric = Feet Crossed/Close (Curtsy lunge)
    
    bool isWide = dist > (shoulderWidth * 0.8);
    bool isCrossed = dist < (shoulderWidth * 0.35);

    if (state == ExerciseState.neutral) {
        if (isCrossed) {
           state = ExerciseState.concentric;
           repCount++;
           triggerCooldown(newFrames: 20);
           return EvaluationResult(feedback: "Good Skate!", isRepCompleted: true, currentMetric: 180);
        }
    } else if (state == ExerciseState.concentric) {
        if (isWide) {
           state = ExerciseState.neutral;
        }
    }

    if (state == ExerciseState.concentric) return EvaluationResult(feedback: "Hop Back!", currentMetric: 180);
    return EvaluationResult(feedback: "Hop & Cross!", currentMetric: metric);
  }
}

class ButtKickEvaluator extends ExerciseEvaluator {
   @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Kick!", currentMetric: 180);
    
    final lAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.leftAnkle);
    final rAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightAnkle, PoseLandmarkType.rightAnkle);
    final lKnee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftKnee);
    final rKnee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightKnee);
    final lHip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftHip);

    // 1. Safety Check
    if (lAnkle.likelihood < 0.3 || lKnee.likelihood < 0.3) {
       return EvaluationResult(feedback: "Show Legs", currentMetric: 0);
    }

    double thighLen = 50; // default fallout
    if (lHip.likelihood > 0.5) thighLen = (lKnee.y - lHip.y).abs();
    if (thighLen < 20) thighLen = 100;

    // Logic: Heel (Ankle) should go UP towards Glute.
    // Ideally Ankle.Y should get close to Hip.Y OR simply Ankle.Y < Knee.Y (Foot higher than knee)
    // "Up" state: Ankle.y < (Knee.y - offset)
    
    // We use a normalized metric based on full extension vs full curl
    // Full extension: Ankle.y ~ Knee.y + TibiaLen
    // Full Curl: Ankle.y ~ Knee.y (or slightly above/below depending on flexibility)
    
    // Simple Threshold: Ankle is "Up" if it is visibly higher than the "grounded" position.
    // Grounded: Ankle.y is > Knee.y + 20.
    // Action: Ankle.y < Knee.y + 10 (High enough).

    double liftThreshold = lKnee.y + (thighLen * 0.2); // Just below knee height is good enough for a kick
    
    bool leftUp = lAnkle.y < liftThreshold;
    bool rightUp = rAnkle.y < liftThreshold;

    double metric = 0; // 0 = Down, 180 = Full Kick

    if (state == ExerciseState.neutral) {
       if (leftUp || rightUp) {
          state = ExerciseState.concentric;
          repCount++;
          triggerCooldown(newFrames: 15);
          return EvaluationResult(feedback: "Good Kick!", isRepCompleted: true, currentMetric: 180);
       }
    } else if (state == ExerciseState.concentric) {
       // Reset: Both feet down
       // Down = Ankle much lower than knee
       double resetThreshold = lKnee.y + (thighLen * 0.8);
       bool leftDown = lAnkle.y > resetThreshold;
       bool rightDown = rAnkle.y > resetThreshold;
       
       if (leftDown && rightDown) {
          state = ExerciseState.neutral;
       }
    }
    
    if (state == ExerciseState.concentric) return EvaluationResult(feedback: "Switch!", currentMetric: 180);
    return EvaluationResult(feedback: "Heels to Glutes!", currentMetric: metric);
  }
} 
class BicycleCrunchEvaluator extends MountainClimberEvaluator {} 
class TuckJumpEvaluator extends ExerciseEvaluator {
   @override
  EvaluationResult evaluate(Pose pose) {
    if (checkCooldown()) return EvaluationResult(feedback: "Jump!", currentMetric: 180);
    
    final lKnee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftKnee);
    final rKnee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightKnee);
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip); 
    final lAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.leftAnkle);
    final rAnkle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightAnkle, PoseLandmarkType.rightAnkle);
    
    if (lKnee.likelihood < 0.3 || hip.likelihood < 0.3) {
       return EvaluationResult(feedback: "Show Legs!", currentMetric: 0);
    }

    // Logic: 
    // Tuck = Both Knees ABOVE Hip level (Y < Hip.Y)
    // To be robust, also check if feet are off ground (Ankle Y not super low)
    
    // Threshold: Knees higher than Hip line
    bool tucked = lKnee.y < hip.y && rKnee.y < hip.y; 
    
    // Metric: Knee Height relative to Hip
    double metric = 0;
    if (tucked) metric = 180;
    else {
        // Visualize how close knees are to hips
        double dist = (lKnee.y - hip.y); 
        metric = (1.0 - (dist / 100)) * 100; // Rough gauge
    }
    if (metric < 0) metric = 0; if (metric > 180) metric = 180;

    if (state == ExerciseState.neutral) {
        if (tucked) {
           state = ExerciseState.concentric; 
           repCount++;
           triggerCooldown(newFrames: 25);
           return EvaluationResult(feedback: "Good Tuck!", isRepCompleted: true, currentMetric: 180);
        }
    } else if (state == ExerciseState.concentric) {
        // Reset: Feet Down (Ankles well below Hips)
        if (lKnee.y > (hip.y + 50) && rKnee.y > (hip.y + 50)) {
           state = ExerciseState.neutral; 
        }
    }

    if (state == ExerciseState.concentric) return EvaluationResult(feedback: "Land Softly!", currentMetric: 180);
    return EvaluationResult(feedback: "Knees to Chest!", currentMetric: metric);
  }
} 

// ==============================================================================
// 5. STATIC HOLDS -> TIMER BASED
// ==============================================================================

class StaticHoldEvaluator extends ExerciseEvaluator {
  DateTime? _lastTick;
  @override
  EvaluationResult evaluate(Pose pose) {
    final now = DateTime.now();
    if (_lastTick == null || now.difference(_lastTick!).inSeconds >= 1) {
      repCount++; // 1 rep = 1 second
      _lastTick = now;
      return EvaluationResult(feedback: "Hold... ($repCount)", isRepCompleted: true, currentMetric: 180);
    }
    return EvaluationResult(feedback: "Hold...", currentMetric: 180);
  }
}

class PlankEvaluator extends StaticHoldEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
    // 1. Landmarks
    final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
    final ankle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);

    // 2. Safety
    if (shoulder.likelihood < 0.3 || hip.likelihood < 0.3 || knee.likelihood < 0.3) {
      return EvaluationResult(feedback: "Show Full Body");
    }

    // 3. Linearity: Shoulder - Hip - Knee
    // Ideally this angle should be ~180 degrees (Straight line)
    double bodyAngle = PoseUtils.getSmoothedAngle("plank_body", shoulder, hip, knee);
    
    // Also check Hip height? 
    // If Hip is significantly higher than Shoulder, it's a downward dog or pike (Angle < 150 likely).
    // If Hip is very low (Cobra pose), Angle < 150 reversed? (The util always returns positive 0-180).
    
    // Threshold: 160 - 180 is straight.
    bool straight = bodyAngle > 160;
    
    // 4. Horizontal Check
    // For a Plank, the body slope should be low.
    // Slope = (Shoulder.y - Ankle.y) / (Shoulder.x - Ankle.x).
    // Actually, just checking straightness is usually enough to stop "standing" ghosts if we also check orientation.
    // If user is standing up, Shoulder.y < Hip.y < Knee.y. 
    // If user is planking, Shoulder.y ~ Hip.y ~ Knee.y (roughly horizontal).
    
    bool isHorizontal = (shoulder.y - ankle.y).abs() < 200; // Arbitrary wide threshold for horizontal-ish
    // Better: Angle with gravity?
    // Let's rely on linearity first. If you stand straight, it might count as a plank?
    // Yes, standing straight = straight body.
    // Fix: Check if Shoulder Y is close to Hip Y. 
    // In plank: Shoulder Y ~ Hip Y. 
    // In standing: Shoulder Y << Hip Y (Shoulder much higher).
    
    bool horizontal = (shoulder.y - hip.y).abs() < 100; // Should be roughly same height

    if (straight && horizontal) {
        // Use parent logic to tick
        return super.evaluate(pose);
    } else {
        _lastTick = null; // Reset tick if form breaks? Or just pause? 
        // Pause matches better.
        if (!straight) return EvaluationResult(feedback: "Straighten Back!", currentMetric: bodyAngle);
        if (!horizontal) return EvaluationResult(feedback: "Get Down!", currentMetric: bodyAngle);
        return EvaluationResult(feedback: "Hold Plank");
    }
  }
}
class SidePlankEvaluator extends StaticHoldEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
     final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
     final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
     final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
     final ankle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);

     if (shoulder.likelihood < 0.3 || hip.likelihood < 0.3) return EvaluationResult(feedback: "Show Full Body");

     // 1. Straightness
     double bodyAngle = PoseUtils.getSmoothedAngle("side_plank", shoulder, hip, knee);
     bool straight = bodyAngle > 160;

     // 2. Horizontal Check (Prevent Standing Ghosts)
     // Standing: diff > 200 (Shoulder high).
     // Horizontal: diff < 200.
     double slopeDiff = (shoulder.y - ankle.y).abs();
     bool horizontal = slopeDiff < 200;

     if (straight && horizontal) {
         return super.evaluate(pose);
     } else {
         _lastTick = null;
         if (!straight) return EvaluationResult(feedback: "Straighten Hips!", currentMetric: bodyAngle);
         if (!horizontal) return EvaluationResult(feedback: "Get Down!");
         return EvaluationResult(feedback: "Hold Side Plank");
     }
  }
}
class SupermanEvaluator extends StaticHoldEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
     final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
     final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
     final ankle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);
     
     if (shoulder.likelihood < 0.3 || hip.likelihood < 0.3 || ankle.likelihood < 0.3) {
        return EvaluationResult(feedback: "Show Full Body");
     }
     
     // 1. Arch Check: User is lying on stomach (prone), hips on ground.
     // Shoulders and Ankles should be HIGHER (smaller Y) than Hips.
     // Note: Y increases downwards. So Hip.Y > Shoulder.Y and Hip.Y > Ankle.Y
     
     bool upperLift = hip.y > shoulder.y + 20; // Shoulders significantly above hips
     bool lowerLift = hip.y > ankle.y + 20; // Ankles significantly above hips
     
     if (upperLift && lowerLift) {
        return super.evaluate(pose);
     } else {
        _lastTick = null;
        if (!upperLift && !lowerLift) return EvaluationResult(feedback: "Lift Arms & Legs!");
        if (!upperLift) return EvaluationResult(feedback: "Lift Chest!");
        if (!lowerLift) return EvaluationResult(feedback: "Lift Legs!");
        return EvaluationResult(feedback: "Hold Superman");
     }
  }
}

class HollowBodyEvaluator extends StaticHoldEvaluator {}

class WallSitEvaluator extends StaticHoldEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
     final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
     final knee = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
     final ankle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);
     
     if (hip.likelihood < 0.3 || knee.likelihood < 0.3) return EvaluationResult(feedback: "Show Legs");
     
     // 1. Thigh Horizontal Check
     // Hip Y should be roughly equal to Knee Y.
     bool thighHorizontal = (hip.y - knee.y).abs() < 50; 
     
     // 2. Knee Angle Check (~90 degrees)
     // Since we don't have a reliable hip-knee-ankle angle calc for "sitting" vs "standing" purely on just 3 points if viewing from front, 
     // vertical separation of Hip/Knee vs Ankle is better.
     // If standing: Hip Y is much smaller than Knee Y (Hip above Knee).
     // If sitting: Hip Y ~ Knee Y.
     
     // 3. Wall Check (Static torso) - Hard to check without reference, but Thigh Horizontal is main key.
     
     if (thighHorizontal) {
        return super.evaluate(pose);
     } else {
        _lastTick = null;
        // Feedback based on position
        if (hip.y < knee.y - 50) return EvaluationResult(feedback: "Sit Lower!"); // Hip too high
        if (hip.y > knee.y + 50) return EvaluationResult(feedback: "Too Low!"); // Hip below knee (rare)
        return EvaluationResult(feedback: "Hold Parallel!");
     }
  }
}
class LSitEvaluator extends StaticHoldEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
     final shoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
     final hip = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
     final ankle = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);
     
     if (hip.likelihood < 0.3 || ankle.likelihood < 0.3) {
        return EvaluationResult(feedback: "Show Profile");
     }

     // 1. Check L-Shape: Hip Angle ~ 90 deg
     double hipAngle = PoseUtils.getSmoothedAngle("lsit_hip", shoulder, hip, ankle);
     // Range: 75 - 105 is acceptable
     bool isLShape = hipAngle > 70 && hipAngle < 110;

     // 2. Check Legs Horizontal
     // Ankle Y should be close to Hip Y
     bool legsHorizontal = (hip.y - ankle.y).abs() < 100; // Tolerance

     // 3. Check Lift (Feet off ground) implies Ankle.Y is not super huge compared to reference?
     // Hard to know "ground" Y.
     // But if we assume frame captures body, just checking form is usually enough.
     
     if (isLShape && legsHorizontal) {
        return super.evaluate(pose);
     } else {
        _lastTick = null; 
        if (!legsHorizontal) return EvaluationResult(feedback: "Lift Legs!");
        if (!isLShape) return EvaluationResult(feedback: "Straighten Legs!");
        return EvaluationResult(feedback: "Hold L-Sit");
     }
  }
}
class GenericEvaluator extends ExerciseEvaluator {
  @override
  EvaluationResult evaluate(Pose pose) {
     if (checkCooldown()) return EvaluationResult(feedback: "Go!", currentMetric: 180);
     repCount++;
     triggerCooldown(newFrames: 30);
     return EvaluationResult(feedback: "Good Work!", isRepCompleted: true, currentMetric: 180);
  }
}

class PullupsEvaluator extends ExerciseEvaluator {
   @override
   EvaluationResult evaluate(Pose pose) {
      final nose = PoseUtils.getBestLandmark(pose, PoseLandmarkType.nose, PoseLandmarkType.nose);
      final wrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist);
      final lEye = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftEye, PoseLandmarkType.leftEye);
      final rEye = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightEye, PoseLandmarkType.rightEye);
      final leftShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftShoulder);
      final rightShoulder = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightShoulder);
      final leftElbow = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftElbow, PoseLandmarkType.leftElbow);
      final rightElbow = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightElbow, PoseLandmarkType.rightElbow);
      final leftWrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.leftWrist, PoseLandmarkType.leftWrist);
      final rightWrist = PoseUtils.getBestLandmark(pose, PoseLandmarkType.rightWrist, PoseLandmarkType.rightWrist);


      if (wrist.likelihood < 0.3) return EvaluationResult(feedback: "Show Hands");
      
      // Relative Metric: Head Size (Inter-pupillary distance)
      double headSize = (lEye.x - rEye.x).abs();
      if (headSize < 10) headSize = 30; // Fallback

      double diff = nose.y - wrist.y; // Positive = Nose below wrist (Hang). Negative = Nose above (Pullup).
      
      // Check arm extension for "Down" state
      double angle = (PoseUtils.calculateAngle(leftShoulder, leftElbow, leftWrist) + 
                      PoseUtils.calculateAngle(rightShoulder, rightElbow, rightWrist)) / 2;

      // Threshold: Pullup if nose is ABOVE wrist logic
      // We check if nose is visibly above wrist.
      if (diff < 0) { // Nose above wrist
         state = ExerciseState.concentric;
         return EvaluationResult(feedback: "Hold!", currentMetric: diff);
      } else if (angle > 150) { // Down: Arms Extended
         if (state == ExerciseState.concentric) {
            repCount++;
            triggerCooldown();
            state = ExerciseState.neutral;
            return EvaluationResult(feedback: "Good Pull!", isRepCompleted: true);
         }
      }
      return EvaluationResult(feedback: "Pull Up!", currentMetric: diff);
   }
}


