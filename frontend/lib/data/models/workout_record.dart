class WorkoutRecord {
  final int? id;
  final String username;
  final String exerciseName;
  final int reps;
  final double accuracy; // 0.0 to 1.0
  final int durationSec;
  final double caloriesBurned;
  final DateTime timestamp;

  WorkoutRecord({
    this.id,
    required this.username,
    required this.exerciseName,
    required this.reps,
    required this.accuracy,
    required this.durationSec,
    required this.caloriesBurned,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'exercise_name': exerciseName,
        'reps': reps,
        'accuracy': accuracy,
        'duration_sec': durationSec,
        'calories_burned': caloriesBurned,
        'timestamp': timestamp.toIso8601String(),
      };

  static WorkoutRecord fromJson(Map<String, dynamic> json) => WorkoutRecord(
        id: json['id'] as int?,
        username: json['username'] as String,
        exerciseName: json['exercise_name'] as String,
        reps: json['reps'] as int,
        accuracy: (json['accuracy'] as num).toDouble(),
        durationSec: json['duration_sec'] as int,
        caloriesBurned: (json['calories_burned'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
