# Implementation Plan: Caregiver Sign-Up for Kubo North Service

**Branch**: `014-caregiver-signup` | **Date**: 2026-11-22 | **Spec**: [spec.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-microservices/specs/014-caregiver-signup/spec.md)  
**Input**: Feature specification from `/specs/014-caregiver-signup/spec.md`

## Summary

Implement end-to-end caregiver email sign-up, 6-digit verification code + finalization link delivery, editable username + password finalization, and automatic authentication (AuthN) and multi-tenant authorization (AuthZ) provisioning across the Go modular monolith (`elderly-microservices`) and Flutter mobile application (`elderly-mobile`):

1. **Modular Monolith Onboarding & Email Verification (`elderly-microservices`)**:
   - Extend `internal/platform/database/migrations.go` with an explicit case-insensitively unique `username` column on `auth.users` (backfilled from `SPLIT_PART(email, '@', 1)` for existing users) and a new `auth.onboarding_verifications` table storing normalized `email`, `code_hash`, `role` (`caregiver`), `attempts` (max 5), `expires_at` (15-minute TTL), and `consumed_at`.
   - Add `/api/v1/auth/onboarding/initiate` (and alias `/api/v1/auth/signup/caregiver`), `/api/v1/auth/onboarding/resend`, and `/api/v1/auth/onboarding/finalize` in `internal/auth`.
   - Add a local dev SMTP server container (`mailpit` — `axllent/mailpit:latest`, SMTP port `1025`, Web UI / API port `8025`) to `elderly-microservices/docker-compose.yml` and wire its startup and teardown into `elderly-microservices/scripts/dev_stack.sh`.
   - Implement a pluggable `EmailSender` (`SMTPEmailSender` delivering over `net/smtp` to `mailpit:1025` / `localhost:1025` or configured production SMTP, with `LocalOutboxEmailSender` structured log + inspectable in-memory outbox fallback + dev OTP `123456` allowance when `ALLOW_INSECURE_DEV_TOKENS=true`) that sends an email containing both the 6-digit verification code and the finalization link (`/signup/finalize?email=<encoded>`).
2. **Automatic Authentication (AuthN) & Authorization (AuthZ) Provisioning on Finalization (`elderly-microservices`)**:
   - On `POST /api/v1/auth/onboarding/finalize`, atomically verify the 6-digit code, validate the editable `username` and `password`, create/activate the `auth.users` row (`role = 'caregiver'`, `is_email_verified = true`, `is_sms_verified = true`, `needs_onboarding = false`), register an active caregiver affiliation with `StandaloneInstitutionID` (`00000000-0000-0000-0000-000000000001`) via `internal/institution`, emit `CAREGIVER_SIGNUP_INITIATED` / `CAREGIVER_SIGNUP_FINALIZED` audit logs via `internal/audit`, and return a signed JWT bearer token carrying `sub`, `email`, `username`, `name`, `role: "caregiver"`, and `is_email_verified: true`.
   - Ensure standalone patient and activity authorization checks (`internal/patient/handler.go` and `internal/activity/handler.go`) honor `IsCaregiverAffiliated(ctx, user.Subject, StandaloneInstitutionID)` in addition to `p.CreatorID == user.Subject` so newly onboarded standalone caregivers can access standalone residents and generate/enqueue regimens while unaffiliated callers remain rejected with `403 Forbidden`.
   - Update `POST /api/v1/auth/login` to authenticate against either `username` or `email` (`LOWER(username) = LOWER($1) OR LOWER(email) = LOWER($1)`).
3. **Flutter Mobile Sign-Up, Deep-Link Finalization & Auto-Login (`elderly-mobile`)**:
   - Add a **Sign Up as Caregiver** button on `LoginScreen` (`lib/presentation/auth/login_screen.dart`) and register unauthenticated `GoRouter` routes `/signup` (`CaregiverSignUpScreen`) and `/signup/finalize` (`CaregiverFinalizeSignUpScreen`, reading `?email=...`) in `lib/core/router/app_router.dart`.
   - Pre-populate `email` and pre-fill the editable `Username` field with the email local-part prefix on `CaregiverFinalizeSignUpScreen`, allowing manual 6-digit code entry, code resend, and password + confirmation input.
   - Extend `AuthRepository`, `HttpAuthRepository`, `MockAuthRepository`, and `AuthNotifier` with `initiateCaregiverSignUp`, `resendCaregiverSignUpCode`, and `finalizeCaregiverSignUp` (plus raw username/email login without blindly appending `@kubocare.com`), automatically storing the returned JWT on `ApiClient`, hydrating `UserProfile` (`UserRole.visitingCaregiver`, default standalone `linkedResidentId`), selecting the resident in `residentProvider`, and navigating directly to `/portal`.

## Technical Context

**Language/Version**: Go 1.22 (`elderly-microservices`), Dart 3.x / Flutter 3.x (`elderly-mobile`)  
**Primary Dependencies**: `chi/v5`, `pgx/v5`, `lestrrat-go/jwx/v2`, `golang.org/x/crypto/bcrypt`, `net/smtp` (Go); `flutter_riverpod`, `go_router`, `http` (Flutter)  
**Storage**: PostgreSQL 16 (`auth.users`, `auth.onboarding_verifications`, `institution.caregiver_affiliations`, `audit.audit_logs`) with in-memory repository fallback for unit/disconnected tests  
**Testing**: `go test ./...` (`elderly-microservices`), `flutter analyze && flutter test` (`elderly-mobile`)  
**Target Platform**: Linux/macOS servers & Docker (`elderly-microservices`), Android, iOS, Web & Desktop (`elderly-mobile`)  
**Project Type**: Multi-repository Go modular monolith backend + Flutter mobile application  
**Performance Goals**: `<100ms` p95 latency for onboarding initiate/resend/finalize and login endpoints (`SC-002` requires `<3s` code + link generation); `<2 minutes` total caregiver sign-up completion (`SC-001`)  
**Constraints**: 6-digit verification codes expire in 15 minutes (`900s`), are single-use, lock after 5 failed attempts, and never embed the secret 6-digit code in the finalization URL (`FR-005`, `FR-006`)  
**Scale/Scope**: Touches 2 repositories (`elderly-microservices` and `elderly-mobile`) on branch `014-caregiver-signup`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Service Independence & Modular Boundaries**: PASS — Backend onboarding, verification, and credential logic resides cleanly in `internal/auth`, affiliation provisioning in `internal/institution`, and audit logging in `internal/audit`; mobile UI (`lib/presentation/auth/`), routing (`lib/core/router/`), and dual repositories (`lib/data/repositories/`) maintain strict layer separation.
- **II. Identity & Multi-Tenant Authorization**: PASS — Finalized caregivers receive a signed JWT verified by `TokenVerifier` (`internal/auth/token.go`) with `role = "caregiver"`, and are automatically affiliated with `StandaloneInstitutionID` so `middleware.InstitutionContext`, Casbin RBAC (`configs/rbac_policy.csv`), and domain access guards authorize requests immediately.
- **III. Observability & Auditing (NON-NEGOTIABLE)**: PASS — Emits `CAREGIVER_SIGNUP_INITIATED` and `CAREGIVER_SIGNUP_FINALIZED` audit records via `internal/audit.AuditService` and structured logs via the platform logger.
- **IV. Contract-First**: PASS — OpenAPI 3.0 contract defined in `specs/014-caregiver-signup/contracts/openapi.yaml` before implementation.
- **V. Test-Driven Foundations (MANDATORY)**: PASS — Unit, widget, and integration tests planned across `internal/auth/auth_test.go`, `test/integration/mobile_e2e_test.go`, and `elderly-mobile/test/`.
- **Open Feature & Canonical Spec Synchronization**: PASS — `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/openapi.yaml`, and `quickstart.md` are synchronized across both repositories on branch `014-caregiver-signup`.

## Project Structure

### Documentation (this feature)

```text
specs/014-caregiver-signup/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/
│   └── openapi.yaml     # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (across the 2 repositories)

```text
elderly-microservices/
├── .env.example                             # Documents SMTP_HOST, SMTP_PORT (1025), SMTP_FROM_EMAIL, APP_FINALIZATION_BASE_URL
├── docker-compose.yml                       # Adds mailpit dev SMTP service (ports 1025 SMTP, 8025 Web UI/API) & monolith SMTP env vars
├── scripts/
│   └── dev_stack.sh                         # Starts/stops mailpit container and exports SMTP_HOST=localhost / SMTP_PORT=1025
├── cmd/
│   └── server/
│       └── main.go                          # Wires EmailSender + StandaloneInstitution affiliation hook into auth.Service
├── internal/
│   ├── platform/
│   │   ├── config/
│   │   │   └── config.go                    # Adds optional SMTP_* / APP_DEEP_LINK_BASE_URL config fields
│   │   └── database/
│   │       └── migrations.go                # Adds auth.users.username column + index & auth.onboarding_verifications table
│   └── auth/
│       ├── model.go                         # Adds Username to User, OnboardingVerification, Initiate/Resend/Finalize DTOs
│       ├── email_sender.go                  # New: EmailSender interface, SMTPEmailSender, LocalOutboxEmailSender
│       ├── repository.go                    # Adds GetByIdentifier (email or username), Upsert/Get/Increment/Consume verification methods
│       ├── service.go                       # Adds InitiateOnboarding, ResendOnboardingCode, FinalizeOnboarding + standalone AuthZ hook
│       ├── handler.go                       # Mounts POST /onboarding/initiate, /onboarding/resend, /onboarding/finalize, /signup/caregiver
│       └── auth_test.go                     # Unit tests for 6-digit code lifecycle, expiry, 5-attempt lockout, resend, username login, AuthZ
└── test/
    └── integration/
        └── mobile_e2e_test.go               # End-to-end test: caregiver email sign-up -> 6-digit code -> finalize -> auto-login -> protected patient/activity access

elderly-mobile/
├── lib/
│   ├── core/
│   │   └── router/
│   │       └── app_router.dart              # Adds /signup and /signup/finalize?email=... routes and updates unauthenticated redirect guard
│   ├── data/
│   │   └── repositories/
│   │       ├── auth_repository.dart         # Adds initiateCaregiverSignUp, resendCaregiverSignUpCode, finalizeCaregiverSignUp contracts
│   │       ├── http_auth_repository.dart    # Implements HTTP onboarding calls, JWT storage, and username/email login without forced @kubocare.com suffix
│   │       └── mock_auth_repository.dart    # Implements offline mock 6-digit onboarding & finalization flow
│   └── presentation/
│       └── auth/
│           ├── auth_provider.dart           # Adds initiateCaregiverSignUp, resendCaregiverSignUpCode, finalizeCaregiverSignUp state actions
│           ├── login_screen.dart            # Adds "Sign Up as Caregiver" button navigating to /signup
│           ├── caregiver_signup_screen.dart # New: Step 1 caregiver email sign-up screen
│           └── caregiver_finalize_signup_screen.dart # New: Step 2 finalization screen (pre-filled email, editable pre-filled username, 6-digit code, password)
│       └── shared/
│           └── resident_header.dart         # Adds Sign Out icon button (Key('header_logout_button')) to clear session and return to /login
└── test/
    ├── unit/
    │   └── auth_provider_test.dart          # Unit tests for caregiver sign-up initiation, resend, finalization, and login
    └── widget/
        └── caregiver_signup_test.dart       # Widget tests for LoginScreen -> CaregiverSignUpScreen -> CaregiverFinalizeSignUpScreen -> Portal
```

**Structure Decision**: Multi-repository modular enhancement across `elderly-microservices` (`internal/auth`, `internal/platform`, `cmd/server`) and `elderly-mobile` (`lib/core/router`, `lib/data/repositories`, `lib/presentation/auth`), leveraging the in-process modular monolith and dual-repository Flutter architecture without introducing new standalone microservices.

## Complexity Tracking

No constitution violations; complexity tracking table not required.
