# IronLog

**Offline workout tracking app with rule-based strength progression.** No backend, no account, no cost.

---

## Summary

IronLog lets you log workouts, follow training plans, and track progress (1RM, volume, workout analyzer) entirely on your device. It uses simple rules to suggest when to add weight or deload—no cloud or paid APIs.

- **Dashboard** – Today's workouts, fatigue warning, next workout suggestion, filter by date/exercise/plan day
- **Workout** – Start a plan day or log a free workout; plan workouts drive double-progression (weight/rep targets)
- **Plans** – Create and edit multi-day plans with exercises, sets, min/max reps, and weight increments
- **Progress** – 1RM chart, weekly volume (line chart), and workout analyzer (volume per session + session list)
- **Offline-first** – Data stored locally with Hive; works without internet

**Tech:** Flutter, Riverpod, Hive, fl_chart. Clean separation: UI → providers → services → models.

---

## Download (Release APK)

**Tap the link below on your phone to download the app.** The APK will download automatically; then open the file and allow "Install from unknown sources" if asked.

---

### [Download IronLog APK](https://github.com/melbinproy2003/IronLog/releases/latest/download/app-release.apk)
### [Download](https://github.com/melbinproy2003/IronLog/raw/refs/heads/main/releases/latest/download/app-release.apk)

---

**Setup (repo owner):** Replace `YOUR_USERNAME` with your GitHub username and `YOUR_REPO` with this repository name (e.g. `PrimeLift-AI` or `ironlog`). After you [create a release](#build-release-apk-yourself) and attach a file named **`app-release.apk`**, this link will always point to the latest release—one tap to download on phone or desktop.

---

## Build release APK yourself

**Requirements:** Flutter SDK ([flutter.dev](https://flutter.dev)).

```bash
# Clone (if needed)
git clone <your-repo-url>
cd "PrimeLift AI"   # or your project folder name

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

The APK is generated at:

**`build/app/outputs/flutter-apk/app-release.apk`**

- Install on a device: copy `app-release.apk` to the phone and open it, or use `flutter install --release` with the device connected.
- **Provide the APK to users (e.g. GitHub):**
  1. Go to your repo on GitHub → **Releases** → **Create a new release**.
  2. Choose or create a tag (e.g. `v1.0.0`), add a title and optional description.
  3. Attach **`app-release.apk`** (drag & drop or "Attach binaries"). **Name the file exactly `app-release.apk`** so the download link above works.
  4. Publish the release. The [Download IronLog APK](#download-release-apk) link will then start the APK download when users tap it on their phone.

---

## Run from source

```bash
flutter pub get
flutter run
```

See **Setups.md** in this repo for detailed setup and run instructions.

---

## License

See the repository license file (if present).
