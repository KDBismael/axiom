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

## Backend — scope and goals

The Flutter app currently runs entirely on in-memory mock data (`lib/features/*/repositories/`). A real backend is planned. Stack: **NestJS + Prisma ORM + PostgreSQL (with Row-Level Security) + Swagger** for API docs. Simple architecture, single dev, TDD (test → implement → test passes).

### Goals

- Replace every mocked repository (`QuestRepository`, `SocialRepository`, `OnboardingService`, profile/auth stubs) with real persistence, scoped to a real logged-in user via Postgres RLS.
- Ship domain-by-domain, starting with whatever unblocks the others: Identity & Sessions is the foundation everything else depends on (quests, profile, social, payments all need a real `userId`).
- Keep the API documented via Swagger as it grows so the Flutter client integration stays straightforward for a single dev.

### Scope (by domain — see full audit for detail)

1. **Identity & Sessions** — registration/login, password hashing, JWT/session issuance, OAuth (Google/Apple), logout. Currently: no backend, no persisted user, no logout.
2. **Profile & Settings** — profile update endpoint, avatar/file upload, notification/privacy/language preferences. Currently: edits only show a SnackBar, nothing persists.
3. **Quests** — quest CRUD with real ownership, check-ins with per-day dedup + derived streaks, evidence upload for proof-of-completion, ally-invite-on-a-quest workflow, stakes ledger, scheduled deadline/payout jobs. Currently: hardcoded in-memory list, no persistence, no enforcement.
4. **Payments (Mobile Money, XOF)** — real integration with Orange Money, MTN MoMo, Moov Money, Wave (Côte d'Ivoire): charge initiation, OTP verification, webhook handling, reconciliation against the stakes ledger. Currently: checkout UI only, no processing.
5. **Social — Ally Invitations & Validation** — real Users/Allies relationship model, invite tokens + deep links, proof-submission with photo upload, validation decisions that feed back into quest/stake status, push notifications for invite/validation events. Currently: single hardcoded invitation, no relationship graph, no notifications.

### Cross-cutting

- Shared file/photo storage service (avatars, quest evidence, ally-validation proof).
- Push notification service (quest deadlines, social invites/validations).
- Postgres RLS policies scoping every table to the authenticated user once Identity & Sessions exists.

Full domain-by-domain audit (what's mocked vs. what a real backend replaces): `/Users/MACPRO/.claude/plans/lets-implement-this-design-witty-bubble.md`.
