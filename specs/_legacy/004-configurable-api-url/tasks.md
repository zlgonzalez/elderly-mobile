# Tasks: Configurable Server Connection Settings

**Input**: Design documents from `/specs/004-configurable-api-url/`
**Prerequisites**: [plan.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-mobile/specs/004-configurable-api-url/plan.md), [spec.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-mobile/specs/004-configurable-api-url/spec.md), [research.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-mobile/specs/004-configurable-api-url/research.md), [data-model.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-mobile/specs/004-configurable-api-url/data-model.md), [settings-contract.json](file:///Users/zlgonzalez/Documents/code/kubo/elderly-mobile/specs/004-configurable-api-url/contracts/settings-contract.json)

**Tests**: Unit and widget tests included per `plan.md` to verify URL normalization, persistence, connection testing, and 100% microservice repository propagation.

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`US1`, `US2`, `US3`)
- Includes exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize local device storage (`Hive` box `app_settings`) at app startup and verify Android local network HTTP configuration.

- [X] T001 Initialize `Hive.initFlutter()` and `AppConfigStorage.init()` before `runApp` in `lib/main.dart`
- [X] T002 [P] Verify Android cleartext HTTP traffic and internet permissions for local Wi-Fi IPs in `android/app/src/main/AndroidManifest.xml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core `AppConfig`, `AppConfigStorage`, `ApiClient`, and repository wiring that MUST be complete so 100% of microservices use the configured base URL reactively.

**⚠️ CRITICAL**: No user story UI work can begin until this phase is complete.

- [X] T003 Implement `AppConfigStorage` (Hive `app_settings` box persistence with in-memory fallback for tests), `AppConfig.normalizeBaseUrl()`, `AppConfig.validateBaseUrl()`, `customBaseUrl` tracking, and synchronized `apiBaseUrl`/`authServiceUrl`/`careServiceUrl`/`aiServiceUrl` updates in `lib/core/config/app_config.dart`
- [X] T004 Update `ApiClient` and `apiClientProvider` to preserve active `authToken` and `activeInstitutionId` across base URL updates and add `ConnectionTestResult` / `testConnection()` probe (`GET /auth/demo-accounts`) in `lib/core/network/api_client.dart`
- [X] T005 [P] Ensure `mealRepositoryProvider`, `memoryRepositoryProvider`, `moodRepositoryProvider`, and `aiAssistantRepositoryProvider` watch `appConfigProvider` and `apiClientProvider` consistently with all other microservice repositories in `lib/data/repositories/meal_repository.dart`, `lib/data/repositories/memory_repository.dart`, `lib/data/repositories/mood_repository.dart`, and `lib/data/repositories/ai_assistant_repository.dart`

**Checkpoint**: Foundation ready — `appConfigProvider` and `apiClientProvider` persist custom URLs and propagate them across all 9 microservice repositories.

---

## Phase 3: User Story 1 - Configure Custom Server Address from Sign-In Screen (Priority: P1) 🎯 MVP

**Goal**: Allow a user on a physical phone (e.g., Google Pixel on local Wi-Fi) to open the Server Connection Settings modal from the Welcome/Demo Profile screen or Sign-In screen, enter their MacBook's IP or full URL, save it to persistent storage, and immediately load demo accounts and authenticate against that server.

**Independent Test**: Open the app on the Welcome screen (`DemoLoginScreen`) or Sign-In screen (`LoginScreen`), tap the Settings icon button, enter `192.168.1.100` (or `http://192.168.1.100:8080/api/v1`), tap "Save & Apply", and verify `appConfigProvider.apiBaseUrl` updates to `http://192.168.1.100:8080/api/v1`, persists in storage, and reloads `demoAccountsProvider`.

### Implementation for User Story 1

- [X] T006 [US1] Create `ServerSettingsModal` bottom sheet widget displaying active base URL, custom override status badge, URL/IP input field with live normalized preview, and "Save & Apply" action in `lib/presentation/shared/server_settings_modal.dart`
- [X] T007 [P] [US1] Add Settings icon button (`Icons.settings_outlined`) in the top bar of `DemoLoginScreen` that opens `ServerSettingsModal.show(context)` in `lib/presentation/auth/demo_login_screen.dart`
- [X] T008 [P] [US1] Add Settings icon button (`Icons.settings_outlined`) to `AppBar.actions` in `LoginScreen` that opens `ServerSettingsModal.show(context)` in `lib/presentation/auth/login_screen.dart`
- [X] T009 [US1] Ensure `demoAccountsProvider` automatically invalidates/re-fetches when `appConfigProvider` base URL changes in `lib/presentation/auth/auth_provider.dart`

**Checkpoint**: User Story 1 is fully functional and independently testable from the unauthenticated screens.

---

## Phase 4: User Story 2 - Modify or Reset Server Address While Signed In (Priority: P2)

**Goal**: Allow an authenticated user inside the main care portal to open the Settings modal from the portal header, modify the base URL or tap "Reset to Default", and have all active resident and portal data refresh in-place without losing their current screen or session.

**Independent Test**: Sign in to the main portal, tap the Settings icon button in `ResidentHeader`, tap "Reset to Default" (or save a new URL), and verify `appConfigProvider.apiBaseUrl` updates while `residentProvider` and all feature providers refresh in-place for the currently selected resident.

### Implementation for User Story 2

- [X] T010 [US2] Add "Reset to Default" action button in `ServerSettingsModal` that calls `ref.read(appConfigProvider.notifier).resetBaseUrl()` and shows confirmation feedback in `lib/presentation/shared/server_settings_modal.dart`
- [X] T011 [P] [US2] Add Settings icon button (`Icons.settings_outlined`) next to the resident `Switch` button in `ResidentHeader` to open `ServerSettingsModal.show(context)` in `lib/presentation/shared/resident_header.dart`
- [X] T012 [US2] Update `ResidentNotifier` and `residentProvider` to preserve the currently selected resident ID when `residentRepositoryProvider` rebuilds and immediately trigger `selectById()` in-place refresh in `lib/presentation/family_portal/resident_provider.dart`

**Checkpoint**: User Stories 1 and 2 both work independently, supporting seamless URL switching and resetting both before and after sign-in.

---

## Phase 5: User Story 3 - Validate Server URL and Test Connection (Priority: P3)

**Goal**: Provide immediate inline validation for empty/malformed URLs and a "Test Connection" button in `ServerSettingsModal` that verifies reachability of the target server over Wi-Fi within 5 seconds.

**Independent Test**: Open `ServerSettingsModal`, enter an invalid string (e.g., `http://bad host`) to verify saving is blocked with a validation message, then enter a valid IP/URL and tap "Test Connection" to verify the reachability status banner displays success or error feedback.

### Implementation for User Story 3

- [X] T013 [US3] Add inline form validation using `AppConfig.validateBaseUrl()` and interactive "Test Connection" button with loading indicator and reachability result banner (`ConnectionTestResult`) in `lib/presentation/shared/server_settings_modal.dart`

**Checkpoint**: All 3 user stories (`US1`, `US2`, `US3`) are complete and independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Automated unit and widget tests verifying URL normalization, persistence, connection testing, UI modal flows, and 100% microservice repository base URL propagation.

- [X] T014 [P] Add unit tests for `AppConfig.normalizeBaseUrl`, `AppConfig.validateBaseUrl`, `AppConfigStorage` persistence, `resetBaseUrl`, and reactive base URL propagation across all 9 microservice repositories in `test/unit/config_test.dart`
- [X] T015 [P] Add widget tests for `ServerSettingsModal` (opening from `DemoLoginScreen` and `ResidentHeader`, shorthand IP normalization, validation error state, connection test feedback, save, and reset to default) in `test/widget/server_settings_modal_test.dart`
- [X] T016 Run `flutter analyze` and `flutter test` across the test suite to verify zero regressions in `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately (`T001`, `T002`).
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories (`T003` → `T004` → `T005`).
- **User Story 1 (Phase 3 - P1 MVP)**: Depends on Foundational (`T006` → `T007`, `T008`, `T009`).
- **User Story 2 (Phase 4 - P2)**: Depends on Foundational & `ServerSettingsModal` from US1 (`T010`, `T011`, `T012`).
- **User Story 3 (Phase 5 - P3)**: Depends on Foundational & `ServerSettingsModal` (`T013`).
- **Polish & Tests (Phase 6)**: Depends on Phases 2–5 (`T014`, `T015`, `T016`).

### Parallel Opportunities

- `T001` and `T002` can run in parallel.
- `T007` (`DemoLoginScreen`), `T008` (`LoginScreen`), and `T011` (`ResidentHeader`) modify separate screen files and can run in parallel once `ServerSettingsModal` (`T006`) exists.
- `T014` (unit tests) and `T015` (widget tests) touch separate test files and can run in parallel.

---

## Parallel Example: User Story 1 & 2 Screen Entry Points

```bash
# After T006 (ServerSettingsModal), wire entry points in parallel:
Task T007: "Add Settings icon button in lib/presentation/auth/demo_login_screen.dart"
Task T008: "Add Settings icon button in lib/presentation/auth/login_screen.dart"
Task T011: "Add Settings icon button in lib/presentation/shared/resident_header.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003`–`T005`)
3. Complete Phase 3: User Story 1 (`T006`–`T009`)
4. **STOP and VALIDATE**: Open Settings on `DemoLoginScreen`, enter MacBook IP, save, and verify all microservice calls use the new base URL.

### Incremental Delivery

1. Setup + Foundational → Core config, persistence, and all-microservice propagation ready.
2. Add User Story 1 (P1) → Unauthenticated Settings modal + shorthand IP entry ready.
3. Add User Story 2 (P2) → Authenticated header Settings modal + Reset to Default + in-place resident/portal refresh ready.
4. Add User Story 3 (P3) + Phase 6 Tests → Validation, live connection probe, and automated test suite complete.
