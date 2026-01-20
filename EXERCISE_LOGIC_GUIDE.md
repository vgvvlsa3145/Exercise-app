# Exercise Evaluation Logic Guide

This document details the internal logic, thresholds, and form cues used by the AI Motion Engine to evaluate user performance.

---

## 🏋️ Weight Loss / Cardio

### 1. Burpees
*   **Logic:** State machine tracking verticality and wrist position.
*   **Start/Down:** User drops to pushup position (Hips and Shoulders aligned horizontally, Hands below hips).
    *   *Threshold:* `|Hip.Y - Shoulder.Y| < 50` AND `Wrist.Y > Hip.Y`.
*   **End/Up:** User stands up vertical.(Jump is not strictly enforced to allow modification, but verticality is).
    *   *Threshold:* `Hip.Y - Shoulder.Y > 50`.
*   **Feedback:** "Pushup Position!", "Stand Up!", "Drop Down!".

### 2. Jumping Jacks
*   **Logic:** Tracks limb expansion relative to shoulder width.
*   **Start (Out):** Legs wide, Hands up.
    *   *Threshold:* `LegSpread > 1.4 * ShoulderWidth` AND `Wrist.Y < Shoulder.Y`.
*   **End (In):** Feet together, Hands down.
    *   *Threshold:* `LegSpread < 1.1 * ShoulderWidth` AND `Wrist.Y > Shoulder.Y`.
*   **Feedback:** "Jump Wide!", "Feet Together!".

### 3. High Knees
*   **Logic:** Checks knee height relative to hip height.
*   **Rep Count:** One knee passes the threshold.
    *   *Threshold:* `Knee.Y < Hip.Y + 25` (Knee rises above or near hip line).
*   **Reset:** Knee drops back down.
    *   *Threshold:* `Knee.Y > Hip.Y + 70`.
*   **Feedback:** "Knees Up!", "Switch!".

### 4. Mountain Climbers
*   **Logic:** Tracks knee proximity to shoulders in a plank position.
*   **Start (Knee In):** Knee drives close to torso.
    *   *Threshold:* `KneeDistance < TorsoLength * 0.85`.
*   **End (Leg Out):** Leg extends back.
    *   *Threshold:* `KneeDistance > TorsoLength * 1.0`.
*   **Feedback:** "Drive Knees!", "Switch!".

### 5. Jump Squats
*   **Logic:** Extends Standard Squat logic with cooldowns for air time.
*   **Down:** Hip creases below knee.
    *   *Threshold:* `Knee.Y - Hip.Y < 10` (Parallel or below).
*   **Up:** Full extension/Jump.
    *   *Threshold:* `Knee.Y - Hip.Y > 40` (Standing tall).
*   **Feedback:** "Jump!", "Explode!", "Drive Up!".

### 6. Skaters
*   **Logic:** Lateral movement + Curtsy lunge sensing.
*   **Start (Cross):** Feet cross or come very close (Curtsy).
    *   *Threshold:* `LegDistance < 0.35 * ShoulderWidth`.
*   **End (Wide):** Lateral hop to wide stance.
    *   *Threshold:* `LegDistance > 0.8 * ShoulderWidth`.
*   **Feedback:** "Hop & Cross!", "Good Skate!".

### 7. Butt Kicks
*   **Logic:** Heel lift towards glutes.
*   **Rep Count:** Ankle rises high towards hip magnitude.
    *   *Threshold:* `Ankle.Y < Knee.Y + (ThighLen * 0.2)` (Heel rises significantly).
*   **Reset:** Foot returns to ground.
    *   *Threshold:* `Ankle.Y > Knee.Y + (ThighLen * 0.8)`.
*   **Feedback:** "Heels to Glutes!", "Switch!".

### 8. Tuck Jumps
*   **Logic:** Simultaneous high knee lift in air.
*   **Rep Count:** Both knees rise above hips.
    *   *Threshold:* `LeftKnee.Y < Hip.Y` AND `RightKnee.Y < Hip.Y`.
*   **Feedback:** "Knees to Chest!", "Land Softly!".

### 9. Plank Jacks
*   **Logic:** Horizontal Jumping Jacks (Plank position).
*   **Out:** Legs spread wide.
    *   *Threshold:* `LegWidth > 1.3 * ShoulderWidth`.
*   **In:** Legs close.
    *   *Threshold:* `LegWidth < 1.1 * ShoulderWidth`.
*   **Feedback:** "Jump!", "In!".

### 10. Sprint in Place
*   **Logic:** Similar to High Knees but faster cooldowns and strictly checks rapid alternating movement.
*   **Threshold:** Same as High Knees (`Knee.Y < Hip.Y + 25`).
*   **Feedback:** "Fast!", "Knees Up!".

---

## 💪 Muscle Building / Strength

### 11. Push-ups
*   **Logic:** Elbow angle tracking.
*   **Down:** Deep elbow flexion.
    *   *Threshold:* `ElbowAngle < 140°`.
*   **Up:** Arm lockout.
    *   *Threshold:* `ElbowAngle > 160°`.
*   **Feedback:** "Go Deeper!", "Straighten Arms!".

### 12. Squats
*   **Logic:** Hip depth relative to knees.
*   **Down (Parallel):** Hip crease aligns with knee.
    *   *Threshold:* `Knee.Y - Hip.Y < 10` (pixels).
*   **Up (Standing):** Hips rise well above knees.
    *   *Threshold:* `Knee.Y - Hip.Y > 40`.
*   **Feedback:** "Squat Down", "Drive Up!".

### 13. Lunges
*   **Logic:** Hips dropping relative to standing height.
*   **Start:** Auto-calibrates "Standing Y".
*   **Down:** Hip drops significantly.
    *   *Threshold:* `DropDistance > TorsoLength * 0.2`.
*   **Up:** Return to near starting height.
    *   *Threshold:* `DropDistance < TorsoLength * 0.5`.
*   **Feedback:** "Step Down", "Drive Up!".

### 14. Glute Bridges
*   **Logic:** Straight line from Shoulder to Knee.
*   **Up (Bridge):** Hips extended linearly.
    *   *Threshold:* `BodyAngle > 165°`.
*   **Down:** Hips flexed.
    *   *Feedback:* "Squeeze!", "Lift Hips".

### 15. Calf Raises
*   **Logic:** Vertical rise of Head/Shoulders.
*   **Up (Raise):** Body rises above baseline.
    *   *Threshold:* `RiseAmount > TorsoLength * 0.08` (Approx 8% height increase).
*   **Down:** Return to baseline.
*   **Feedback:** "Raise Heels", "Hold!".

### 16. Dips
*   **Logic:** Elbow Flexion (Similar to Pushups but for upright torso).
*   **Down:** Elbow bend per side.
    *   *Threshold:* `ElbowAngle < 100°`.
*   **Up:** Lockout.
    *   *Threshold:* `ElbowAngle > 160°`.
*   **Feedback:** "Dip Down", "Drive Up!".

### 17. Pull-ups
*   **Logic:** Nose position relative to Wrists.
*   **Up:** Nose rises ABOVE wrist line.
    *   *Threshold:* `Nose.Y < Wrist.Y`.
*   **Down:** Arms fully extended.
    *   *Threshold:* `ElbowAngle > 150°`.
*   **Feedback:** "Pull Up!", "Show Hands".

---

## 🧱 Core & Statics

### 18. Plank
*   **Logic:** Static hold with linearity check.
*   **Requirement:** Body (Shoulder-Hip-Knee) must be straight AND Horizontal.
    *   *Linearity:* `BodyAngle > 160°`.
    *   *Horizontal:* `|Shoulder.Y - Hip.Y| < 100`.
*   **Feedback:** "Straighten Back!", "Get Down!" (if standing).

### 19. Crunches
*   **Logic:** Torso flexion (Shoulder-Hip-Knee angle).
*   **Up (Crunch):** Shoulders curl towards knees.
    *   *Threshold:* `TorsoAngle < 135°`.
*   **Down:** Flat.
    *   *Threshold:* `TorsoAngle > 135°`.
*   **Feedback:** "Crunch Up", "Squeeze".

### 20. Bicycle Crunches
*   **Logic:** Similar to Mountain Climbers (Knees driving in).
*   **Rep Count:** Alternating knee nearing chest.
*   **Feedback:** "Drive Knees!".

### 21. Leg Raises
*   **Logic:** Hip flexion (Legs lifting) while lying flat.
*   **Up:** Legs vertical approx 90 deg.
    *   *Threshold:* `HipAngle < 130°`.
*   **Down:** Legs flat.
    *   *Threshold:* `HipAngle > 160°`.
*   **Safety:** Checks if user is lying down (`|Shoulder.Y - Hip.Y| < 150`).
*   **Feedback:** "Lift Legs", "Lower Slowly".

### 22. Side Plank
*   **Logic:** Linear body from side view.
*   **Requirement:** Straight body `Angle > 160°` AND Horizontal orientation `|Shoulder.Y - Ankle.Y| < 200`.
*   **Feedback:** "Lift Hips!", "Straighten Body".

### 23. Superman Holds
*   **Logic:** Prone arch validation.
*   **Requirement:** Hands and Feet HIGHER (smaller Y) than Hips.
    *   *Threshold:* `Hip.Y > Shoulder.Y + 20` AND `Hip.Y > Ankle.Y + 20`.
*   **Feedback:** "Lift Chest!", "Lift Legs!".

### 24. Wall Sits
*   **Logic:** Static hold with parallel thighs.
*   **Requirement:** Thighs horizontal.
    *   *Threshold:* `|Hip.Y - Knee.Y| < 50`.
*   **Feedback:** "Sit Lower!", "Hold Parallel!".

### 25. Hollow Body Holds
*   **Logic:** Static hold, similar to Superman but supine (Logic implementation reuses StaticHold base, relying on user maintaining posture, or checks Leg Raise static hold logic).

### 26. L-Sits
*   **Logic:** 90-degree Hip Angle + Horizontal Legs.
*   **Requirement:**
    1.  `HipAngle > 70°` AND `HipAngle < 110°`.
    2.  `|Hip.Y - Ankle.Y| < 100` (Legs straight out).
*   **Feedback:** "Lift Legs!", "Straighten Legs!".

### 27. Nordic Curls
*   **Logic:** Controlled forward lean from kneeling.
*   **Start:** Upright torso.
*   **Lean:** Torso angle deviates from vertical.
    *   *Threshold:* `LeanAngle > 30°` (from vertical).
*   **Return:** Torso returns vertical.
    *   *Threshold:* `LeanAngle < 15°`.
*   **Feedback:** "Control Fall!", "Lean Forward".

### 28. V-Ups
*   **Logic:** Simultaneous close of 'V' shape.
*   **Peak:** Hip Angle acute AND Hands touching feet.
    *   *Threshold:* `HipAngle < 110°` AND `HandToFootDist < TorsoLen * 0.5`.
*   **Flat:** Body extends.
    *   *Threshold:* `HipAngle > 150°`.
*   **Feedback:** "Reach for Toes!", "Lower Slowly".

---

## 📶 Offline & Offline-First Strategy

The HyperPulseX application is designed with an **Offline-First Architecture**, ensuring full functionality even without an active internet connection.

### 1. Exercise Library & Assets
*   **Fully Offline:** All 28 exercises, including their instructional GIFs and Evaluation Logic (AI models), are bundled directly within the application assets.
*   **No Streaming:** Users do not need to download exercises or stream video. Everything is pre-loaded on the device.
*   **Local Fallback:** The `SyncService` attempts to fetch updates from the cloud but automatically falls back to `LocalExerciseData` if the network is unavailable.

### 2. Workout Tracking & History
*   **Local Database:** Every completed workout is immediately saved to a secure local SQLite database `hyperpulsex.db`.
*   **Sync Strategy:**
    *   **Save:** Application saves to Local DB first (0ms latency).
    *   **Push:** Application attempts to push the record to the Cloud in the background.
    *   **Fail-Safe:** If the push fails (Offline), the data remains safe locally. The app manages synchronization automatically when connectivity restores.

### 3. Authentication
*   **Existing Users:** Login is supported offline using locally cached credentials.
*   **Admin Access:** The default local admin profile allows immediate access and testing without any server connection.
*   **Registration:** New account creation is the only feature that optimally requires a connection to ensure global username uniqueness, though local profile creation is supported.

---

## 🛠️ Technology Stack

HyperPulseX leverages a modern, high-performance tech stack optimized for real-time AI processing on mobile devices.

### Frontend (Mobile App)
*   **Framework:** Flutter (Dart) - Cross-platform (Android/iOS)
*   **AI Engine:** Google ML Kit (Pose Detection) - Runs locally on-device using Neural Networks API (NNAPI) / GPU Delegates.
*   **State Management:** Native Flutter State Management (`setState`, `InheritedWidget`).
*   **Local Database:** `sqflite` (SQLite) - For robust local storage of user profiles and workout history.
*   **Networking:** `http` - For REST API communication with the backend.

### Backend (Cloud API)
*   **Runtime:** Node.js
*   **Framework:** Express.js
*   **Database:** MongoDB (via Mongoose ODM) - Scalable NoSQL storage for global user data.
*   **Authentication:** Custom Token/Session based (REST API).

---

## ⭐ Scoring & Rating System

The application uses a gamified scoring system to motivate users and track granular progress.

### 1. Rep counting
*   A repetition is only counted if the user completes a **Full Range of Motion (ROM)**.
*   **State Machine:**
    *   `Neutral`: Starting position.
    *   `Eccentric/Concentric`: Movement phase.
    *   `Top/Bottom`: Peak contraction/extension.
    *   **Trigger:** Rep count increments only when returning from Peak State to Neutral State, enforcing complete form.

### 2. Accuracy Rating
*   Currently, the system enforces **Strict thresholds**.
*   Unlike loose apps that guess, HyperPulseX counts a rep as **100% Valid** or **0% Invalid**.
*   **Accuracy Score:** Currently defaults to 100% for completed reps, as "bad reps" are simply not counted. Future updates will introduce "Form Quality" scores (e.g., 80% stable).

### 3. Total Score (XP)
*   For every successfully completed repetition, the user gains **XP Points**.
*   **Points Calculation:** `Score = Reps * DifficultyMultiplier`.
*   This score accumulates in the User Profile (`total_score`) and is synchronized with the Leaderboard.

---

## 📂 Project Structure & File Description

### Frontend (`frontend/lib`)

| Path | Description |
| :--- | :--- |
| `main.dart` | **Entry Point.** Initializes Flutter, App Theme, and Routing. |
| **`logic/`** | **Core Logic Layer** |
| `exercise_evaluator.dart` | **The AI Brain.** Contains the `ExerciseEvaluator` class and specific logic classes (e.g., `PushupEvaluator`, `SquatEvaluator`) for all 28 exercises. |
| `pose_utils.dart` | **Math Utilities.** Helper functions for calculating angles (Cosine Rule), distances, and smoothing pose streams. |
| `sync_service.dart` | **Network Layer.** Handles data synchronization between Local DB and Cloud API. |
| `voice_coach.dart` | **TTS Engine.** Provides real-time audio feedback ("Lower your hips!", "Good Job!") during workouts. |
| **`data/`** | **Data Layer** |
| `database_helper.dart` | **Local Storage.** Manages SQLite connection, schema creation (tables: `users`, `workouts`), and CRUD operations. |
| `local_exercise_data.dart` | **Offline Data.** Hardcoded backup of all 28 exercises with descriptions, steps, and asset paths. |
| **`ui/`** | **User Interface** |
| `screens/dashboard/` | Main app screens (`HomeScreen`, `ExercisesScreen`, `ProfileScreen`) post-login. |
| `screens/workout/` | Active workout screens (`ExercisePreviewScreen`, `WorkoutScreen`). |
| `screens/auth/` | Authentication screens (`LoginScreen`, `RegisterScreen`). |

### Backend (`backend/`)

| Path | Description |
| :--- | :--- |
| `server.js` | **Server Entry.** Starts the Express server, connects to MongoDB, and defines API Routes. |
| `seed.js` | **Database Seeder.** Utility script to populate the Cloud Database with the standard set of 28 exercises and Admin accounts. |
| **`models/`** | **Database Schemas** |
| `User.js` | Mongoose schema for User profiles. |
| `Exercise.js` | Mongoose schema for Exercise definitions. |
