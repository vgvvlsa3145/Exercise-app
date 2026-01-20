import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'ui/screens/onboarding/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HyperPulseXApp());
}

class HyperPulseXApp extends StatelessWidget {
  const HyperPulseXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperPulseX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
