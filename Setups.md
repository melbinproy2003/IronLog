# IronLog – Setup & Run Guide

This guide explains how to set up your environment and run the IronLog Flutter application.

---

## Prerequisites

1. **Flutter SDK** (latest stable)
  - Install from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Ensure Flutter is on your PATH.
  - Verify:
    ```bash
    flutter --version
    flutter doctor
    ```
2. **IDE** (optional but recommended)
  - **VS Code** with the Flutter extension, or
  - **Android Studio** with Flutter plugin
3. **Device or emulator**
  - **Android:** Android Studio AVD or a physical device with USB debugging.
  - **iOS (macOS only):** Xcode and an iOS Simulator or a physical device.

---

## 1. Open the project

- **VS Code:** `File → Open Folder` and select the project root (folder containing `pubspec.yaml`).
- **Android Studio:** `File → Open` and select the same folder.
- **Terminal:** `cd` into the project root:
  ```bash
  cd "E:\PrimeLift AI"
  ```
  (Use your actual path if different.)

---

## 2. Install dependencies

From the project root run:

```bash
flutter pub get
```

This installs packages listed in `pubspec.yaml` (e.g. Riverpod, Hive, fl_chart, uuid).

---

## 3. Run the application

### Option A: Default device

If one device/emulator is connected or running:

```bash
flutter run
```

Flutter will pick that device and launch the app.

### Option B: Choose a device

List devices:

```bash
flutter devices
```

Run on a specific device (use the id from the list):

```bash
flutter run -d <device_id>
```

Examples:

- **Chrome (web):** `flutter run -d chrome`
- **Android emulator:** `flutter run -d emulator-5554` (replace with your emulator id)
- **iOS Simulator:** `flutter run -d "iPhone 15"` (replace with your simulator name)

### Option C: From the IDE

- **VS Code:** Press `F5` or use `Run → Start Debugging` (ensure a device is selected in the status bar).
- **Android Studio:** Click the green **Run** button or use `Run → Run 'main.dart'`.

---

## 4. Build for release (optional)

- **Android APK:**
  ```bash
  flutter build apk
  ```
  Output: `build/app/outputs/flutter-apk/app-release.apk`
- **Android App Bundle (for Play Store):**
  ```bash
  flutter build appbundle
  ```
- **iOS (macOS only):**
  ```bash
  flutter build ios
  ```

---

## 5. Run tests (optional)

```bash
flutter test
```

Runs all tests in the `test/` folder.

---

## Troubleshooting


| Issue                        | What to try                                                                                      |
| ---------------------------- | ------------------------------------------------------------------------------------------------ |
| `flutter: command not found` | Add Flutter’s `bin` to your PATH or use the full path to `flutter`.                              |
| `No devices found`           | Start an emulator (Android Studio → AVD Manager) or connect a device with USB debugging enabled. |
| `flutter pub get` fails      | Check internet connection; run `flutter pub cache repair` and try again.                         |
| Build errors after pull      | Run `flutter clean` then `flutter pub get` and build again.                                      |
| Hive/adapters errors         | Ensure you run from the project root so `lib/` and generated/code are found.                     |


---

## Quick reference


| Goal                 | Command             |
| -------------------- | ------------------- |
| Install dependencies | `flutter pub get`   |
| Run app              | `flutter run`       |
| List devices         | `flutter devices`   |
| Clean build          | `flutter clean`     |
| Run tests            | `flutter test`      |
| Build APK            | `flutter build apk` |


Once the app is running, use the bottom navigation: **Dashboard**, **Workout**, **Progress**, and **Coach**. All data is stored locally on the device; no backend or internet is required.