import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'package:hyperpulsex/data/models/workout_record.dart';

class SummaryScreen extends StatefulWidget {
  final String username;
  final String exerciseName;
  final int reps;
  final int durationSec;
  final double accuracy;
  final double caloriesBurned;

  const SummaryScreen({
    super.key,
    required this.username,
    required this.exerciseName,
    required this.reps,
    required this.durationSec,
    required this.accuracy,
    required this.caloriesBurned,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 100, color: AppTheme.successGreen),
                const SizedBox(height: 20),
                const Text("WORKOUT COMPLETE!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                
                _buildStat("Exercise", widget.exerciseName),
                const SizedBox(height: 10),
                _buildStat("Reps", "${widget.reps}"),
                const SizedBox(height: 10),
                _buildStat("Duration", "${widget.durationSec}s"),
                const SizedBox(height: 10),
                 _buildStat("Accuracy", "${(widget.accuracy * 100).toInt()}%"),
                 const SizedBox(height: 10),
                 _buildStat("Calories", "${widget.caloriesBurned.toInt()} kcal"),
                
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text("Back to Dashboard"),
                )
              ],
            ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return SizedBox(
      width: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 18)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
