# Firebase Setup Guide – IronLog

This guide walks you through adding Firebase (Authentication + Cloud Firestore) to IronLog so the app can sync data across devices when users sign in.

---

## 1. Create a Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** (or **Create a project**).
3. Enter a project name (e.g. `ironlog`) and follow the steps (Google Analytics optional).
4. When the project is ready, open it from the console.

---

## 2. Add Android app

1. In Project overview, click the **Android** icon to add an Android app.
2. **Android package name:** use the same as in your app, e.g. `com.example.ironlog` (see `android/app/build.gradle.kts` → `applicationId`).
3. (Optional) App nickname and Debug signing certificate SHA-1 – you can skip for now.
4. Click **Register app**.
5. **Download `google-services.json`** and place it in your project at:
   ```
   android/app/google-services.json
   ```
6. Click **Next**; the console will show adding the Gradle plugin – the IronLog project already has the plugin applied.
7. Finish the wizard.

---

## 3. Add iOS app (if you build for iOS)

1. In Project overview, click the **iOS** icon to add an iOS app.
2. **iOS bundle ID:** use the same as in your app (e.g. from `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`), e.g. `com.example.ironlog`.
3. (Optional) App nickname and App Store ID – you can skip.
4. Click **Register app**.
5. **Download `GoogleService-Info.plist`** and add it to the Xcode project under `ios/Runner/` (drag into Runner in Xcode and ensure “Copy items if needed” and Runner target are checked).
6. Follow any remaining steps in the wizard.

---

## 4. Download config files (summary)

- **Android:** `google-services.json` → `android/app/google-services.json`
- **iOS:** `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`

Do not commit these files to public repos if the project is sensitive; add them to `.gitignore` and use CI secrets or a secure internal store for builds.

---

## 5. FlutterFire CLI (optional but recommended)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. From your project root (e.g. `E:\PrimeLift AI`), run:
   ```bash
   flutterfire configure
   ```
3. Sign in with Google if prompted, select your Firebase project, and choose the platforms (Android, iOS).  
   This will create/update `lib/firebase_options.dart` and ensure your config files are in place.

If you prefer not to use FlutterFire, ensure `Firebase.initializeApp()` is called without options; Flutter will use the default config from `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).

---

## 6. Required Firebase services

### Authentication (Email/Password)

1. In Firebase Console, go to **Build** → **Authentication**.
2. Click **Get started** if you haven’t used Auth yet.
3. Open the **Sign-in method** tab.
4. Enable **Email/Password** (first provider in the list).

### Cloud Firestore

1. Go to **Build** → **Firestore Database**.
2. Click **Create database**.
3. Choose **Start in test mode** for initial setup (you’ll lock it down with rules next).
4. Pick a location close to your users and confirm.

---

## 7. Firestore structure (recommended)

IronLog uses this structure so each user only accesses their own data:

```
users/{uid}
   └── (document)
         - activePlanId: string | null
         - updatedAt: timestamp

users/{uid}/plans/{planId}
   └── (document) plan data (id, name, createdAt, days[])

users/{uid}/workouts/{workoutId}
   └── (document) workout data (id, date, exerciseName, sets[], ...)
```

All operations require the authenticated user’s `uid`; the app uses it in path builders (see `lib/core/firestore_paths.dart`).

---

## 8. Firestore security rules (copy-paste)

In Firebase Console → **Firestore Database** → **Rules**, replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /plans/{planId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
      match /workouts/{workoutId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

Then click **Publish**.  
These rules ensure users can only read and write their own `users/{uid}` document and its `plans` and `workouts` subcollections.

A copy of these rules is also in the project root: `firestore.rules`. You can deploy them with the Firebase CLI if you use it.

---

## 9. How to test login

1. Run the app: `flutter run`.
2. You should see the **login** screen (no account yet).
3. Tap **Create an account** and register with an email and password (e.g. test@example.com, minimum 6 characters).
4. After registration you should be taken to the main app (Dashboard).
5. Sign out via the logout icon on the Dashboard, then sign in again with the same email/password to confirm login works.

---

## 10. How to test Firestore writes

1. Sign in (as above).
2. Create a plan (Plan tab → add plan, add days/exercises, save).
3. Log a workout (Workout tab → Start Plan Workout or Log Free Workout, add sets, save).
4. In Firebase Console → **Firestore Database**, open **users** → your `uid` (long string). You should see:
   - The user document (e.g. `activePlanId`, `updatedAt`).
   - Subcollection **plans** with your plan document(s).
   - Subcollection **workouts** with your workout document(s).

If you see data there, Firestore writes are working.

---

## 11. Common errors and fixes

| Error | Cause | Fix |
|-------|--------|-----|
| **Firebase not configured** / missing options | Config files missing or wrong path | Add `google-services.json` under `android/app/`, and (iOS) `GoogleService-Info.plist` in `ios/Runner/`. Run `flutterfire configure` if you use it. |
| **Permission denied** in Firestore | Rules not published or too strict | Publish the rules from section 8. Ensure you’re signed in so `request.auth.uid == uid`. |
| **Email/Password sign-in disabled** | Auth provider not enabled | In Authentication → Sign-in method, enable **Email/Password**. |
| **Build error: duplicate class** (Android) | Conflicting Firebase/Play services deps | Align `firebase_core` / `firebase_auth` / `cloud_firestore` versions in `pubspec.yaml` with the [FlutterFire docs](https://firebase.flutter.dev/docs/overview). |
| **No user after sign-in** | Auth state not updating | Ensure `authStateProvider` (StreamProvider) is used for the app’s home screen so the UI switches to `HomeShell` when `user != null`. |

---

## 12. Deploying the app safely

1. **Security rules:** Always use the rules from section 8 (or `firestore.rules`); avoid long-term “test mode” that allows open read/write.
2. **API keys:** The config files contain non-secret identifiers. Restrict Android/iOS keys in [Google Cloud Console](https://console.cloud.google.com/) (APIs & Services → Credentials) to your app’s package name/bundle ID and, if needed, to specific APIs (e.g. Firestore, Auth).
3. **Release build:** For release, use a proper signing config and never commit keystores or secrets. Use environment or CI variables for any extra config.
4. **Updates:** After changing rules or Auth settings, test login and a few Firestore reads/writes before releasing.

---

## Summary

- Create a Firebase project, add Android (and iOS) apps, and place the config files as in sections 2–4.
- Optionally run `flutterfire configure` (section 5).
- Enable **Authentication** (Email/Password) and **Cloud Firestore** (section 6).
- Use the Firestore structure in section 7 and the security rules in section 8.
- Test with login (section 9) and Firestore writes (section 10), and fix common issues using section 11.
- Before release, lock down rules and keys as in section 12.
