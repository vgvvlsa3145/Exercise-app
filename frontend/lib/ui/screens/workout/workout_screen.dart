import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:hyperpulsex/logic/pose_service.dart';
import 'package:hyperpulsex/logic/pose_utils.dart';
import 'package:hyperpulsex/logic/exercise_evaluator.dart';
import 'package:hyperpulsex/data/models/exercise.dart';
import 'pose_painter.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'dart:async';
import 'package:hyperpulsex/data/database_helper.dart';
import 'package:hyperpulsex/data/models/workout_record.dart';
import 'package:hyperpulsex/logic/session_service.dart';
import 'package:hyperpulsex/logic/sync_service.dart';
import 'package:hyperpulsex/logic/recommendation_service.dart';
import 'package:hyperpulsex/data/models/exercise.dart';

import 'summary_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final String exerciseName;
  const WorkoutScreen({super.key, required this.exerciseName});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  CameraController? _controller;
  PoseService _poseService = PoseService();
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isDetecting = false;
  List<Pose> _poses = [];
  InputImageRotation _imageRotation = InputImageRotation.rotation270deg;
  Size _imageSize = const Size(480, 640);
  
  // Logic
  late ExerciseEvaluator _evaluator;
  String _feedback = "Get Ready";
  int _reps = 0;
  bool _isFinishing = false; // Prevent double taps
  double? _currentMetric; // Store raw metric for debug
  int _durationSec = 0;
  Timer? _timer;
  List<double> _accuracies = [];
   double _accuracy = 0.0;
   bool _isTimerOnly = false;
   List<Recommendation> _recommendations = [];
   List<String> _currentInstructions = [];
   List<String> _instructions = []; 
   bool _showSuccess = false;
   DateTime _lastRepTime = DateTime.now();
   double _lightingConfidence = 1.0;

  @override
  void initState() {
    super.initState();
    _currentInstructions = ExerciseEvaluator.getInstructions(widget.exerciseName);
    _initEvaluator();
    _initCamera();
    _startTimer();
    _loadNextUp();
  }

  Future<void> _loadNextUp() async {
     final userId = await SessionService.getUserId();
     if (userId == null) return;
     final profile = await DatabaseHelper.instance.getFitnessProfile(userId);
     if (profile != null) {
        final recs = RecommendationService.getRecommendations(profile);
        if (mounted) {
          setState(() {
            _recommendations = recs.take(3).toList();
          });
        }
     }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _durationSec++;
        });
      }
    });
  }

  void _initEvaluator() {
    final name = widget.exerciseName;
    _evaluator = ExerciseEvaluator.getEvaluator(name);
    _instructions = ExerciseEvaluator.getInstructions(name);
    _currentInstructions = _instructions;
    print("Initialized Evaluator for: $name -> ${_evaluator.runtimeType}");
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Default to front if available, else 0
    if (_controller == null) {
        int frontIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        _cameraIndex = frontIndex != -1 ? frontIndex : 0;
    }

    _startCamera();
  }

  Future<void> _startCamera() async {
     if (_controller != null) {
       await _controller!.dispose();
     }

     _controller = CameraController(_cameras[_cameraIndex], ResolutionPreset.medium, enableAudio: false);
     try {
       await _controller!.initialize();
       if (!mounted) return;
       setState(() {});
       
         _controller!.startImageStream(_processImage);
     } catch (e) {
       print("Camera error: $e");
     }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final poses = await _poseService.processImage(inputImage);
      
      if (mounted) {
        setState(() {
          _poses = poses ?? [];
          if (_poses.isNotEmpty) {
            final pose = _poses.first;
            
            
            final result = _evaluator.evaluate(pose);
            
            // DISPLAY RICH FEEDBACK ON SCREEN
            // User requested "more words and directions" on screen.
            // We use the detailed 'voiceMessage' if available, otherwise the short 'feedback'.
            if (result.voiceMessage != null && result.voiceMessage!.isNotEmpty) {
               _feedback = result.voiceMessage!;
            } else {
               _feedback = result.feedback;
            }
                
            // Check for signature mismatch (Optional: refine this list)
                bool wrongSignature = _feedback.contains("profile") || _feedback.contains("Stand to") || _feedback.contains("horizontally");
                
                if (result.currentMetric != null) {
                    _currentMetric = result.currentMetric; // Capture for Debug Overlay
                    double acc = (result.currentMetric! / 180.0).clamp(0.0, 1.0);
                    if (acc > 0.8) acc = 1.0; 
                    if (_reps == 0) {
                       _accuracy = acc; 
                    } else {
                       _accuracy = (_accuracy * (_reps * 10 + 1) + acc) / (_reps * 10 + 2); 
                    }
                }

                // Confidence Check (Lighting/Visibility)
                if (pose.landmarks.isNotEmpty) {
                   double sum = 0;
                   int count = 0;
                   pose.landmarks.forEach((_, lm) {
                      sum += lm.likelihood;
                      count++;
                   });
                   _lightingConfidence = sum / count;
                }

                if (result.isRepCompleted) {
                    _reps = _evaluator.repCount;
                    _accuracies.add(_accuracy);
                    _lastRepTime = DateTime.now();
                    _playSound();
                    
                    // Trigger Flash
                    _showSuccess = true;
                    Timer(const Duration(milliseconds: 800), () {
                       if (mounted) setState(() => _showSuccess = false);
                    });
                }

                // Auto-reset if stuck (15s timeout)
                if (DateTime.now().difference(_lastRepTime).inSeconds > 15 && _evaluator.state != ExerciseState.neutral) {
                   _feedback = "Ready";
                   _reps = 0;
                   _accuracy = 0.0;
                   if (mounted) _evaluator.reset(); // Reset logic too
                }
            }
          });
      }
    } catch (e) {
      debugPrint("ProcessImage Error: $e");
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    
    // Simple conversion for Android (NV21/YUV_420_888)
    // In production, handle iOS BGRA8888 too.
    
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
       // Standard fix for most Android devices in portrait
       rotation = InputImageRotation.rotation90deg; 
    } else if (Platform.isIOS) {
       rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    
    if (rotation == null) return null;

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    if (mounted) {
      if (_imageRotation != rotation || _imageSize != imageSize) {
        setState(() {
          _imageRotation = rotation!;
          _imageSize = imageSize;
        });
      }
    }

    return InputImage.fromBytes(
       bytes: _concatenatePlanes(image.planes),
       metadata: InputImageMetadata(
         size: imageSize,
         rotation: rotation,
         format: InputImageFormat.nv21,
         bytesPerRow: image.planes[0].bytesPerRow,
       ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final int totalLength = planes.fold(0, (prev, plane) => prev + plane.bytes.length);
    final Uint8List allBytes = Uint8List(totalLength);
    int offset = 0;
    for (Plane plane in planes) {
      allBytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return allBytes;
  }

  void _playSound() {
     debugPrint("BEEP! Rep Completed");
  }

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
    

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _startCamera();
  }

  double _getAccuracyScore() {
    final status = _getFormStatus();
    if (status == "FORM: ELITE") return 1.0;
    if (status == "FORM: GOOD") return 0.7;
    return 0.4;
  }

  Future<void> _finishWorkout() async {
    if (_isFinishing) return;
    _isFinishing = true;

    // Feedback to user immediately
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saving Workout..."), duration: Duration(milliseconds: 1000)),
    );

    _timer?.cancel();
    
    // Fire and forget camera stop to prevent hangs
    _controller?.stopImageStream().catchError((e) => debugPrint("Cam stop error: $e"));
    
    // Stop UI updates
    if (mounted) {
      setState(() {
        _isDetecting = false;
      });
    }

    final userId = await SessionService.getUserId();
    final username = await SessionService.getUsername();
    final effectiveUsername = username ?? "Guest";
    print("WORKOUT DEBUG: Saving for User: $username (Effective: $effectiveUsername)");

    final record = WorkoutRecord(
      username: effectiveUsername,
      exerciseName: widget.exerciseName,
      reps: _reps,
      accuracy: _accuracy, 
      timestamp: DateTime.now(),
      durationSec: _durationSec,
      caloriesBurned: (_reps * 0.5), 
    );

    try {
      // NON-BLOCKING SYNC
      SyncService.syncWorkout(record);

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Saving to History for: $effectiveUsername", style: const TextStyle(color: AppTheme.neonCyan)))
         );
      }

      // LOCAL SAVE WITH TIMEOUT
      // Don't let a slow DB hang the user.
      await DatabaseHelper.instance.saveWorkout(record).timeout(
        const Duration(seconds: 2), 
        onTimeout: () {
          print("DB Save Timed out - continuing anyway");
          return 0;
        }
      );
    } catch (e) {
      print("Save error: $e");
    }

    if (!mounted) return;

    // Navigate to Summary Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryScreen(
           username: effectiveUsername,
           exerciseName: widget.exerciseName,
           reps: _reps,
           durationSec: _durationSec,
           accuracy: _accuracy,
           caloriesBurned: record.caloriesBurned,
        ),
      ),
    );
  }


  @override
  void dispose() {
    _timer?.cancel();
    _poseService.close(); // Close pose detector first
    
    // Safely dispose camera
    if (_controller != null) {
      final camera = _controller!;
      _controller = null; // Prevent further use
      
      try {
        if (camera.value.isStreamingImages) {
           camera.stopImageStream().then((_) => camera.dispose());
        } else {
           camera.dispose();
        }
      } catch (e) {
        print("Error disposing camera: $e");
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          
          // Pose Overlay
          CustomPaint(
            painter: PosePainter(
              _poses, 
              _imageSize, 
              _imageRotation,
              isFrontCamera: _cameras[_cameraIndex].lensDirection == CameraLensDirection.front,
            ),
          ),

          // HUD
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                Flexible( // Prevent Title Overflow
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      widget.exerciseName, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis, // Add ellipsis
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
                  onPressed: () {
                    setState(() {
                      _evaluator.reset();
                      _feedback = "Reset!";
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                  onPressed: _switchCamera,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    padding: const EdgeInsets.symmetric(horizontal: 10), // Reduce padding
                  ),
                  onPressed: _finishWorkout,
                  child: const Text("FINISH", style: TextStyle(fontSize: 12)), // Reduce font size
                ),
              ],
            ),
          ),
          
          // Form Correction Tips Overlay
          if (_feedback.contains("Chest") || _feedback.contains("Back") || _feedback.contains("Hip") || _feedback.contains("heel")
              || _feedback.contains("Knee") || _feedback.contains("Ab") || _feedback.contains("Glute") 
              || _feedback.contains("Lift") || _feedback.contains("Drive") || _feedback.contains("Straighten"))
          Positioned(
            top: 150, left: 40, right: 40,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4)
                ],
              ),
              child: Row(
                children: [
                   const Icon(Icons.tips_and_updates, color: Colors.white),
                   const SizedBox(width: 10),
                   Expanded(
                     child: Text("PRO TIP: $_feedback", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ),
                ],
              ),
            ),
          ),

          // NEW: Progress Gauge
          if (!_isTimerOnly)
          Positioned(
            top: 120,
            right: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: _accuracy,
                    strokeWidth: 6,
                    backgroundColor: Colors.white12,
                    color: AppTheme.neonCyan,
                  ),
                ),
                Text(
                  "${(_accuracy * 100).toInt()}%",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // NEW: Lighting Warning
          if (_lightingConfidence < 0.2)
          Positioned(
            top: 220,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text("MORE LIGHT NEEDED", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // Success Flash Overlay (New)
          if (_showSuccess)
             Positioned.fill(
               child: Center(
                 child: TweenAnimationBuilder<double>(
                   tween: Tween(begin: 0.0, end: 1.0),
                   duration: const Duration(milliseconds: 500),
                   builder: (context, value, child) {
                     return Opacity(
                       opacity: 1.0 - value, 
                       child: Transform.scale(
                         scale: 0.5 + (value * 1.5),
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                           decoration: BoxDecoration(color: AppTheme.neonCyan, borderRadius: BorderRadius.circular(50)),
                           child: const Text("PERFECT!", style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                         ),
                       ),
                     );
                   },
                 ),
               ),
             ),

          // Feedback Overlay (Centralized & Clean)
          if (_feedback.isNotEmpty && _feedback != "Ready" && !_showSuccess)
            Positioned(
              bottom: 220, // Moved up slightly to avoid bottom sheet
              left: 20,
              right: 20,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: _getFeedbackColor().withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: _getFeedbackColor().withOpacity(0.4), blurRadius: 10, spreadRadius: 2)]
                  ),
                  child: Text(
                    _feedback.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      shadows: [Shadow(color: Colors.black45, offset: Offset(1,1), blurRadius: 2)]
                    ),
                  ),
                ),
              ),
            ),
            
           // Dynamic Instructions (Replacing Static List)
           // Only show ONE relevant instruction based on state, or cycle them if idle.
           if (_feedback == "Ready" || _feedback == "Get Ready")
           Positioned(
             bottom: 160,
             left: 40, right: 40,
             child: Center(
               child: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                 child: Text(
                   "Tip: ${_currentInstructions.isNotEmpty ? _currentInstructions.first : "Keep consistent pace"}",
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.white70, fontSize: 12),
                 ),
               ),
             ),
           ),


          // Bottom Sheet (Stats Panel)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 150, // Reduced height
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -5))]
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 15),
                  
                  // Stats Row
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                         // Reps Circle
                         FittedBox( // Safeguard Reps Circle
                           child: Container(
                             width: 80, height: 80,
                             decoration: BoxDecoration(
                               color: Colors.black26, 
                               shape: BoxShape.circle,
                               border: Border.all(color: _getFeedbackColor(), width: 4),
                             ),
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Text("$_reps", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                                 const Text("REPS", style: TextStyle(fontSize: 10, color: Colors.grey)),
                               ],
                             ),
                           ),
                         ),
                         
                         const SizedBox(width: 10),

                         // Feedback Text
                         Expanded(
                           child: Container(
                             margin: const EdgeInsets.only(right: 10),
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), 
                             decoration: BoxDecoration(
                               color: _getFeedbackColor().withOpacity(0.15),
                               borderRadius: BorderRadius.circular(15),
                               border: Border.all(color: _getFeedbackColor(), width: 2),
                             ),
                             child: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 FittedBox(
                                   fit: BoxFit.scaleDown,
                                   child: Text(
                                     _isTimerOnly ? "Keep Moving!" : _feedback,
                                     textAlign: TextAlign.center,
                                     maxLines: 1, 
                                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                   ),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   _isTimerOnly ? "NICE WORK" : _getFormStatus(),
                                   style: TextStyle(color: _getFeedbackColor(), fontSize: 12, fontWeight: FontWeight.w900),
                                 ),
                               ],
                             ),
                           ),
                         ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFeedbackColor() {
    if (_feedback.contains("Perfect") || _feedback.contains("Excellent") || _feedback.contains("Great")) return Colors.greenAccent;
    if (_feedback.contains("Good")) return Colors.blueAccent;
    if (_feedback.contains("Lower") || _feedback.contains("Steady") || _feedback.contains("Ready")) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getFormStatus() {
    if (_feedback.contains("Perfect") || _feedback.contains("Excellent") || _feedback.contains("Great")) return "FORM: ELITE";
    if (_feedback.contains("Good")) return "FORM: GOOD";
    if (_feedback.contains("fix") || _feedback.contains("Straighten") || _feedback.contains("Lower")) return "FORM: IMPROVING";
    return "FORM: CHECKING...";
  }

  Widget _buildFormVisualizer() {
    // A small visual indicator of accuracy
    double score = _getFormStatus() == "FORM: ELITE" ? 1.0 : (_getFormStatus() == "FORM: GOOD" ? 0.7 : 0.4);
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
        border: Border.all(color: _getFeedbackColor(), width: 2),
      ),
      child: Center(
        child: Text("${(score * 100).toInt()}%", style: TextStyle(color: _getFeedbackColor(), fontWeight: FontWeight.bold)),
      ),
    );
  }
}
