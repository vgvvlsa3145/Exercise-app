import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'package:hyperpulsex/ui/screens/workout/workout_screen.dart'; 
import 'package:hyperpulsex/ui/screens/workout/exercise_preview_screen.dart';
import 'package:hyperpulsex/logic/exercise_evaluator.dart';
import 'package:hyperpulsex/logic/sync_service.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<String> _weightLoss = [];
  List<String> _weightGain = [];
  List<String> _normal = [];
  List<String> _muscle = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    final allExercises = await SyncService.fetchAllExercises();
    
    // Categorize
    List<String> wl = [];
    List<String> wg = [];
    List<String> n = [];
    List<String> m = [];

    for (var ex in allExercises) {
      String name = ex['name'] ?? ex['title'] ?? "Unknown";
      List<dynamic> goals = ex['goals'] ?? [];
      
      // Multi-category support
      if (goals.contains("Weight Loss") || goals.contains("Cardio")) wl.add(name);
      
      // "Weight Gain" includes specific Muscle Gain exercises
      if (goals.contains("Weight Gain") || goals.contains("Muscle Gain")) {
         if ((goals.contains("Muscle Gain") && _isCompound(name)) || goals.contains("Weight Gain")) {
            wg.add(name);
         }
         // Also add to Muscle list effectively
         m.add(name);
      }
      
      // "Normal" includes Fitness and Toning
      if (goals.contains("Fitness") || goals.contains("General Fitness") || goals.contains("Toning")) n.add(name);
    }
    
    // Fallback if empty (shouldn't happen with updated backend)
    if (allExercises.isEmpty) {
       // Use local backup only if completely offline
       wg = ["Squats", "Push-ups", "Lunges"];
    }

    if (mounted) {
      setState(() {
        _weightLoss = wl.isEmpty ? ["Jumping Jacks", "Burpees"] : wl;
        _weightGain = wg.isEmpty ? ["Squats", "Push-ups"] : wg;
        _muscle = m.isEmpty ? ["Push-ups", "Pull-ups"] : m;
        _normal = n.isEmpty ? ["Plank", "Crunches"] : n;
        _isLoading = false;
      });
    }
  }

  bool _isCompound(String name) {
    // Helper to put big lifts in "Weight Gain"
    final n = name.toLowerCase();
    return n.contains("squat") || n.contains("deadlift") || n.contains("press") || n.contains("row") || n.contains("pull-up") || n.contains("dip");
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.deepBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Exercise Library"),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.neonCyan,
            labelColor: AppTheme.neonCyan,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "Weight Loss"),
              Tab(text: "Weight Gain"),
              Tab(text: "Normal"),
              Tab(text: "Muscle"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, _weightLoss),
            _buildList(context, _weightGain), 
            _buildList(context, _normal),
            _buildList(context, _muscle),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<String> exercises) {
    // Remove duplicates
    final unique = exercises.toSet().toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unique.length,
      itemBuilder: (context, index) {
        final name = unique[index];
        final isAI = ExerciseEvaluator.hasEvaluator(name);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAI ? AppTheme.neonCyan.withOpacity(0.2) : Colors.black26,
              child: Icon(
                Icons.fitness_center, 
                color: isAI ? AppTheme.neonCyan : Colors.white54
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: isAI 
              ? const Text("AI Rep Counting", style: TextStyle(color: AppTheme.neonCyan, fontSize: 10))
              : const Text("Timer Based", style: TextStyle(color: Colors.white30, fontSize: 10)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: isAI ? AppTheme.neonPurple : Colors.grey[800],
              ),
              onPressed: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExercisePreviewScreen(
                      title: name,
                      instructions: ExerciseEvaluator.getInstructions(name), 
                    ),
                  ),
                );
              },
              child: const Text("PREVIEW"),
            ),
          ),
        );
      },
    );
  }
}
