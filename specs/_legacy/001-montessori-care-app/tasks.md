---
description: "Task list template for feature implementation"
---

# Tasks: Montessori Care App

**Input**: Design documents from `/specs/001-montessori-care-app/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project structure per implementation plan in `lib/`
- [x] T002 Update `pubspec.yaml` with Riverpod, Isar, Http, and GoRouter dependencies
- [x] T003 [P] Implement Stitch design tokens in `lib/core/theme/app_theme.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

- [x] T004 Create core entity models for Isar in `lib/data/local/` (User, Resident, CareLog)
- [x] T005 Run Isar code generation via build_runner
- [x] T006 [P] Implement base network client for MCP/Zitadel in `lib/core/network/api_client.dart`
- [x] T007 Setup GoRouter configuration framework in `lib/core/router/app_router.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Secure Staff Authentication (Priority: P1) 🎯 MVP

**Goal**: As a caregiver or facility staff member, I want to securely log into the application so that I can access my personalized dashboard and resident information.

**Independent Test**: Can be fully tested by launching the app, seeing the Welcome to Evergreen screen, navigating to the Staff Login screen, logging in successfully, and being redirected to the Evergreen Dashboard.

### Implementation for User Story 1

- [x] T008 [P] [US1] Implement AuthRepository (Zitadel integration) in `lib/data/repositories/auth_repository.dart`
- [x] T009 [US1] Create AuthProvider (Riverpod state) in `lib/presentation/auth/auth_provider.dart`
- [x] T010 [US1] Build Welcome Screen UI in `lib/presentation/auth/welcome_screen.dart`
- [x] T011 [US1] Build Login Screen UI in `lib/presentation/auth/login_screen.dart`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Multi-Platform Navigation (Priority: P1)

**Goal**: As a user on a mobile device or desktop browser, I want a navigation layout that is optimized for my screen size so that I can easily move between the Dashboard, Residents list, and Care Logs.

**Independent Test**: Can be fully tested by resizing the window or launching on different platforms to verify the navigation pattern switches between Sidebar and Bottom Nav.

### Implementation for User Story 2

- [x] T012 [P] [US2] Create Sidebar widget in `lib/presentation/shared/sidebar_nav.dart`
- [x] T013 [P] [US2] Create BottomNav widget in `lib/presentation/shared/bottom_nav.dart`
- [x] T014 [US2] Implement responsive shell layout in `lib/presentation/shared/responsive_layout.dart` integrating GoRouter

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Caregiver Handover & Dashboard (Priority: P2)

**Goal**: As a caregiver, I want to view my current shift's priorities and a summary of my residents' status so that I can organize my daily tasks effectively.

**Independent Test**: Can be fully tested by navigating to the Evergreen Dashboard and observing the summary data.

### Implementation for User Story 3

- [x] T015 [P] [US3] Create Evergreen Dashboard UI in `lib/presentation/dashboard/dashboard_screen.dart`
- [x] T016 [P] [US3] Create Caregiver Handover UI in `lib/presentation/dashboard/handover_screen.dart`
- [x] T017 [US3] Implement DashboardProvider for state fetching in `lib/presentation/dashboard/dashboard_provider.dart`

**Checkpoint**: All user stories up to P2 Dashboard should now be functional

---

## Phase 6: User Story 4 - Resident Profile & Care Logs (Priority: P2)

**Goal**: As a caregiver, I want to access a resident's profile and log meaningful work or care activities so that there is an accurate record of their daily engagement.

**Independent Test**: Can be fully tested by selecting a resident and adding a new entry to the Meaningful Work Log (saved to Isar).

### Implementation for User Story 4

- [x] T018 [P] [US4] Implement CareLogRepository with offline-first background sync logic in `lib/data/repositories/care_log_repository.dart`
- [x] T019 [P] [US4] Create Residents List UI in `lib/presentation/residents/residents_list_screen.dart`
- [x] T020 [US4] Create Resident Profile UI in `lib/presentation/residents/resident_profile_screen.dart`
- [x] T021 [US4] Build Care Log submission form UI in `lib/presentation/residents/care_log_form.dart`

---

## Phase 7: User Story 5 - CareGuide AI Assistant (Priority: P3)

**Goal**: As a caregiver, I want to ask the CareGuide AI Assistant questions about a resident's care plan or general Montessori techniques.

**Independent Test**: Can be fully tested by opening the CareGuide AI Assistant, submitting a query, and receiving a relevant response via MCP service.

### Implementation for User Story 5

- [x] T022 [P] [US5] Implement CareGuide service connecting to MCP in `lib/domain/repositories/careguide_service.dart`
- [x] T023 [US5] Create Chat interface UI in `lib/presentation/careguide/chat_screen.dart`

---

## Phase 8: User Story 6 - Profile Settings (Priority: P3)

**Goal**: As a caregiver, I want to view and manage my profile settings so that I can configure my application preferences.

**Independent Test**: Can be fully tested by navigating to the Profile Settings screen and updating a preference.

### Implementation for User Story 6

- [x] T024 [US6] Create Profile Settings UI in `lib/presentation/settings/profile_settings_screen.dart`

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories (e.g., edge cases clarified during specs)

- [x] T025 Handle Empty States with encouraging text in `lib/presentation/shared/empty_state_widget.dart`
- [x] T026 Implement Token Expiration graceful re-login modal in `lib/presentation/auth/reauth_modal.dart`
- [x] T027 Restrict Dark Mode explicitly to preserve Light theme aesthetic across entire app

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion

### Parallel Opportunities
- After Phase 2, different team members can tackle US1, US2, and US3 simultaneously since their UI components are distinct and mock data can be used initially.
- Specifically, T012 and T013 can be developed entirely in parallel as isolated widgets.

## Implementation Strategy

### MVP First (User Story 1 & 2 Only)
1. Complete Phase 1 & 2
2. Complete Phase 3 (Auth) and Phase 4 (Navigation Shell)
3. **STOP and VALIDATE**: Test Login -> Navigate around shell layout
4. Iteratively add remaining user stories to the shell.
