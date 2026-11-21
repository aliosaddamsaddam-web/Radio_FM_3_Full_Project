RADIO FM 3 — Flutter project

WHAT IS INCLUDED
- Arabic RTL-ready radio interface.
- Internet radio station search through Radio Browser API.
- Internet stream playback using just_audio.
- Demonstration FM frequency screen.

IMPORTANT FM LIMITATION
This project does NOT yet tune real FM hardware. Android's generic public APIs
do not provide a universal way for ordinary third-party apps to control every
phone's FM tuner. Real offline FM requires a compatible tuner chip, vendor
firmware/HAL support, and an accessible API. A wired headset may act as an
antenna on supported devices, but cannot add missing FM hardware.

BUILD APK IN KLENCOD IDE
1. Open/import this folder as a Flutter project.
2. Replace the project's lib/main.dart with the included lib/main.dart.
3. Replace pubspec.yaml with the included pubspec.yaml.
4. Add INTERNET permission to android/app/src/main/AndroidManifest.xml
   (or use the included manifest only if your template matches it; preserve
   any project-specific application settings and icon references).
5. Run Flutter Pub Get.
6. Build > Build APK / or run: flutter build apk --release
7. APK output: build/app/outputs/flutter-apk/app-release.apk

The internet-radio tab needs an internet connection. Stream availability and
station links are provided by the Radio Browser directory and may change.
