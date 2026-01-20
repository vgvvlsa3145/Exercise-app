import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'package:hyperpulsex/data/database_helper.dart';
import 'package:hyperpulsex/data/models/user_model.dart';
import 'package:hyperpulsex/logic/sync_service.dart';
import 'package:hyperpulsex/logic/session_service.dart';
import '../onboarding/questionnaire_screen.dart';
import '../auth/login_screen.dart';
import 'history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String _cloudStatus = "Checking...";

  int _workoutCount = 0;
  String _avgAccuracy = "-";
  String _computedLevel = "Beginner";

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkCloudStatus();
  }

  Future<void> _loadProfile() async {
    final userId = await SessionService.getUserId();
    if (userId == null) return;

    try {
      final user = await DatabaseHelper.instance.getUserById(userId);
      final profile = await DatabaseHelper.instance.getFitnessProfile(userId);
      final workouts = await DatabaseHelper.instance.getWorkouts(user?.username ?? "");
      
      // Calculate Stats Logic
      int count = workouts.length;
      double totalAcc = 0;
      double calculatedScore = 0;

      for (var w in workouts) {
        totalAcc += w.accuracy;
        // Points Formula: Reps * 10 * AccuracyMultiplier (0.5 to 1.5)
        // Adjust formula to match what you want:
        // Basic: Reps * 10. Accuracy bonus?
        // Let's use: (Reps * 10) * Accuracy
        calculatedScore += (w.reps * 10) * w.accuracy;
      }
      
      String accuracyStr = count > 0 ? "${(totalAcc / count * 100).toInt()}%" : "-";
      int finalScore = calculatedScore.toInt();

      // Real-time Level Logic
      String level = "Beginner";
      if (finalScore >= 10000) level = "Elite";
      else if (finalScore >= 5000) level = "Advanced";
      else if (finalScore >= 1000) level = "Intermediate";

      if (mounted) {
        setState(() {
          _user = user?.copyWith(totalScore: finalScore); // Display real-time score
          _profile = profile;
          _workoutCount = count;
          _avgAccuracy = accuracyStr;
          _computedLevel = level;
          _isLoading = false;
          _cloudStatus = "Checking...";
        });
        
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e"), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _checkCloudStatus() {
    SyncService.getRecommendations({}).then((recs) {
      if (mounted) {
        setState(() {
          _cloudStatus = "Connected";
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _cloudStatus = "Offline";
        });
      }
    });
  }

  Future<void> _manualSync() async {
    if (_user == null) return;
    
    setState(() => _cloudStatus = "Syncing...");
    
    try {
       // 1. Push Profile
       final userUpdated = await SyncService.syncUser(_user!, _profile ?? {});

       // 2. Push History (Upstream) - NEW
       await SyncService.syncHistoryUpstream(_user!.username);
    
       // 3. Pull History (Downstream)
       await SyncService.syncHistoryDownstream(_user!.username);
    
       if (mounted) {
          setState(() => _cloudStatus = userUpdated != null ? "Synced" : "Offline");
          if (userUpdated != null) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sync Complete! Data secured.")));
             _loadProfile(); // Refresh stats
          } else {
             // Should be caught by try-catch now, but just in case
             setState(() => _cloudStatus = "Error");
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sync Failed: Check server logs."), backgroundColor: AppTheme.errorRed));
          }
       }
    } catch (e) {
       if (mounted) {
          setState(() => _cloudStatus = "Error");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync Error: $e"), backgroundColor: AppTheme.errorRed));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Fitness Profile"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.neonCyan,
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_user?.username ?? "User", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.neonCyan, size: 20),
                      onPressed: _showEditNameDialog,
                    ),
                  ],
                ),
                Text(
                  "${_user?.totalScore ?? 0} Pulse Points",
                  style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Text("Goal: ${_profile?['q15'] ?? 'Not Set'}", style: const TextStyle(color: AppTheme.neonCyan)),
            const SizedBox(height: 30),
            
            _buildStatRow(),
            
            const SizedBox(height: 30),

            _buildSectionHeader("Overview"),
            _buildTile(Icons.history, "Workout History", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()));
            }),
            _buildTile(Icons.star, "Achievements", trailing: const Icon(Icons.lock, size: 16, color: Colors.white24)),
            const SizedBox(height: 20),

            _buildSection("Physical Metrics", [
              _buildValueTile(Icons.height, "Height", "${_user?.heightCm} cm"),
              _buildValueTile(Icons.monitor_weight_outlined, "Weight", "${_user?.weightKg} kg"),
              _buildValueTile(Icons.cake, "Age", "${_user?.age} years"),
            ]),

            _buildSection("Settings", [
              _buildTile(Icons.assignment_ind, "Manage Profile Details", 
                trailing: const Icon(Icons.edit, size: 20, color: AppTheme.neonCyan),
                onTap: () async {
                  final refined = await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => QuestionnaireScreen(
                      username: _user!.username,
                      email: _user!.email,
                      existingUser: _user,
                      initialAnswers: _profile,
                      isEditMode: true,
                    ),
                  ));
                  if (refined == true) _loadProfile();
                },
              ),
              _buildTile(
                Icons.sync, 
                "Cloud Sync Status (Tap to Sync)", 
                trailing: Text(_cloudStatus, style: TextStyle(
                  color: (_cloudStatus == "Connected" || _cloudStatus == "Synced") ? AppTheme.successGreen 
                       : (_cloudStatus == "Syncing..." || _cloudStatus == "Checking...") ? AppTheme.neonCyan 
                       : AppTheme.errorRed
                )),
                onTap: _manualSync,
              ),
              _buildTile(Icons.notifications, "Notifications"),
              _buildTile(Icons.logout, "Logout", color: AppTheme.errorRed, onTap: () async {
                await SessionService.clearSession();
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem("Workouts", "$_workoutCount"),
        _buildStatItem("Accuracy", _avgAccuracy),
        _buildStatItem("Level", _computedLevel),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.neonPurple)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
        const SizedBox(height: 10),
        Card(child: Column(children: children)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, {Color? color, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(title, style: TextStyle(color: color ?? Colors.white)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 16),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildValueTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.neonPurple),
      title: Text(title),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _showEditNameDialog() async {
    final ctrl = TextEditingController(text: _user?.username);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGrey,
        title: const Text("Edit Username", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "New Username"),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty && newName != _user?.username) {
                 final messenger = ScaffoldMessenger.of(context);
                 
                 // Check uniqueness
                 final existing = await DatabaseHelper.instance.getUser(newName);
                 if (existing != null) {
                    Navigator.pop(context);
                    messenger.showSnackBar(const SnackBar(content: Text("Username unavailable")));
                    return;
                 }
                 
                 // Update
                 final updatedUser = _user!.copyWith(username: newName);
                 await DatabaseHelper.instance.updateUser(updatedUser);
                 
                 // Update Session
                 await SessionService.saveSession(updatedUser.id!, newName);
                 
                 // Update Cloud if possible
                 SyncService.syncUser(updatedUser, _profile ?? {});

                 if (mounted) {
                    Navigator.pop(context);
                    _loadProfile();
                 }
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
      ),
    );
  }
}
