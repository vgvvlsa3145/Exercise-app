import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'package:hyperpulsex/ui/screens/workout/workout_screen.dart';
import 'package:hyperpulsex/utils/asset_mapper.dart'; // Import Added

class ExercisePreviewScreen extends StatelessWidget {
  final String title;
  final List<String> instructions;

  const ExercisePreviewScreen({
    super.key,
    required this.title,
    this.instructions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // GIF / Animation Placeholder
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neonCyan.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppTheme.neonCyan.withOpacity(0.2), blurRadius: 20)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Smart GIF Mapping
                      Image.asset(
                        AssetMapper.getGifPath(title),
                        fit: BoxFit.cover,
                        gaplessPlayback: true, // Prevent flickering
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "assets/logo.png", 
                            fit: BoxFit.contain,
                            color: Colors.white24, 
                            colorBlendMode: BlendMode.modulate
                          );
                        },
                      ),
                      const Center(
                        child: Icon(Icons.play_circle_fill, size: 80, color: Colors.white54),
                      ),
                      Positioned(
                        bottom: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.black54,
                          child: const Text("GIF PREVIEW", style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Instructions
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                       Icon(Icons.info_outline, color: AppTheme.neonCyan),
                       SizedBox(width: 10),
                       Text("INSTRUCTIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                    const SizedBox(height: 15),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: instructions.isNotEmpty 
                            ? instructions.asMap().entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text("${e.key + 1}. ", style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white70, height: 1.4))),
                                ]),
                              )).toList()
                            : const [Text("Follow the on-screen guide and maintain good form.", style: TextStyle(color: Colors.white70))],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Start Button
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 10,
                  shadowColor: AppTheme.neonCyan.withOpacity(0.5),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (_) => WorkoutScreen(exerciseName: title))
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("START SESSION", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
