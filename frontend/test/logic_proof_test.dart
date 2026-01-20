import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:hyperpulsex/logic/exercise_evaluator.dart';
import 'package:hyperpulsex/logic/pose_utils.dart';

// Mocking PoseLandmark since we can't easily instantiate native objects sometimes
// But checking the package, it typically allows:
// PoseLandmark(type: type, x: x, y: y, z: z, likelihood: 1.0)

Pose createPose(Map<PoseLandmarkType, List<double>> landmarks) {
  final map = <PoseLandmarkType, PoseLandmark>{};
  landmarks.forEach((type, pos) {
    map[type] = PoseLandmark(type: type, x: pos[0], y: pos[1], z: 0, likelihood: 1.0);
  });
  return Pose(landmarks: map);
}

void main() {
  group('LegRaiseEvaluator Logic', () {
    late LegRaiseEvaluator evaluator;

    setUp(() {
      evaluator = LegRaiseEvaluator();
    });

    test('Detects Leg Raise Rep', () {
      // 1. Initial: Legs Down (Shoulder, Hip, Knee in line)
      // angle ~ 180
      var poseDown = createPose({
         PoseLandmarkType.leftShoulder: [0, 0],
         PoseLandmarkType.leftHip: [0, 50],
         PoseLandmarkType.leftKnee: [0, 100], // Straight line down
         PoseLandmarkType.leftAnkle: [0, 150],
      });
      
      evaluator.evaluate(poseDown);
      expect(evaluator.state, ExerciseState.initiating); // Feedback: Lift legs!

      // 2. Legs Up (Hip Flexion)
      // Hip at 50. Knee at 50 (same Y level) -> 90 degrees
      var poseUp = createPose({
         PoseLandmarkType.leftShoulder: [0, 0],
         PoseLandmarkType.leftHip: [0, 50],
         PoseLandmarkType.leftKnee: [50, 50], 
         PoseLandmarkType.leftAnkle: [100, 50],
      });

      evaluator.evaluate(poseUp);
      expect(evaluator.state, ExerciseState.eccentric); // Feedback: Lower slowly
      
      // 3. Legs Down again
      var result = evaluator.evaluate(poseDown);
      expect(result.isRepCompleted, true);
      expect(evaluator.repCount, 1);
    });
  });

  group('MountainClimber Logic', () {
    late MountainClimberEvaluator evaluator;

    setUp(() {
      evaluator = MountainClimberEvaluator();
    });

    test('Detects Knee Drive', () {
      // Prone Position (Horizontal)
      // Shoulder (0,0), Hip (100, 0)
      
      // 1. Neutral (Plank)
      var posePlank = createPose({
         PoseLandmarkType.leftShoulder: [0, 0],
         PoseLandmarkType.leftHip: [100, 0],
         PoseLandmarkType.rightHip: [100, 0],
         PoseLandmarkType.leftKnee: [150, 0], // Extended back
         PoseLandmarkType.rightKnee: [150, 0],
      });
      
      evaluator.evaluate(posePlank);
      expect(evaluator.state, ExerciseState.neutral);

      // 2. Drive Left Knee (Close to Chest/Shoulder)
      // Left Knee moves to 50
      var poseDrive = createPose({
         PoseLandmarkType.leftShoulder: [0, 0],
         PoseLandmarkType.leftHip: [100, 0],
         PoseLandmarkType.rightHip: [100, 0],
         PoseLandmarkType.leftKnee: [50, 0], // DRIVING!
         PoseLandmarkType.rightKnee: [150, 0],
      });

      evaluator.evaluate(poseDrive);
      expect(evaluator.state, ExerciseState.concentric); // "Fast!"

      // 3. Return (Both back)
      var result = evaluator.evaluate(posePlank);
      expect(result.isRepCompleted, true);
      expect(evaluator.repCount, 1);
    });
  });
}
