# Implementation Plan: Configurable Server Connection Settings

**Branch**: `004-configurable-api-url` | **Date**: 2026-10-12 | **Spec**: [spec.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-mobile/specs/004-configurable-api-url/spec.md)  
**Input**: Feature specification from `specs/004-configurable-api-url/spec.md`

## Summary

Add a **Server Connection Settings** modal bottom sheet accessible from both the unauthenticated screens (`DemoLoginScreen`, `LoginScreen`) and the authenticated portal header (`ResidentHeader`) so users on physical devices (such as a Google Pixel phone on the same Wi-Fi as a MacBook) can modify, test, persist, and reset the microservices base URL at runtime. Leverage the existing Flutter + Riverpod + Hive + `http` stack and ensure 100% of microservice repositories and media URL resolutions dynamically use the configured base URL with in-place data refresh.

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter 3.44+  
**Primary Dependencies**: `flutter_riverpod` (`^2.5.1`), `hive` (`^2.2.3`), `hive_flutter` (`^1.1.0`), `http` (`^1.6.0`), `go_router` (`^17.2.2`), `google_fonts` (`^8.0.2`)  
**Storage**: Local device persistence via `hive_flutter` (`app_settings` box, key `custom_base_url`) with automatic in-memory fallback for test environments  
**Testing**: `flutter_test` (unit tests for URL normalization, validation, persistence, and all-service propagation + widget tests for the Settings modal on Welcome, Login, and Portal screens)  
**Target Platform**: Android 12+ (Google Pixel physical device & emulator) and iOS 15+  
**Project Type**: Mobile Application (Flutter)  
**Performance Goals**: Instant reactive URL propagation across all Riverpod providers (<50ms), connection test feedback within 4 seconds (<5s target)  
**Constraints**: Zero new package dependencies; preserve existing auth session token and current screen state (in-place refresh) when switching URLs; maintain 48x48dp minimum touch targets and calming `#F2FAF5` palette  
**Scale/Scope**: 1 reusable modal bottom sheet widget (`ServerSettingsModal`), 3 entry points (`DemoLoginScreen`, `LoginScreen`, `ResidentHeader`), centralized `AppConfig` + `ApiClient` + 9 HTTP repository integrations (`Auth`, `Resident`, `CareTasks`, `HealthVitals`, `Meal`, `Mood`, `Memory`, `Montessori`, `AiAssistant`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I: Self-Contained Feature Architecture**: Clean separation between `core/config` (`AppConfig`, `AppConfigNotifier`, `AppConfigStorage`), `core/network` (`ApiClient`), and `presentation/shared` (`ServerSettingsModal`). (**PASS**)
- **Principle II: Microservice Pluggability**: All 9 microservice HTTP repositories (`HttpAuthRepository`, `HttpResidentRepository`, `HttpCareTasksRepository`, `HttpHealthVitalsRepository`, `HttpMealRepository`, `HttpMoodRepository`, `HttpMemoryRepository`, `HttpMontessoriRepository`, `HttpAiAssistantRepository`) watch `apiClientProvider`, which reactively binds to `appConfigProvider.apiBaseUrl`. (**PASS**)
- **Principle III: Test-First & Platform Coverage**: Comprehensive unit and widget tests covering shorthand/full URL normalization, persistence, connection testing, and reactive propagation across all repositories. (**PASS**)
- **Principle IV: Environment-Aware Configuration**: Extends `AppConfig` to layer persisted runtime custom base URLs on top of compile-time `--dart-define` and platform defaults (`10.0.2.2` vs `localhost`), with one-tap "Reset to Default". (**PASS**)

## Project Structure

### Documentation (this feature)

```text
specs/004-configurable-api-url/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Phase 0 architecture & technical decisions
├── data-model.md        # Phase 1 entities, normalization rules, and state transitions
├── quickstart.md        # Phase 1 step-by-step Wi-Fi setup guide (Google Pixel + MacBook)
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── contracts/
    └── settings-contract.json # Storage & connection probe schema
```

### Source Code (repository root)

```text
lib/
├── main.dart                                      # Initialize Hive & AppConfigStorage before runApp
├── core/
│   ├── config/
│   │   └── app_config.dart                        # URL normalization, validation, Hive persistence, synchronized service URLs
│   └── network/
│       └── api_client.dart                        # Preserve authToken/institutionId across baseUrl updates + connection probe
├── data/
│   └── repositories/
│       ├── auth_repository.dart                   # Watches appConfigProvider & apiClientProvider
│       ├── resident_repository.dart               # Watches appConfigProvider & apiClientProvider
│       ├── care_tasks_repository.dart             # Watches appConfigProvider & apiClientProvider
│       ├── health_vitals_repository.dart          # Watches appConfigProvider & apiClientProvider
│       ├── meal_repository.dart                   # Watches appConfigProvider & apiClientProvider
│       ├── mood_repository.dart                   # Watches appConfigProvider & apiClientProvider
│       ├── memory_repository.dart                 # Watches appConfigProvider & apiClientProvider
│       ├── montessori_repository.dart             # Watches appConfigProvider & apiClientProvider
│       └── ai_assistant_repository.dart           # Watches appConfigProvider & apiClientProvider
└── presentation/
    ├── auth/
    │   ├── auth_provider.dart                     # Re-fetches demo accounts on baseUrl change
    │   ├── demo_login_screen.dart                 # Adds Settings gear icon button to open ServerSettingsModal
    │   └── login_screen.dart                      # Adds Settings gear icon button in AppBar to open ServerSettingsModal
    ├── family_portal/
    │   └── resident_provider.dart                 # Preserves selected resident ID & refreshes in-place on repo rebuild
    └── shared/
        ├── resident_header.dart                   # Adds Settings gear icon button next to Switch button
        └── server_settings_modal.dart             # New modal bottom sheet for editing, testing, saving, and resetting Base URL

test/
├── unit/
│   └── config_test.dart                           # Unit tests for shorthand normalization, validation, persistence, and all-repo URL propagation
└── widget/
    └── server_settings_modal_test.dart            # Widget tests for opening modal, validating input, testing connection, saving, and resetting
```

**Structure Decision**: Reuse the existing feature-layered Flutter architecture in `elderly-mobile`. No new third-party dependencies are introduced.

## Implementation Architecture Details

1. **Unified Microservice Base URL Synchronization (`lib/core/config/app_config.dart`)**:
   - Add `AppConfig.normalizeBaseUrl(String input)` and `AppConfig.validateBaseUrl(String input)` supporting both full URLs (`http://192.168.1.50:8080/api/v1`) and smart shorthand (`192.168.1.50` or `192.168.1.50:8080` → `http://192.168.1.50:8080/api/v1`).
   - Add `AppConfigStorage` wrapper around Hive box `app_settings` (with safe in-memory fallback when Hive is not initialized in tests).
   - Ensure `AppConfigNotifier.setCustomBaseUrl(String url)` and `AppConfigNotifier.resetBaseUrl()` update `apiBaseUrl`, `authServiceUrl`, `careServiceUrl`, and `aiServiceUrl` in unison and persist to `AppConfigStorage`.
   - Ensure `mealRepositoryProvider`, `memoryRepositoryProvider`, `moodRepositoryProvider`, and `aiAssistantRepositoryProvider` also respect `appConfigProvider` consistently with `careTasksRepositoryProvider`, `healthVitalsRepositoryProvider`, `montessoriRepositoryProvider`, `residentRepositoryProvider`, and `authRepositoryProvider`.

2. **Session-Preserving `ApiClient` & In-Place Refresh (`lib/core/network/api_client.dart` & `resident_provider.dart`)**:
   - Maintain active `authToken` and `activeInstitutionId` across `apiClientProvider` rebuilds when `appConfigProvider.apiBaseUrl` changes so signed-in users remain authenticated.
   - Add `Future<ConnectionTestResult> testConnection()` on `ApiClient` (or helper) that probes `GET <baseUrl>/auth/demo-accounts` with a 4-second timeout.
   - Update `ResidentNotifier` so that when `residentRepositoryProvider` rebuilds on a base URL change, the currently selected resident ID is preserved and immediately re-fetched from the new server (`selectById(currentId)`), triggering in-place refresh across the portal.

3. **Settings Modal Bottom Sheet (`lib/presentation/shared/server_settings_modal.dart`)**:
   - Follows the exact visual style of `ResidentSwitchModal` (rounded top corners, drag handle, calming green theme).
   - Displays current active Base URL and badge indicating whether `Custom Override` or `Default` is active.
   - Provides a text field pre-filled with the current URL, helper hint (`e.g. 192.168.1.50 or http://192.168.1.50:8080/api/v1`), live preview of normalized URL, inline validation errors, a **Test Connection** button with status banner, a **Reset to Default** button, and a **Save & Apply** primary button.
   - Accessible from:
     - `DemoLoginScreen` (top-right Settings icon button)
     - `LoginScreen` (`AppBar` actions Settings icon button)
     - `ResidentHeader` (icon button beside the resident `Switch` button)

## Complexity Tracking

No constitution violations. Zero new dependencies added.
