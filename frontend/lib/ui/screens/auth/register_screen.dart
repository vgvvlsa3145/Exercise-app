
import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import '../onboarding/questionnaire_screen.dart';
import 'package:hyperpulsex/data/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController(); // Display Name
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkAndProceed() async {
    final email = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
       return;
    }
    
    if (!email.contains("@")) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Email")));
       return;
    }

    if (password != confirm) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
       return;
    }
    
    if (password.length < 6) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 characters")));
       return;
    }

    setState(() => _isLoading = true);

    // Check if email already exists
    final exists = await DatabaseHelper.instance.getUserByEmail(email);
    
    setState(() => _isLoading = false);

    if (exists != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email already registered")));
      return;
    }

    if (!mounted) return;
    
    // Proceed to Questionnaire, passing credentials
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(
          email: email,
          username: username,
          initialPassword: password,
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Join HyperPulseX",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
            ),
            const SizedBox(height: 10),
            const Text(
              "Start your AI fitness journey today.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 40),
            
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email", 
                prefixIcon: Icon(Icons.email, color: AppTheme.neonCyan)
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: "Username (Display Name)", 
                prefixIcon: Icon(Icons.person, color: AppTheme.neonCyan)
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                 prefixIcon: Icon(Icons.lock, color: AppTheme.neonCyan)
              ),
            ),
             const SizedBox(height: 20),
            
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                 prefixIcon: Icon(Icons.lock_outline, color: AppTheme.neonCyan)
              ),
            ),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _checkAndProceed,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.black) 
                : const Text("NEXT STEP: PROFILE SETUP"),
            ),
          ],
        ),
      ),
    );
  }
}
