let's avoid to to test on simple UI, like buttons and components, only logic. and heavy features logics
App language is french
The app is connected to a real NestJS backend — no mock data, all repositories call the API
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

- **State management**: [GetX](https://pub.dev/packages/get) — controllers, bindings, and named routes.
- **Navigation**: `GetMaterialApp` with named routes (`lib/core/routes/app_routes.dart`, `app_pages.dart`).
- **Feature-based folders** under `lib/features/`: `auth`, `onboarding`, `home`, `shell`, `quests`, `social`, `profile`, `payments`, `notifications`, `history`. Each typically has `views/`, `controllers/`, `models/`, `repositories/`, `services/`.
- **Shared code** under `lib/core/`: `api/` (HTTP client), `bindings/`, `routes/`, `services/`, `theme/`, `utils/`, `widgets/`.

## Backend

The app is connected to a real backend (NestJS + Prisma + PostgreSQL, with Row-Level Security). Every feature's `repositories/*.dart` calls the API via `lib/core/api/api_client.dart` — there is no in-memory/mock data left in the app. Auth, profile, quests, social (allies/invitations/validation), payments (Wave), and notifications are all backend-connected.

`API_BASE_URL` and `GOOGLE_SERVER_CLIENT_ID` are supplied via `--dart-define` at build/run time (see `.vscode/launch.json` for local/dev configs).

The backend repo lives separately at `axiom-backend` (NestJS + Prisma + Swagger docs); see its own `DEPLOY.md` for deployment.
