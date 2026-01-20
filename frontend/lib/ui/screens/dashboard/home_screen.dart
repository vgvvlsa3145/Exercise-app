import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'package:hyperpulsex/data/database_helper.dart';
import 'package:hyperpulsex/logic/recommendation_service.dart';
import 'package:hyperpulsex/logic/sync_service.dart';
import 'package:hyperpulsex/logic/session_service.dart';
import 'package:hyperpulsex/data/models/user_model.dart';
import 'package:hyperpulsex/data/models/workout_record.dart'; // Import for Graph
import 'exercises_screen.dart';
import 'profile_screen.dart'; 
import 'package:hyperpulsex/ui/screens/workout/exercise_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recommendation> _recommendations = [];
  bool _isLoading = true;
  User? _user;
  int _touchedIndex = -1;
  
  // Real-time Chart Data
  int _totalWorkouts = 0;
  Map<String, int> _exerciseDistribution = {}; 

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await SessionService.getUserId();
    if (userId == null) return;
    
    final profile = await DatabaseHelper.instance.getFitnessProfile(userId);
    final user = await DatabaseHelper.instance.getUserById(userId);
    final sessionName = await SessionService.getUsername();
    final effectiveName = user?.username ?? sessionName ?? "";
    
    final workouts = await DatabaseHelper.instance.getWorkouts(effectiveName);
    
    // Process Workouts for Pie Chart (Specific Exercises)
    int total = workouts.length;
    Map<String, int> distribution = {};
    
    for (var w in workouts) {
      // Capitalize first letter for display
      String name = w.exerciseName.split(' ').map((str) => str.length > 0 ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');
      distribution[name] = (distribution[name] ?? 0) + 1;
    }

    if (mounted) {
      setState(() {
        _user = user;
        _totalWorkouts = total;
        _exerciseDistribution = distribution;
        _recommendations = RecommendationService.getRecommendations(profile ?? {});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset("assets/logo.png", height: 35),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.surfaceGrey,
        selectedItemColor: AppTheme.neonCyan,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercises'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (idx) async {
            if (idx == 1) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisesScreen()));
              _loadProfile(); 
            } else if (idx == 2) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              _loadProfile(); 
            }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Weekly Activity", style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 20),
            
            // Hollow Pie Chart
            SizedBox(
              height: 300, 
              child: _totalWorkouts == 0 
                ? const Center(child: Text("Start working out to see stats!", style: TextStyle(color: Colors.white54)))
                : Stack(
                children: [
                   PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: _showingSections(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("$_totalWorkouts", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text("Workouts", style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            // Legend
            if (_totalWorkouts > 0) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _exerciseDistribution.keys.toList().asMap().entries.map((entry) {
                   final index = entry.key;
                   final name = entry.value;
                   final colors = _getChartColors();
                   return _buildLegendItem(name, colors[index % colors.length]);
                }).toList(),
              ),
            ],

            const SizedBox(height: 30),
            Text(
              _isLoading || _recommendations.isEmpty ? "Getting Ready..." : "Personalized For You", 
              style: Theme.of(context).textTheme.headlineSmall
            ),
            const SizedBox(height: 10),
            
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_recommendations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("Answer all questions to get personalized workouts!", style: TextStyle(color: Colors.white30)),
              )
            else
              ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
          ],
        ),
      ),
    );
  }

  List<Color> _getChartColors() {
    return const [
      AppTheme.neonCyan,
      AppTheme.neonPurple,
      Color(0xFFFF00FF), // Magenta
      Color(0xFFFFD700), // Gold
      Color(0xFF00FF00), // Lime
      Color(0xFFFF4500), // OrangeRed
      Color(0xFF1E90FF), // DodgerBlue
      Color(0xFFFF1493), // DeepPink
      Color(0xFF00FA9A), // SpringGreen
      Color(0xFF8A2BE2), // BlueViolet
      Color(0xFFFF6347), // Tomato
      Color(0xFF40E0D0), // Turquoise
      Color(0xFFD2691E), // Chocolate
      Color(0xFFDC143C), // Crimson
      Color(0xFF7FFF00), // Chartreuse
      Color(0xFF00BFFF), // DeepSkyBlue
    ];
  }

  List<PieChartSectionData> _showingSections() {
    final entries = _exerciseDistribution.entries.toList();
    final colors = _getChartColors();

    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      final entry = entries[i];
      final color = colors[i % colors.length];
      
      final value = entry.value.toDouble();
      final percentage = (value / _totalWorkouts) * 100;

      return PieChartSectionData(
        color: color,
        value: value,
        title: percentage > 5 ? '${percentage.toInt()}%' : '',
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black),
      );
    });
  }

  Widget _buildRecommendationCard(Recommendation rec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: AppTheme.neonCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.flash_on, color: AppTheme.neonCyan),
        ),
        title: Text(rec.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rec.subtitle),
            Text(rec.reason, style: const TextStyle(fontSize: 11, color: AppTheme.neonCyan, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showInstructions(rec),
      ),
    );
  }

  void _showInstructions(Recommendation rec) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePreviewScreen(
          title: rec.title,
          instructions: rec.steps,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
