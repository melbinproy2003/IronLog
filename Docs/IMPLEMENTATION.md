# IronLog – Implementation Documentation

This document describes what was implemented in the IronLog Flutter application according to the production plan. It is a reference for developers and maintainers.

---

## 1. Overview

**IronLog** is a fully offline workout tracking app with rule-based “AI” strength progression. It uses Flutter, Riverpod, Hive, and fl_chart. There is no backend, Firebase, or paid APIs.

| Aspect | Choice |
|--------|--------|
| State management | Riverpod |
| Local database | Hive |
| Charts | fl_chart |
| Architecture | Clean separation: UI → Providers → Services → Models / Hive |
| Null safety | Enabled (SDK >= 3.0.0) |

---

## 2. What Was Done (By Phase)

### Phase 1: Project Bootstrap and Foundation

- **pubspec.yaml**  
  Dependencies: `flutter_riverpod`, `hive`, `hive_flutter`, `fl_chart`, `path_provider`, `uuid`. Dev: `flutter_lints`, `hive_generator`, `build_runner`.

- **lib/main.dart**  
  Async `main()`: `WidgetsFlutterBinding.ensureInitialized()`, `Hive.initFlutter()`, registration of Hive adapters, `HiveService` creation and `open()`, `ProviderScope` with `hiveServiceProvider` override, `runApp(IronLogApp())`. `IronLogApp` is a `MaterialApp` with `HomeShell` as home.

- **lib/core/constants.dart**  
  App name, Hive box name, default target reps, progression thresholds (e.g. +2.5 kg, -5%, 20% volume, 2-week 1RM drop for deload).

- **lib/core/utils.dart**  
  Pure helpers: `estimated1RM(weight, reps)`, `totalVolume`, `volumeFromSets`, `formatDateKey`, `startOfWeek`. No UI or state.

- **analysis_options.yaml**  
  Lint rules (e.g. prefer_const_constructors, avoid_print).

---

### Phase 2: Data Layer

- **lib/models/exercise_set_model.dart**  
  Immutable `ExerciseSet`: `weight`, `reps`, `completed`. `ExerciseSetAdapter` (Hive typeId 0) for read/write.

- **lib/models/workout_model.dart**  
  Immutable `Workout`: `id`, `date`, `exerciseName`, `sets` (List&lt;ExerciseSet&gt;), `targetReps`. `WorkoutAdapter` (Hive typeId 1) for read/write (nested sets via `writer.write(set)` / `reader.read()`).

- **lib/services/hive_service.dart**  
  Single responsibility: open box, `saveWorkout`, `deleteWorkout`, `getWorkout`, `getAllWorkouts`, `getWorkoutsInRange`, `getWorkoutsOnDate`, `getAllExerciseNames`. No progression or coach logic.

- **main.dart**  
  Registers `ExerciseSetAdapter` and `WorkoutAdapter` and opens the Hive box via `HiveService().open()` before `runApp`.

---

### Phase 3: Progress Calculation (Pure Logic)

- **lib/core/utils.dart**  
  Already contained `estimated1RM` and volume helpers; `volumeFromSets` added for services.

- **lib/services/stats_service.dart**  
  Stateless helpers over workout lists: `best1RMPerExercise`, `best1RMForExercise`, `weeklyVolumePerExercise`, `weeklyBest1RMPerExercise`, `oneRMProgression`. All data derived from passed-in workouts; no UI.

---

### Phase 4: Progression Engine (Rule-Based “AI”)

- **lib/services/progression_engine.dart**  
  - **ProgressionResult**: `suggestWeightChangeKg`, `fatigueWarning`, `suggestDeload`, `messages`.  
  - **ProgressionEngine.analyze(workouts, exerciseName)** applies:
    1. Target reps hit for 2–3 sessions → suggest +2.5 kg.
    2. Target reps failed for 2 sessions → suggest -5% weight.
    3. Weekly volume increase &gt; 20% → set fatigue warning.
    4. 1RM down for 2 consecutive weeks → suggest deload.  
  Uses constants from `core/constants.dart`. Stateless and testable with mock workout lists.

---

### Phase 5: Coach Engine

- **lib/services/coach_engine.dart**  
  - **CoachSuggestion**: `text`, `priority`.  
  - **CoachEngine.suggest(workouts)** builds a list of suggestions by:
    - Running `ProgressionEngine.analyze` per exercise.
    - Turning progression results into suggestions (deload, fatigue, add/reduce weight).
    - Optionally suggesting “Add accessory” when there is 1RM data but no other suggestions.  
  Reuses progression and stats; no UI dependency.

---

### Phase 6: State Management (Riverpod)

- **lib/providers/workout_provider.dart**  
  - **hiveServiceProvider** – Injected in main with opened `HiveService`.  
  - **allWorkoutsProvider** – All workouts from Hive.  
  - **todayWorkoutsProvider** – Workouts for today (derived from all).  
  - **allExerciseNamesProvider** – Sorted unique exercise names.  
  - **recentWorkoutsProvider(days)** – Workouts in last N days (e.g. 56 for 8 weeks).  
  - **best1RMPerExerciseProvider** – Best 1RM per exercise (via `StatsService`).  
  - **progressionResultProvider(exerciseName)** – Progression result for one exercise (via `ProgressionEngine`).  
  - **coachSuggestionsProvider** – Coach suggestions (via `CoachEngine`).  
  - **fatigueWarningProvider** – First fatigue message from any exercise’s progression result.  
  - **oneRMChartDataProvider(exerciseName)** – 1RM progression points for charts.  
  - **weeklyVolumeChartDataProvider(exerciseName)** – Weekly volume points for charts.  
  - **WorkoutNotifier** (workoutNotifierProvider): `saveWorkout`, `deleteWorkout`; invalidates relevant providers.  
  - **createNewWorkout(date, exerciseName, targetReps)** – Factory using `uuid` for `id`.  

  Providers only orchestrate; formulas and rules live in services.

---

### Phase 7: Minimal Workout Screen and Widgets

- **lib/widgets/set_tile.dart**  
  One set: weight and reps `TextField`s, optional remove. Stateful with controllers synced to `ExerciseSet`; `onChanged` and `onRemove` callbacks.

- **lib/widgets/exercise_card.dart**  
  Card with exercise name (from `Workout`), list of `SetTile`s, “Add set” button. Calls `onWorkoutChanged` when sets change.

- **lib/widgets/date_picker_bar.dart**  
  Displays selected date (via `formatDateKey`) and “Change date” button; opens date picker and calls `onDateChanged`.

- **lib/screens/workout_screen.dart**  
  ConsumerStatefulWidget: local state for current `Workout` and exercise name controller. Uses `DatePickerBar`, exercise name `TextField`, `ExerciseCard`, “Save workout” button. Validates non-empty name and at least one set with weight and reps; saves via `workoutNotifierProvider.saveWorkout(toSave)`. No business logic in widget.

---

### Phase 8: Dashboard Screen

- **lib/screens/dashboard_screen.dart**  
  ConsumerWidget watching `todayWorkoutsProvider`, `best1RMPerExerciseProvider`, `fatigueWarningProvider`.  
  - Fatigue warning card (errorContainer) when `fatigueWarningProvider` has a message.  
  - “Latest PR” card: exercise with highest 1RM and value (est. 1RM).  
  - “Today’s workout”: list of today’s workouts as summary cards (exercise name + sets summary).  
  Pull-to-refresh invalidates the relevant providers.

---

### Phase 9: Progress Screen and Charts

- **lib/widgets/one_rm_chart.dart**  
  **OneRMChart**: takes `List<({DateTime date, double oneRm})>`, builds fl_chart `LineChart` (spots, titles, grid). Empty data shows “No 1RM data yet”.

- **lib/widgets/volume_chart.dart**  
  **VolumeChart**: takes `List<({DateTime weekStart, double volume})>`, builds fl_chart `BarChart` (groups, titles, grid). Empty data shows “No volume data yet”.

- **lib/screens/progress_screen.dart**  
  ConsumerStatefulWidget: dropdown for exercise (from `allExerciseNamesProvider`). Two sections: “1RM progression” (data from `oneRMChartDataProvider(exercise)` → `OneRMChart`) and “Weekly volume” (data from `weeklyVolumeChartDataProvider(exercise)` → `VolumeChart`). Handles empty exercise list and invalid selection.

---

### Phase 10: Coach Screen and Navigation Polish

- **lib/screens/coach_screen.dart**  
  ConsumerWidget watching `coachSuggestionsProvider`. Lists suggestions as cards (icon by priority). Pull-to-refresh invalidates provider.

- **lib/screens/home_shell.dart**  
  StatefulWidget: `IndexedStack` of Dashboard, Workout, Progress, Coach; bottom `NavigationBar` with four destinations (Dashboard, Workout, Progress, Coach).

- **lib/main.dart**  
  Home set to `HomeShell()` (replacing temporary home). No other structural changes.

- **Code quality**  
  Short comments in progression and coach engines; logic kept out of UI; small, reusable widgets.

---

## 3. Folder and File Layout

```
lib/
├── main.dart
├── core/
│   ├── constants.dart
│   └── utils.dart
├── models/
│   ├── exercise_set_model.dart
│   └── workout_model.dart
├── services/
│   ├── hive_service.dart
│   ├── stats_service.dart
│   ├── progression_engine.dart
│   └── coach_engine.dart
├── providers/
│   └── workout_provider.dart
├── screens/
│   ├── home_shell.dart
│   ├── dashboard_screen.dart
│   ├── workout_screen.dart
│   ├── progress_screen.dart
│   └── coach_screen.dart
└── widgets/
    ├── set_tile.dart
    ├── exercise_card.dart
    ├── date_picker_bar.dart
    ├── one_rm_chart.dart
    └── volume_chart.dart
```

Root: `pubspec.yaml`, `analysis_options.yaml`, `README.md`.

---

## 4. Data Flow (Summary)

1. **Persistence**  
   `HiveService` is the only writer/reader to Hive. It is created and opened in `main()` and provided via `hiveServiceProvider`.

2. **State**  
   Riverpod providers read from `HiveService` (or from other providers). `WorkoutNotifier` writes through `HiveService` and invalidates `allWorkoutsProvider`, `todayWorkoutsProvider`, etc., so the UI updates.

3. **Business logic**  
   `StatsService`, `ProgressionEngine`, and `CoachEngine` take workout lists (or exercise name) and return derived data or suggestions. They are used only from providers (or tests), not from widgets.

4. **UI**  
   Screens and widgets only `ref.watch` / `ref.read` providers and call notifier methods (e.g. `saveWorkout`). They do not implement 1RM, volume, or progression rules.

---

## 5. Key Formulas and Rules

- **Estimated 1RM:** `1RM = weight × (1 + reps / 30)` (in `core/utils.dart`).
- **Volume:** `volume = sum(weight × reps)` per set (and aggregated per week per exercise in `StatsService`).
- **Progression rules** (in `ProgressionEngine`):  
  - 2–3 sessions hitting target reps → +2.5 kg.  
  - 2 sessions failing target reps → -5% weight.  
  - Weekly volume up &gt; 20% → fatigue warning.  
  - 1RM down for 2 consecutive weeks → suggest deload.

---

## 6. How to Run

1. Ensure Flutter SDK is installed and on PATH.
2. In project root: `flutter pub get`.
3. Run: `flutter run` (device or simulator).

The app starts on `HomeShell` with bottom nav: Dashboard, Workout, Progress, Coach. All data is stored locally via Hive; no network or backend is required.

---

## 7. Constraints Satisfied

- Fully offline: no backend, Firebase, or paid services.
- Business logic only in services (and pure utils); UI only displays and dispatches.
- Clear separation: UI → providers → services → models/Hive.
- Scalable structure: core, models, services, providers, screens, widgets.
- Typed Dart, null safety, small widgets, and comments where needed for rules and flow.

This completes the implementation as specified in the plan.
