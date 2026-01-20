import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'package:hyperpulsex/logic/session_service.dart';
import 'package:hyperpulsex/ui/screens/auth/login_screen.dart';
import 'package:hyperpulsex/ui/screens/dashboard/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _controller.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait for animation + session check
    await Future.wait([
       Future.delayed(const Duration(seconds: 3)), // Min display time
       SessionService.getUserId(),
    ]).then((values) async {
       final userId = await SessionService.getUserId();
       if (!mounted) return;
       
       if (userId != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
       } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
       }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset("assets/logo.png", height: 150),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                "HyperPulseX", 
                style: TextStyle(
                  fontSize: 36, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ),
             const SizedBox(height: 10),
             FadeTransition(
              opacity: _fadeAnimation,
             child: const Text(
               "Unlock Your Potential", 
               style: TextStyle(color: AppTheme.neonCyan, fontSize: 16),
             ),
             ),
          ],
        ),
      ),
    );
  }
}
