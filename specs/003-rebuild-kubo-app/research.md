# Implementation Research: Kubo North Family Care App Rebuild

**Feature**: `003-rebuild-kubo-app`  
**Date**: 2026-09-26  
**Status**: Completed  

---

## 1. Technical Decisions & Architectural Choices

### Decision 1: Mobile Framework & Application Architecture
- **Decision**: Flutter (Dart 3.12.x / Flutter 3.44.x) utilizing a feature-first clean architecture separating Presentation (Widgets, Riverpod StateNotifiers/Notifiers), Domain (Entities, Repository Interfaces), and Data (Local Mock Fixtures, Hive persistence, HTTP Microservice Client implementations).
- **Rationale**: The project already contains a Flutter project setup with dependencies (`flutter_riverpod`, `go_router`, `hive_flutter`, `google_fonts`, `http`). Flutter delivers unified cross-platform rendering for both iOS and Android from a single codebase while faithfully honoring the Figma typography and layout dimensions (~401px width standard).
- **Alternatives Considered**: React Native (requires completely re-initializing project, losing existing Flutter scaffolding) or pure Web SPA (fails iOS/Android native mobile requirements).

---

### Decision 2: State Management & Mockable Data Providers
- **Decision**: Riverpod 2.x (`flutter_riverpod`) with abstract repository interfaces and Swappable Providers.
  - Every domain feature exposes an abstract repository (e.g., `ResidentRepository`, `CareTasksRepository`, `HealthVitalsRepository`, `MealRepository`, `MemoryRepository`, `AiAssistantRepository`).
  - By default, providers instantiate `Mock*Repository` implementations pre-loaded with the exact data fixtures from Figma design `wMzyM9baD4XT5PLTu2sijV` (Margaret Thompson, Robert Chen, Dorothy Williams, Nurse Jane, 35+ item food library, Montessori activities).
  - A real `Http*Repository` implementation sits parallel, ready to communicate with backend microservices once deployed.
  - A global `useMockDataProvider` or `AppConfig.useMockData` flag automatically determines which implementation is wired to the presentation layer.
- **Rationale**: Allows 100% of the UI, state transitions, validation, and user journeys to be fully tested and demoed offline today, while guaranteeing zero frontend refactoring when backend microservices are ready.
- **Alternatives Considered**: Bloc/Cubit (heavier boilerplate, requires complex event mapping) or simple `ChangeNotifier` (lacks dependency injection, difficult to mock cleanly in unit tests).

---

### Decision 3: Microservice Integration Tagging & Pluggability
- **Decision**: Establish a standardized code tagging standard across all data layer and provider files:
  - `// [MICROSERVICE_INTEGRATION_POINT]: <Service Name> - <Endpoint/Contract description>`
  - `// TODO(microservice): Replace mock return with: final response = await apiClient.get('/api/v1/...')`
  - All mock repositories will feature commented-out HTTP microservice calls directly matching the JSON contracts in `/contracts/`.
- **Rationale**: Developers building the backend microservices can grep `[MICROSERVICE_INTEGRATION_POINT]` across the codebase and immediately see the exact payload formats, endpoints, headers, and response models required.
- **Alternatives Considered**: Ad-hoc TODO comments (hard to parse and automate) or separate integration documentation without in-code anchors.

---

### Decision 4: Centralized Configuration & Environment Variables
- **Decision**: Implement a centralized `AppConfig` singleton / Riverpod provider configured via Dart compile-time environment variables (`--dart-define`) with sensible development fallbacks:
  - `API_BASE_URL` (default: `http://localhost:8080/api/v1`)
  - `AUTH_SERVICE_URL` (default: `http://localhost:8081`)
  - `CARE_SERVICE_URL` (default: `http://localhost:8082`)
  - `AI_SERVICE_URL` (default: `http://localhost:8083`)
  - `VITE_GEMINI_API_KEY` / `GEMINI_API_KEY` (optional for live AI assistant streaming)
  - `USE_MOCK_DATA` (default: `true`, toggled to `false` for live backend)
  - `ENVIRONMENT` (`dev`, `staging`, `prod`)
- **Rationale**: Follows 12-factor application design principles; supports switching between local mock testing, staging servers, and production clusters without rebuilding binary assets.
- **Alternatives Considered**: Hardcoded constant URLs in code (violates security & environment isolation).

---

### Decision 5: Makefile for Development, Testing & Multi-Platform Builds
- **Decision**: Create a comprehensive root `Makefile` exposing developer workflows:
  - `make run`: Run app in debug mode with mock data
  - `make run-prod`: Run app connected to microservices
  - `make test`: Run all unit and widget tests
  - `make test-ios`: Run iOS-specific widget and unit test suite
  - `make test-android`: Run Android-specific widget and unit test suite
  - `make analyze`: Run Flutter analyzer and linter
  - `make clean`: Clean build caches and pub dependencies
  - `make build-apk`: Build Android release APK
  - `make build-ios`: Build iOS archive/bundle
- **Rationale**: Standardizes developer commands across macOS and Linux development environments, making CI/CD integration straightforward.
- **Alternatives Considered**: Manual long `flutter run --dart-define=...` shell commands (error-prone).

---

### Decision 6: Testing Strategy for iOS and Android
- **Decision**: A dual-level testing suite:
  1. **Unit & Repository Tests**: Testing mock data providers, state notifiers, business rules (nutrient calculations, intake percentage scaling, profile switching, error boundaries).
  2. **Platform-Aware Widget Tests**:
     - Testing iOS Cupertino-style modals, bottom sheets, navigation transitions, and typography.
     - Testing Android Material behaviors, ripple effects, back button handling, and responsiveness.
     - Mocking `TargetPlatform.iOS` and `TargetPlatform.android` in widget test harnesses to verify pixel-perfect design rendering on both target operating systems.
- **Rationale**: Ensures feature parity and UI stability across both mobile platforms without needing physical hardware attached for every regression pass.
- **Alternatives Considered**: Testing only generic widgets without platform variations.
