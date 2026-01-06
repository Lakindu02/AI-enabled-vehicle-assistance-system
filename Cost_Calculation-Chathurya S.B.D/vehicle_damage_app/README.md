# Vehicle Damage Assessment Flutter App

A simple Flutter mobile application for assessing vehicle damage using AI-powered image analysis.

## Features

- 📸 Take photos or select from gallery
- 🚗 Enter vehicle details (Brand, Model, Year)
- 🔍 AI-powered damage detection
- 💰 Automatic repair cost estimation
- 🤖 Gemini AI validation and price explanation

## Prerequisites

- Flutter SDK installed
- FastAPI backend running on http://localhost:8000
- Android/iOS device or emulator

## Installation

1. Install dependencies:
```bash
cd vehicle_damage_app
flutter pub get
```

2. Make sure your FastAPI backend is running:
```bash
cd ../Chathurya
source venv/bin/activate
python 3_app.py
```

## Running the App

### For Android Emulator:
```bash
flutter run
```

### For iOS Simulator (macOS only):
```bash
flutter run -d "iPhone 15"
```

### For Physical Device:
1. Enable USB debugging on your Android device
2. Connect via USB
3. Run:
```bash
flutter run
```

## Configuration

### API Endpoint

By default, the app connects to `http://localhost:8000/assess`.

**For Android Emulator:** Change the API URL in `lib/main.dart` line 46:
```dart
final String apiUrl = 'http://10.0.2.2:8000/assess';  // Android emulator
```

**For iOS Simulator:** Keep as:
```dart
final String apiUrl = 'http://localhost:8000/assess';  // iOS simulator
```

**For Physical Device:** Use your computer's IP address:
```dart
final String apiUrl = 'http://192.168.1.X:8000/assess';  // Replace with your IP
```

To find your IP:
- macOS: `ifconfig | grep "inet " | grep -v 127.0.0.1`
- Windows: `ipconfig`
- Linux: `ip addr show`

## How to Use

1. **Launch the app** on your device/emulator
2. **Take a photo** or select an image from gallery
3. **Fill in vehicle details**:
   - Brand (e.g., Toyota)
   - Model (e.g., Corolla)
   - Year (e.g., 2016)
4. **Tap "Assess Damage"** button
5. **View results**:
   - Detected damages with confidence scores
   - Affected vehicle part
   - Estimated repair cost in LKR
   - AI analysis and price explanation

## Troubleshooting

### Connection Error
- Ensure backend API is running
- Check API URL configuration (especially for physical devices)
- Verify firewall settings allow connections on port 8000

### Image Picker Not Working
- Grant camera and storage permissions to the app
- Check device camera functionality

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

## Project Structure

```
vehicle_damage_app/
├── lib/
│   └── main.dart          # Main app code
├── android/               # Android configuration
├── ios/                   # iOS configuration
├── pubspec.yaml          # Dependencies
└── README.md             # This file
```

## Dependencies

- `http`: API requests
- `image_picker`: Camera and gallery access
- `path_provider`: File system access

## Backend API

This app connects to the Vehicle Damage Assessment FastAPI backend.

Backend repository: `../Chathurya/3_app.py`

Ensure the backend is running before using the app.
