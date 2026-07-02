let's avoid to to test on simple UI, like buttons and components, only logic. and heavy features logics
App language is french
we are using mock data just to make it work for now. we will add backend later
money is in XOF
Don't run simulator for verifications, just test passes it's okay
this is a flutter app don't make ios native assumptions

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Run linter (flutter_lints)
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter build ios        # Build iOS
```

## Architecture

This is a fresh Flutter starter project. Currently it contains only the default counter demo in `lib/main.dart` with no additional architecture beyond Flutter's built-in widget tree.

- **State management**: `setState()` only — no Provider, Riverpod, or BLoC yet
- **Navigation**: None — single-page app
- **Dependencies**: Only `cupertino_icons`; no networking, database, or routing packages

As the app grows, organize new code under `lib/` using feature-based folders (e.g. `lib/features/`, `lib/core/`).
