
// import 'package:flutter_tts/flutter_tts.dart'; 

class VoiceCoach {
  static final VoiceCoach _instance = VoiceCoach._internal();
  factory VoiceCoach() => _instance;
  VoiceCoach._internal();

  // late FlutterTts _flutterTts;

  Future<void> init() async {
    // Stub
  }

  Future<void> speak(String text) async {
    // Stub
    print("VoiceCoach (Stub): $text");
  }

  Future<void> stop() async {
    // Stub
  }
}
