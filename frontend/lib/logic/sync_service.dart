import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/user_model.dart';
import '../data/models/workout_record.dart';
import '../data/local_exercise_data.dart';
import '../data/database_helper.dart';

class SyncService {
  // USB Sync (requires adb reverse tcp:5000 tcp:5000)
  // Physical Device fallback: Use LAN IP if ADB fails.
  // 10.0.2.2 is for Android Emulator only.
  // 127.0.0.1 works only if code runs on same device (e.g. web/desktop or ADB Reverse).
  
  // CURRENT STRATEGY: LAN IP (Wireless Debugging Compatible)
  static String baseUrl = "https://exercise-app-ppo1.onrender.com/api";
  
  static Future<String> getBaseUrl() async {
    return baseUrl;
  }




  static Future<User?> syncUser(User user, Map<String, dynamic> profile) async {
    String url = await getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse("$url/user/sync"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user": {
            ...user.toJson(),
            "profileData": profile,
          },
          "profile": profile,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print("SYNC USER RESPONSE: ${response.body}"); // DEBUG
        final data = json.decode(response.body);
        if (data['user'] != null) {
          try {
             return User.fromJson(data['user']);
          } catch (parseError) {
             throw Exception("Parse Error: $parseError");
          }
        } else {
             throw Exception("Server Success (200) but returned no user data.");
        }
      } else {
        throw Exception("Server Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("SYNC SYNC_USER ERROR: $e");
      throw e; 

    }
  }



  static Future<Map<String, dynamic>?> fetchUserFromCloud(String username) async {
    try {
      String url = await getBaseUrl();
      final response = await http.get(Uri.parse("$url/user/profile/$username"))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Error fetching cloud user: $e");
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getRecommendations(Map<String, dynamic> profile) async {
    try {
      String url = await getBaseUrl();
      final response = await http.post(
        Uri.parse("$url/recommendations"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(profile),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllExercises() async {
    try {
      String url = await getBaseUrl();
      final response = await http.get(
        Uri.parse("$url/exercises"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
         final list = List<Map<String, dynamic>>.from(json.decode(response.body));
         // NUCLEAR OPTION: If backend returns the "fallback" stub list (usually 9 items), 
         // ignore it and use our Full Local Data (46 items).
         if (list.length > 20) return list;
         print("SyncService: Backend returned incomplete list (${list.length}). Using Full Local Data.");
      }
      print("SyncService: Backend empty/unreachable. Using Local Data.");
      return LocalExerciseData.exercises;
    } catch (e) {
      print("SyncService: Network Error ($e). Using Local Data.");
      return LocalExerciseData.exercises;
    }
  }

  static Future<bool> syncWorkout(WorkoutRecord record) async {
    try {
      String url = await getBaseUrl();
      final response = await http.post(
        Uri.parse("$url/workout/sync"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(record.toJson()),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Pull history from Cloud to Device (Login Sync)
  static Future<void> syncHistoryDownstream(String username) async {
    try {
      print("SYNC: Pulling history for $username...");
      String url = await getBaseUrl();
      final response = await http.get(
        Uri.parse("$url/workout/history/$username"),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> cloudRecords = json.decode(response.body);
        print("SYNC: Found ${cloudRecords.length} records in cloud.");

        // Get local records to prevent duplicates
        // Note: Ideally allow DatabaseHelper to handle "Insert if not exists"
        // For now, we just insert. If duplicates occur, we might need a unique constraints.
        // Or we can simple clear local history for this user and replace? 
        // Better: Fetch local, cross-reference timestamps.
        
        final local = await DatabaseHelper.instance.getWorkouts(username);
        final localTimestamps = local.map((w) => w.timestamp.toIso8601String()).toSet();

        int added = 0;
        for (var json in cloudRecords) {
           // Basic de-dupe by timestamp
           final ts = json['timestamp'];
           if (!localTimestamps.contains(ts)) {
              final record = WorkoutRecord(
                username: username,
                exerciseName: json['exerciseName'] ?? json['exercise_name'], // handle potential casing
                reps: json['reps'],
                accuracy: (json['accuracy'] as num).toDouble(),
                durationSec: json['durationSec'] ?? json['duration_sec'],
                caloriesBurned: (json['caloriesBurned'] ?? json['calories_burned'] as num).toDouble(),
                timestamp: DateTime.parse(ts),
              );
              await DatabaseHelper.instance.saveWorkout(record);
              added++;
           }
        }
        print("SYNC: Added $added new records to local DB.");
      }
    } catch (e) {
      print("SYNC ERROR: $e");
    }
  }

  // Push local history to Cloud (Backup)
  static Future<void> syncHistoryUpstream(String username) async {
    try {
      print("SYNC: Pushing history for $username...");
      final localRecords = await DatabaseHelper.instance.getWorkouts(username);
      
      int pushed = 0;
      for (var record in localRecords) {
         final success = await syncWorkout(record);
         if (success) pushed++;
      }
      print("SYNC: Uploaded $pushed/${localRecords.length} records to cloud.");
    } catch (e) {
      print("SYNC UPSTREAM ERROR: $e");
    }
  }
}
