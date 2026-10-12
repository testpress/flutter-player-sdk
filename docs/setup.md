# Development Setup

Internal guide for setting up and working on `tpstreams_player_sdk`.

---

## 1. Prerequisites

* **Flutter SDK**: `>= 3.3.0` (CI runs stable `3.44.0`)
* **Dart SDK**: `>= 3.0.6 < 4.0.0`
* **Xcode / Android Studio**: With simulators/emulators configured.

---

## 2. Install Dependencies

```bash
# Fetch root SDK dependencies
flutter pub get

# Fetch example project dependencies
cd example
flutter pub get
cd ..
```

---

## 3. Platform Bridge Code Generation (Pigeon)

The SDK uses Pigeon (`^22.7.1`) for typed platform channel communication between Flutter, Android (Kotlin), and iOS (Swift). Contract definitions live in `pigeons/`.

When modifying any pigeon definition, run:

```bash
for file in pigeons/*.dart; do
  dart run pigeon --input "$file"
done
```

### Generated Files:
* **Dart**: `lib/generated/`
* **Android (Kotlin)**: `android/src/main/kotlin/com/tpstreams/tpstreams_player_sdk/generated/`
* **iOS (Swift)**: `ios/tpstreams_player_sdk/Sources/tpstreams_player_sdk/generated/`

Always commit the generated files alongside the pigeon definition changes.

---

## 4. Running the Example App

```bash
cd example
flutter run
```

To run on a specific device:
```bash
flutter devices
flutter run -d <device_id>
```

---

## 5. Code Quality & Testing

Run these checks before committing:

```bash
# Lint & static analysis
flutter analyze

# Unit tests
flutter test
```
