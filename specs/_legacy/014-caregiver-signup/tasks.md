# Tasks: Caregiver Sign-Up for Kubo North Service

**Input**: Design documents from `/specs/014-caregiver-signup/`
**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md) (required for user stories), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/openapi.yaml](./contracts/openapi.yaml)

**Tests**: Included per Constitution Principle V (`elderly-microservices`: >80% unit test coverage + integration tests) and Principle III (`elderly-mobile`: automated `flutter_test` unit and widget tests).

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and testing of each story across `elderly-microservices` and `elderly-mobile`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Configuration & Local Dev SMTP Infrastructure)

**Purpose**: Extend environment configuration and add a local development SMTP server (`mailpit`) to Docker Compose and the dev stack launcher for end-to-end local email verification testing.

- [X] T001 Add optional `SMTPHost`, `SMTPPort`, `SMTPUsername`, `SMTPPassword`, `SMTPFromEmail`, and `AppFinalizationBaseURL` configuration fields with local defaults (`SMTPPort=1025`, `SMTPFromEmail=no-reply@kubocare.local`, `AppFinalizationBaseURL=/signup/finalize`) in `elderly-microservices/internal/platform/config/config.go`
- [X] T002 [P] Document `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`, and `APP_FINALIZATION_BASE_URL` environment variables in `elderly-microservices/.env.example`
- [X] T003 [P] Add the `mailpit` local dev SMTP server service (`axllent/mailpit:latest`, ports `1025:1025` for SMTP and `8025:8025` for Web UI/REST API, with healthcheck) and wire `SMTP_HOST=${SMTP_HOST:-mailpit}`, `SMTP_PORT=${SMTP_PORT:-1025}`, `SMTP_FROM_EMAIL=${SMTP_FROM_EMAIL:-no-reply@kubocare.local}`, and `APP_FINALIZATION_BASE_URL=${APP_FINALIZATION_BASE_URL:-/signup/finalize}` into the `monolith` service in `elderly-microservices/docker-compose.yml`
- [X] T004 [P] Update `elderly-microservices/scripts/dev_stack.sh` to start/stop the `mailpit` Docker container (`docker compose up -d mailpit`), export `SMTP_HOST="${SMTP_HOST:-localhost}"` and `SMTP_PORT="${SMTP_PORT:-1025}"` for the local Go server, and display the Mailpit Web Inbox URL (`http://localhost:8025`) in the startup summary banner

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core database schema, domain models, pluggable email transport, and repository interfaces that MUST be complete before any user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 Extend PostgreSQL schema migrations in `elderly-microservices/internal/platform/database/migrations.go` to add `username TEXT` (backfilled from `SPLIT_PART(email, '@', 1)` with case-insensitive unique index `idx_auth_users_username_lower`) to `auth.users` and create the `auth.onboarding_verifications` table (`id`, `email`, `code_hash`, `role`, `attempts`, `expires_at`, `consumed_at`, `created_at`, `updated_at`)
- [X] T006 [P] Extend `User` struct with `Username string` and define `OnboardingVerification`, `InitiateOnboardingRequest`, `InitiateOnboardingResponse`, `ResendOnboardingRequest`, `FinalizeOnboardingRequest`, and `AffiliationProvisioner` types in `elderly-microservices/internal/auth/model.go`
- [X] T007 [P] Implement pluggable `EmailSender` interface with `SMTPEmailSender` (`net/smtp` delivering to the `mailpit` dev SMTP server or configured production SMTP relay with graceful outbox mirroring) and `LocalOutboxEmailSender` (structured log + inspectable in-memory outbox for offline unit tests) in `elderly-microservices/internal/auth/email_sender.go`
- [X] T008 Update `auth.Repository` and `pgRepository` in `elderly-microservices/internal/auth/repository.go` to persist/scan `username` on `auth.users`, add `GetByIdentifier(ctx, identifier)` (`LOWER(email) = LOWER($1) OR LOWER(username) = LOWER($1)`), and add `UpsertOnboardingVerification`, `GetOnboardingVerification`, `IncrementVerificationAttempts`, and `ConsumeOnboardingVerification` (with in-memory fallback support when `pool == nil`)
- [X] T009 [P] Define `CaregiverSignUpInitiationResult` and add `initiateCaregiverSignUp`, `resendCaregiverSignUpCode`, and `finalizeCaregiverSignUp` method signatures to `AuthRepository` in `elderly-mobile/lib/data/repositories/auth_repository.dart`

**Checkpoint**: Foundation ready — User Story 1, User Story 2, and User Story 3 implementation can now proceed.

---

## Phase 3: User Story 1 - Caregiver Initiates Email Sign-Up from Login Page (Priority: P1) 🎯 MVP

**Goal**: Allow an unauthenticated prospective caregiver to click "Sign Up" on the Kubo North login page, submit their email address, and have the onboarding service generate a 6-digit verification code and finalization link and send the verification email through the configured SMTP / dev `mailpit` server.

**Independent Test**: Click the "Sign Up" button on `LoginScreen`, submit a valid unregistered caregiver email address, and verify that `POST /api/v1/auth/onboarding/initiate` creates a pending `caregiver` verification record, dispatches an email containing both a 6-digit code and the `/signup/finalize?email=...` link to the dev SMTP server (`mailpit` on `:1025` / `:8025` or local outbox), emits a `CAREGIVER_SIGNUP_INITIATED` audit event, and transitions the app to the verification/finalization prompt.

### Tests for User Story 1

- [X] T010 [P] [US1] Add unit tests for `InitiateOnboarding` and `SMTPEmailSender`/`LocalOutboxEmailSender` (valid email, malformed email rejection, already-finalized email conflict, 6-digit code + finalization link dispatch, and `CAREGIVER_SIGNUP_INITIATED` audit log) in `elderly-microservices/internal/auth/auth_test.go`
- [X] T011 [P] [US1] Add unit and widget tests for login page "Sign Up" navigation and caregiver email sign-up submission in `elderly-mobile/test/unit/auth_provider_test.dart` and `elderly-mobile/test/widget/caregiver_signup_test.dart`

### Implementation for User Story 1

- [X] T012 [US1] Implement `InitiateOnboarding` in `elderly-microservices/internal/auth/service.go` (normalizes email, rejects already-finalized accounts with `ErrUserAlreadyExists`, generates a 6-digit code with 15-minute expiry, stores `OnboardingVerification` with `role = RoleCaregiver`, dispatches email via `EmailSender`, and logs `CAREGIVER_SIGNUP_INITIATED`)
- [X] T013 [US1] Expose `POST /api/v1/auth/onboarding/initiate` (and alias `POST /api/v1/auth/signup/caregiver`) in `elderly-microservices/internal/auth/handler.go`
- [X] T014 [P] [US1] Implement `initiateCaregiverSignUp(String email)` in `elderly-mobile/lib/data/repositories/http_auth_repository.dart` and `elderly-mobile/lib/data/repositories/mock_auth_repository.dart`
- [X] T015 [US1] Add `initiateCaregiverSignUp(String email)` state handling (`pendingSignUpEmail`, `lastFinalizationLink`, `isLoading`, `errorMessage`) to `AuthNotifier` and `AuthState` in `elderly-mobile/lib/presentation/auth/auth_provider.dart`
- [X] T016 [P] [US1] Create `CaregiverSignUpScreen` (email validation, submission, confirmation banner, and button to proceed to the 6-digit code finalization screen) in `elderly-mobile/lib/presentation/auth/caregiver_signup_screen.dart`
- [X] T017 [US1] Add the "Sign Up as Caregiver" button (`Key('login_signup_button')`) on `LoginScreen` in `elderly-mobile/lib/presentation/auth/login_screen.dart` and register the unauthenticated `/signup` route in `elderly-mobile/lib/core/router/app_router.dart`

**Checkpoint**: User Story 1 is independently functional and testable across backend and mobile.

---

## Phase 4: User Story 2 - Caregiver Finalizes Sign-Up via Email Link, 6-Digit Code, and Password Setup (Priority: P1)

**Goal**: Allow the caregiver to open the finalization screen from the email link (or directly in-app) with their email pre-populated and an editable "Username" field pre-filled with the email prefix, enter the 6-digit code and password, and automatically provision their `caregiver` account credentials, `StandaloneInstitutionID` affiliation (AuthZ), and active JWT session (AuthN) to land directly in `/portal`.

**Independent Test**: Open `/signup/finalize?email=jane.caregiver%40example.com`, confirm the editable `Username` field is pre-filled with `jane.caregiver`, enter the valid 6-digit code and an 8+ character password, submit, and verify that the user is created with `role = caregiver` and `is_email_verified = true`, affiliated with `StandaloneInstitutionID`, auto-logged into `/portal` with the default resident selected, and can subsequently log out and sign back in on `LoginScreen` using their chosen `username` and `password`.

### Tests for User Story 2

- [X] T018 [P] [US2] Add unit tests for `FinalizeOnboarding`, automatic `StandaloneInstitutionID` caregiver affiliation provisioning, and username/email dual `Login` in `elderly-microservices/internal/auth/auth_test.go`
- [X] T019 [P] [US2] Add end-to-end integration test covering caregiver sign-up initiation → 6-digit verification finalization → automatic JWT & standalone institution authorization → protected `/api/v1/patients` access → username login in `elderly-microservices/test/integration/mobile_e2e_test.go`
- [X] T020 [P] [US2] Add unit and widget tests for `CaregiverFinalizeSignUpScreen` (deep-link email pre-population, editable email-prefix username pre-fill, password confirmation validation, auto-login redirect to `/portal`, and subsequent username login) in `elderly-mobile/test/unit/auth_provider_test.dart` and `elderly-mobile/test/widget/caregiver_signup_test.dart`

### Implementation for User Story 2

- [X] T021 [US2] Implement `FinalizeOnboarding` in `elderly-microservices/internal/auth/service.go` (validates 6-digit code/dev OTP, validates unique 3–64 char username and 8+ char password, creates/activates `auth.users` with `RoleCaregiver` and `IsEmailVerified = true`, invokes `AffiliationProvisioner` for `StandaloneInstitutionID`, logs `CAREGIVER_SIGNUP_FINALIZED`, and issues signed JWT with `username` and `role: "caregiver"` claims)
- [X] T022 [US2] Update `Login` in `elderly-microservices/internal/auth/service.go` and `LoginRequest` in `elderly-microservices/internal/auth/model.go` to accept either `username` or `email` and look up users via `repo.GetByIdentifier`
- [X] T023 [US2] Expose `POST /api/v1/auth/onboarding/finalize` in `elderly-microservices/internal/auth/handler.go` and wire `EmailSender` (configured with `cfg.SMTPHost`, `cfg.SMTPPort`, `cfg.SMTPFromEmail`, `cfg.AppFinalizationBaseURL`) and the `StandaloneInstitutionID` caregiver affiliation provisioner (`instRepo` / `instService`) into `authService` in `elderly-microservices/cmd/server/main.go`
- [X] T024 [P] [US2] Implement `finalizeCaregiverSignUp({required String email, required String code, required String username, required String password})` and update `loginWithCredentials` (removing unconditional `@kubocare.com` suffixing so customized caregiver usernames authenticate directly) in `elderly-mobile/lib/data/repositories/http_auth_repository.dart` and `elderly-mobile/lib/data/repositories/mock_auth_repository.dart`
- [X] T025 [US2] Add `finalizeCaregiverSignUp` to `AuthNotifier` in `elderly-mobile/lib/presentation/auth/auth_provider.dart` to hydrate `AuthState` with the authenticated `UserProfile` (`UserRole.visitingCaregiver`, default standalone `linkedResidentId`)
- [X] T026 [P] [US2] Create `CaregiverFinalizeSignUpScreen` (pre-populated email from query parameter or auth state, editable `Username` field pre-filled with the email local-part prefix, 6-digit code input, password & confirm password inputs, and auto-login navigation to `/portal` + `residentProvider.selectById`) in `elderly-mobile/lib/presentation/auth/caregiver_finalize_signup_screen.dart`
- [X] T027 [US2] Register `/signup/finalize` (supporting `?email=...` deep-link and in-app query parameters) as an unauthenticated route in `elderly-mobile/lib/core/router/app_router.dart`

**Checkpoint**: User Stories 1 and 2 are complete — full caregiver sign-up, 6-digit verification, username/password setup, and automatic AuthN/AuthZ work end-to-end.

---

## Phase 5: User Story 3 - Resending Verification Code and Handling Invalid or Expired Codes (Priority: P2)

**Goal**: Provide clear error handling for expired (15-minute TTL), mistyped, or locked (5 failed attempts) 6-digit codes and allow caregivers to resend a fresh 6-digit code and finalization link that invalidates previous codes.

**Independent Test**: Submit an invalid 6-digit code 5 times (or an expired code) on the finalization screen, confirm rejection with a clear error message and lockout, trigger "Resend Verification Code", verify the prior code is invalidated and a new 6-digit code is issued, and finalize sign-up using the new code.

### Tests for User Story 3

- [X] T028 [P] [US3] Add unit tests for expired code rejection, 5-attempt brute-force lockout, and `ResendOnboardingCode` superseding prior codes in `elderly-microservices/internal/auth/auth_test.go`
- [X] T029 [P] [US3] Add widget and unit tests for invalid code error display and "Resend Code" action on `CaregiverFinalizeSignUpScreen` in `elderly-mobile/test/widget/caregiver_signup_test.dart`

### Implementation for User Story 3

- [X] T030 [US3] Implement `ResendOnboardingCode` and 5-attempt lockout / 15-minute expiration enforcement in `elderly-microservices/internal/auth/service.go` and expose `POST /api/v1/auth/onboarding/resend` in `elderly-microservices/internal/auth/handler.go`
- [X] T031 [P] [US3] Implement `resendCaregiverSignUpCode(String email)` in `elderly-mobile/lib/data/repositories/http_auth_repository.dart`, `elderly-mobile/lib/data/repositories/mock_auth_repository.dart`, and `elderly-mobile/lib/presentation/auth/auth_provider.dart`
- [X] T032 [US3] Add "Resend 6-Digit Verification Email" button, confirmation feedback, and invalid/expired code error banners to `CaregiverFinalizeSignUpScreen` in `elderly-mobile/lib/presentation/auth/caregiver_finalize_signup_screen.dart`

**Checkpoint**: All three user stories (`US1`, `US2`, `US3`) are independently functional and tested.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end validation, OpenAPI Swagger synchronization, and canonical specification/blueprint compliance.

- [X] T033 [P] Update aggregated auth documentation in `elderly-microservices/shared/swagger/identity.swagger.json` (or verify contract parity with `specs/014-caregiver-signup/contracts/openapi.yaml`)
- [X] T034 Run full backend test suite (`go test ./...`) in `elderly-microservices` and mobile analysis & test suite (`flutter analyze && flutter test`) in `elderly-mobile` per `specs/014-caregiver-signup/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup & Dev SMTP Infrastructure)**: No dependencies — can start immediately (`T001`–`T004`).
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS** all user stories (`T005`–`T009`).
- **Phase 3 (User Story 1 - P1 MVP)**: Depends on Phase 2 completion (`T010`–`T017`).
- **Phase 4 (User Story 2 - P1 Finalization & Auto-AuthN/AuthZ)**: Depends on Phase 2 and integrates with `US1` initiation (`T018`–`T027`).
- **Phase 5 (User Story 3 - P2 Resend & Lockout Recovery)**: Depends on `US1` and `US2` verification lifecycle (`T028`–`T032`).
- **Phase 6 (Polish)**: Depends on Phases 3–5 completion (`T033`–`T034`).

### User Story Dependency Graph

```text
Phase 1: Setup & Dev SMTP (docker-compose mailpit + dev_stack.sh) (T001–T004)
   │
   ▼
Phase 2: Foundational (T005–T009)
   │
   ├──► Phase 3: US1 - Email Sign-Up Initiation from Login Page (T010–T017) 🎯 MVP
   │       │
   │       ▼
   └──► Phase 4: US2 - 6-Digit Code, Editable Username & Password Finalization + Auto-AuthN/AuthZ (T018–T027)
           │
           ▼
        Phase 5: US3 - Resend Verification Code & Lockout/Expiry Handling (T028–T032)
           │
           ▼
        Phase 6: Polish & Cross-Repo Validation (T033–T034)
```

### Parallel Opportunities

- **Setup & Foundational**: `T002`, `T003`, `T004` (in Phase 1) and `T006`, `T007`, `T009` (in Phase 2) touch separate files across `elderly-microservices` and `elderly-mobile` and can run in parallel.
- **Within User Story 1**: Backend tasks (`T010`, `T012`, `T013`) and mobile tasks (`T011`, `T014`, `T016`) can run in parallel across the two repositories.
- **Within User Story 2**: Backend finalization/AuthZ provisioning (`T018`, `T019`, `T021`–`T023`) and mobile finalization UI/repository (`T020`, `T024`–`T027`) can run in parallel.
- **Within User Story 3**: Backend resend/lockout (`T028`, `T030`) and mobile resend UI (`T029`, `T031`, `T032`) can run in parallel.

---

## Parallel Example: User Story 2

```bash
# Run backend and mobile tests for User Story 2 in parallel:
Task T018: "Add unit tests for FinalizeOnboarding, automatic StandaloneInstitutionID caregiver affiliation provisioning, and username/email dual Login in elderly-microservices/internal/auth/auth_test.go"
Task T020: "Add unit and widget tests for CaregiverFinalizeSignUpScreen in elderly-mobile/test/unit/auth_provider_test.dart and elderly-mobile/test/widget/caregiver_signup_test.dart"

# Implement backend finalization and mobile finalization UI in parallel:
Task T021: "Implement FinalizeOnboarding in elderly-microservices/internal/auth/service.go"
Task T024: "Implement finalizeCaregiverSignUp and update loginWithCredentials in elderly-mobile/lib/data/repositories/http_auth_repository.dart and mock_auth_repository.dart"
Task T026: "Create CaregiverFinalizeSignUpScreen in elderly-mobile/lib/presentation/auth/caregiver_finalize_signup_screen.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2 Core Flow)

1. Complete **Phase 1: Setup & Dev SMTP** (`T001`–`T004`) and **Phase 2: Foundational** (`T005`–`T009`).
2. Complete **Phase 3: User Story 1** (`T010`–`T017`) and validate caregiver email sign-up initiation and dev SMTP (`mailpit`) email delivery.
3. Complete **Phase 4: User Story 2** (`T018`–`T027`) and validate 6-digit code verification, editable username + password finalization, automatic JWT + standalone institution affiliation, and immediate `/portal` access.
4. Complete **Phase 5: User Story 3** (`T028`–`T032`) to add resend and brute-force/expiry recovery.
5. Complete **Phase 6: Polish** (`T033`–`T034`) to verify full test suites across both repositories.
