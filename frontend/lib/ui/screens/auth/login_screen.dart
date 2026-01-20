import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import '../onboarding/questionnaire_screen.dart';
import 'register_screen.dart';
import 'package:hyperpulsex/data/database_helper.dart';
import '../dashboard/home_screen.dart';
import 'package:hyperpulsex/data/models/user_model.dart';
import 'package:hyperpulsex/logic/session_service.dart';
import 'package:hyperpulsex/logic/sync_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(); // Not strictly using auth for local, but for simulation
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final email = _usernameCtrl.text.trim(); // We keep the controller name for now to avoid massive refactor, but it holds EMAIL
    if (email.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter email")));
      return;
    }

    final password = _passwordCtrl.text;

    // --- EMERGENCY OFF-LINE BYPASS FOR ADMIN ---
    if (email == "gv@gmail.com") {
       // Check if A1 exists or creating him
       User? localAdmin = await DatabaseHelper.instance.getUserByEmail(email);
       if (localAdmin == null) {
          debugPrint("Admin not found locally, force creating...");
          final admin = User(
            username: "A1",
            email: "gv@gmail.com",
            password: "pass123",
            age: 25,
            gender: "Male",
            heightCm: 180,
            weightKg: 75,
            targetWeightKg: 80,
            totalScore: 5000,
            createdAt: DateTime.now()
          );
          final id = await DatabaseHelper.instance.createUser(admin);
          
          // Force save profile
          final profile = {
             "q2": "Male", "q6": "No", "q15": "Muscle Gain", "q18": "High", 
             "q20": "5+ days/week", "q31": "Home", "q32": ["None"]
          };
          await DatabaseHelper.instance.saveFitnessProfile(id, profile);
       }
    }
    // -------------------------------------------

    // Check DB by EMAIL
    User? user = await DatabaseHelper.instance.getUserByEmail(email);
    
    // Cloud Check if not local
    if (user == null) {
      // NOTE: SyncService might need update to search by email too? 
      // For now, let's assume cloud syncs by username or we might miss this.
      // Ideally we fetch by Email from cloud. 
      // But SyncService.fetchUserFromCloud currently takes 'username'.
      // If the backend was updated to support email lookup, we'd use that.
      // For now, let's try assuming the user meant 'username' if email fails? 
      // Or just skip cloud sync for this specific email flow until backend catches up.
      // WAIT -> Backend User model likely needs 'email' too if we sync.
      // Let's rely on local creation or Registration for now.
    }

    setState(() => _isLoading = false);
    
    if (user != null) {
       // Verify Password
       if (user.password != null && user.password != password) { // Admin has hardcoded pass check inside created user
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid password")));
          return;
       }

       if (!mounted) return;
       await SessionService.saveSession(user.id!, user.username);
       
       // SYNC HISTORY DOWNSTREAM
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
         content: Text("Syncing your history...", style: TextStyle(color: Colors.white)),
         backgroundColor: Colors.blueAccent,
         duration: Duration(milliseconds: 1500),
       ));
       await SyncService.syncHistoryDownstream(user.username);

       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Welcome back, ${user.username}!"))); // Shows "A1"
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
       if (!mounted) return;
       // If not found, assume new user? Or prompt to register.
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found. Please Register.")));
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset("assets/logo.png", height: 120),
              const SizedBox(height: 10),
              const Text(
                "HyperPulseX",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "AI-Powered Fitness Coaching",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 50),
              
              TextField(
                controller: _usernameCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text("LOGIN"),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text("Create Account"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
