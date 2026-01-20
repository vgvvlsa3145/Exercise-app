# HyperPulseX

AI-powered intelligent fitness coaching system using Flutter and Google ML Kit.

## 🚀 Setup Instructions

**Note:** This project code has been generated manually. You need to verify your local Flutter environment.

### 1. Prerequisites
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** (for Android) or **Xcode** (for iOS)

### 2. Initialize Native Files
Since this project was generated without the CLI, you must generate the Android/iOS native folders:

```bash
# Run this in the project root
flutter create .
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Configure Permissions
**Android** (`android/app/src/main/AndroidManifest.xml`):
Add these lines inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera"/>
```

**iOS** (`ios/Runner/Info.plist`):
Add:
```xml
<key>NSCameraUsageDescription</key>
<string>HyperPulseX needs camera access to monitor your exercise form.</string>
<key>NSMicrophoneUsageDescription</key>
<string>HyperPulseX needs microphone access for video recording (optional).</string>
```

### 5. Run the App
```bash
flutter run
```

## 📂 Project Structure
- `lib/data`: Database and Models
- `lib/logic`: AI Pose Logic and State Management
- `lib/ui`: Screens and Widgets
- `lib/main.dart`: Entry point
