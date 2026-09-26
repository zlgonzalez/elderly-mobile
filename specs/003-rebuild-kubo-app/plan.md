# Implementation Plan: Kubo North Family Care App Rebuild

**Branch**: `003-rebuild-kubo-app` | **Date**: 2026-09-26 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/003-rebuild-kubo-app/spec.md`

## Summary

Rebuild the Kubo North mobile application using Flutter, implementing all 7 screens, dialogs, and interactions defined in Figma design `wMzyM9baD4XT5PLTu2sijV` ("Kubo North (Family only)"). The implementation features Riverpod-powered swappable data providers pre-loaded with rich mock fixtures (Margaret Thompson, Robert Chen, Dorothy Williams, Nurse Jane, 35+ item Food Library, Montessori activities), explicit in-code tagging (`[MICROSERVICE_INTEGRATION_POINT]`) for future microservices, centralized runtime configuration (`AppConfig`), a root `Makefile`, and dedicated automated tests for both iOS and Android platforms.

## Technical Context

**Language/Version**: Dart 3.12+ / Flutter 3.44+  
**Primary Dependencies**: `flutter_riverpod` (^2.5.1), `go_router` (^17.2.2), `hive_flutter` (^1.1.0), `google_fonts` (^8.0.2), `http` (^1.6.0)  
**Storage**: Hive local storage (encrypted boxes) with in-memory mock repository layer and "Reset to Demo" support  
**Testing**: `flutter_test` with unit tests and platform-aware widget tests for both iOS (`CupertinoApp` / `TargetPlatform.iOS`) and Android (`MaterialApp` / `TargetPlatform.android`)  
**Target Platform**: iOS 15+ and Android 12+ (Mobile-optimized ~390px to ~401px viewport with responsive centering for tablets/web)  
**Project Type**: Mobile Application  
**Performance Goals**: 60 fps transitions, <500ms screen cold-start, zero-latency local offline responses  
**Constraints**: Calming light palette (`#F2FAF5`), minimum 48x48 point touch targets, WCAG 2.1 AA accessibility contrast  
**Scale/Scope**: 7 primary screens/tabs, 5 interactive modal sheets, ~35-item food database, contextual AI assistant drawer  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I: Self-Contained Feature Architecture**: Clean separation between Presentation, Domain entities, and Data repositories. (PASS)
- **Principle II: Microservice Pluggability**: Every data domain exposes an abstract interface with mock providers and tagged integration points (`[MICROSERVICE_INTEGRATION_POINT]`). (PASS)
- **Principle III: Test-First & Platform Coverage**: Dedicated test suites verifying iOS Cupertino interactions and Android Material behaviors. (PASS)
- **Principle IV: Environment-Aware Configuration**: Centralized `AppConfig` supporting `--dart-define` for microservice URLs and mock toggle. (PASS)

## Project Structure

### Documentation (this feature)

```text
specs/003-rebuild-kubo-app/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Technical decisions and architecture choices
├── data-model.md        # Entities, attributes, and relationships
├── quickstart.md        # Developer setup, make commands, and microservice guidelines
└── contracts/           # Microservice JSON contract schemas
    ├── resident-contract.json
    ├── care-tasks-contract.json
    ├── health-vitals-contract.json
    ├── meal-tracker-contract.json
    ├── memory-box-contract.json
    ├── ai-assistant-contract.json
    └── config-contract.json
```

### Source Code (repository layout)

```text
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          # Centralized config (API Base URL, useMockData flag)
│   ├── network/
│   │   └── api_client.dart          # HTTP client wrapper with microservice auth headers
│   ├── router/
│   │   └── app_router.dart          # GoRouter definitions for all 7 screens & demo flow
│   └── theme/
│       ├── app_colors.dart          # Design tokens (#F2FAF5 base, restorative greens)
│       └── app_theme.dart           # Typography, button themes, 48x48 touch targets
├── data/
│   ├── fixtures/
│   │   ├── resident_fixtures.dart   # Margaret Thompson, Robert Chen, Dorothy Williams
│   │   ├── food_fixtures.dart       # 35+ item nutritional library
│   │   ├── task_fixtures.dart       # Today's & upcoming routines
│   │   └── memory_fixtures.dart     # Photos, stories, letters, videos
│   ├── models/                      # JSON DTOs matching /contracts/
│   └── repositories/
│       ├── resident_repository.dart # Abstract + Mock with [MICROSERVICE_INTEGRATION_POINT]
│       ├── care_tasks_repository.dart
│       ├── health_vitals_repository.dart
│       ├── meal_repository.dart
│       ├── memory_repository.dart
│       └── ai_assistant_repository.dart
├── domain/
│   └── entities/                    # Pure Dart entities from data-model.md
├── presentation/
│   ├── auth/                        # Demo profile switcher & credentials sign-in
│   ├── family_portal/               # Dashboard, daily snapshot, recent mood
│   ├── their_story/                 # Life portrait, milestones (1965-2018), teaching legacy
│   ├── memory_box/                  # Gallery, filter, Add Memory sheet (dual input)
│   ├── care_tasks/                  # Today's schedule, start/complete/skip, Add Task sheet
│   ├── health_vitals/               # Vitals form, Meal Tracker, Food Library search, Custom Food
│   ├── activity_guide/              # Montessori guide, category counts, facilitation steps
│   ├── ai_assistant/                # Contextual Ask Kubo AI drawer across all screens
│   └── shared/                      # Header (resident info & Switch), bottom nav, buttons
└── main.dart

test/
├── unit/
│   ├── config_test.dart             # Configuration & environment variable tests
│   ├── nutrient_calculation_test.dart
│   └── repository_mock_test.dart    # Mock repository state transitions
├── platform/
│   ├── ios_test.dart                # iOS Cupertino modal sheets & navigation tests
│   └── android_test.dart            # Android Material elevation & back-button tests
└── widget/
    ├── demo_login_test.dart
    ├── family_portal_test.dart
    ├── memory_box_test.dart
    ├── care_tasks_test.dart
    ├── health_vitals_test.dart
    └── activity_guide_test.dart

Makefile                             # Root developer commands (run, test-ios, test-android)
```

**Structure Decision**: Clean feature-layered architecture with domain separation. Every repository has dual implementations (`Mock*Repository` and `Http*Repository`) gated by `AppConfig.useMockData`. Every HTTP integration point contains standardized comments and tags (`// [MICROSERVICE_INTEGRATION_POINT]: <Service> - <Action>`) so backend teams can integrate microservices effortlessly.

## Complexity Tracking

| Mechanism | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| **Swappable Mock Data Providers** | Allows 100% offline testing of all Figma flows today while enabling seamless zero-code-change microservice connections later. | Hardcoding mock strings in widgets violates clean architecture and requires massive rewrites when backend is ready. |
| **Centralized AppConfig (`--dart-define`)** | Configures API base URLs and mock toggles cleanly for CI/CD, local dev, staging, and prod. | Hardcoded URLs break multi-environment deployments. |
| **Dual Platform Test Suite (`test-ios` & `test-android`)** | Verifies UI fidelity and interaction behaviors on both Apple and Google platforms. | Generic test suites miss platform-specific navigation and modal layout bugs. |
