# Phase 0 Research: Caregiver Sign-Up & Modular AuthN/AuthZ Provisioning

**Feature**: `014-caregiver-signup`  
**Date**: 2026-11-22  
**Repositories**: `elderly-microservices` (Go Modular Monolith), `elderly-mobile` (Flutter Application)

---

## 1. Modular Monolith Onboarding & Verification Storage

- **Decision**: Implement the two-step caregiver email sign-up and 6-digit verification lifecycle inside `internal/auth` backed by PostgreSQL (`auth.onboarding_verifications` and an explicit `username` column on `auth.users`) in `internal/platform/database/migrations.go`.
- **Rationale**:
  - The Kubo backend operates as a Go modular monolith (`cmd/server/main.go`) where `internal/auth`, `internal/institution`, `internal/access`, and `internal/audit` share an in-process PostgreSQL pool (`pgxpool.Pool`) and JWT `TokenVerifier`.
  - Storing pending verification records in `auth.onboarding_verifications` (coupled with an in-memory fallback map when running in disconnected/unit-test mode) keeps the 6-digit code lifecycle (15-minute TTL, single-use consumption, 5-attempt brute-force cutoff, and superseding on resend) self-contained and transactional with `auth.users` creation.
- **Alternatives Considered**:
  - *External-only microservice call to `services/identity` over gRPC*: Rejected as the primary path because `cmd/server/main.go` serves mobile traffic directly from `internal/auth`, and requiring an external ZITADEL container for local/E2E mobile caregiver sign-up would break zero-dependency local stack execution. (The standalone `shared/proto/identity/v1` contract remains compatible.)
  - *Stateless JWT-encoded 6-digit code without DB persistence*: Rejected because stateless tokens cannot enforce single-use consumption, 5-attempt brute-force invalidation, or immediate superseding of prior codes on resend (`FR-005`, `FR-011`).

---

## 2. Pluggable Email Delivery & Local Dev SMTP Server (`docker-compose.yml`)

- **Decision**:
  1. Add a lightweight local dev SMTP & web-inbox service (`mailpit` using image `axllent/mailpit:latest`, exposing SMTP on `:1025` and Web UI / REST API on `:8025`) to `elderly-microservices/docker-compose.yml` and start/manage it automatically in `elderly-microservices/scripts/dev_stack.sh`.
  2. Configure default local environment variables (`SMTP_HOST=localhost`, `SMTP_PORT=1025`, `SMTP_FROM_EMAIL=no-reply@kubocare.local` in `.env.example` / `scripts/dev_stack.sh`; and `SMTP_HOST=${SMTP_HOST:-mailpit}`, `SMTP_PORT=${SMTP_PORT:-1025}` inside `docker-compose.yml` for the `monolith` service).
  3. Introduce an `EmailSender` interface in `internal/auth` with two built-in implementations:
     - `SMTPEmailSender`: Dispatches HTML/plain-text onboarding emails via standard `net/smtp` to `SMTP_HOST:SMTP_PORT` (delivering directly to the `mailpit` container in local Docker/dev-stack testing or a production SMTP relay in staging/prod) and also mirrors the dispatched message to the local in-memory outbox for fast in-process inspection.
     - `LocalOutboxEmailSender`: Used when `SMTP_HOST` is unset (e.g., isolated unit tests) or as a non-fatal fallback if the local SMTP container is unreachable, logging the structured onboarding email (recipient, 6-digit code, and finalization link `/signup/finalize?email=<url_encoded_email>`) and honoring the `123456` dev OTP shortcut when `ALLOW_INSECURE_DEV_TOKENS=true`.
- **Rationale**:
  - Satisfies `FR-003` and `FR-004` across production and local/CI environments without requiring an external mail relay during local development or `go test` / `flutter test` runs.
  - Ensures the finalization link never embeds the secret 6-digit code in the URL (`FR-006`), preventing accidental code leakage via URL logs or browser history while pre-populating the caregiver's email address in the mobile app.
- **Alternatives Considered**:
  - *Third-party SaaS SDK (SendGrid/SES only)*: Rejected because standard `net/smtp` works with any SMTP relay (including SendGrid/SES/Mailpit) without adding external Go module dependencies.

---

## 3. Explicit Caregiver Username & Backward-Compatible Credential Login

- **Decision**:
  - Add a nullable/populated `username TEXT` column to `auth.users` with a case-insensitive unique index (`CREATE UNIQUE INDEX IF NOT EXISTS idx_auth_users_username_lower ON auth.users (LOWER(username)) WHERE username IS NOT NULL`).
  - Backfill existing seeded users' `username` from the local-part prefix of their email (`SPLIT_PART(email, '@', 1)`).
  - Update `POST /api/v1/auth/login` (`LoginRequest` and `Repository.GetByIdentifier`) to accept either `username` or `email` (matching `LOWER(username) = LOWER($1) OR LOWER(email) = LOWER($1)`), and update `HttpAuthRepository.loginWithCredentials` in `elderly-mobile` to send the raw identifier rather than unconditionally appending `@kubocare.com`.
- **Rationale**:
  - Previously, `HttpAuthRepository.loginWithCredentials` in `elderly-mobile` appended `@kubocare.com` whenever the username had no `@` character. A caregiver signing up with `jane.doe@gmail.com` and confirming or customizing their username as `jane.doe` or `nurse_jane` would fail to log in if `@kubocare.com` were appended.
  - Looking up by `LOWER(username) = LOWER($1) OR LOWER(email) = LOWER($1)` preserves 100% backward compatibility with all existing demo accounts (`sarah.thompson`, `lisa.chen`, `james.williams`, `caregiver`) and full email logins while supporting any caregiver username established during sign-up finalization (`FR-007`, `FR-008`, `FR-009`).
- **Alternatives Considered**:
  - *Forcing email-only login*: Rejected because `LoginScreen` prompts for `Username` and the user explicitly selected Option B in clarification (editable Username field on the finalization screen pre-filled with the email local-part prefix).

---

## 4. Automatic Authentication (AuthN) & Multi-Tenant Authorization (AuthZ) Provisioning

- **Decision**: Upon successful verification in `POST /api/v1/auth/onboarding/finalize`:
  1. **AuthN**: Persist the verified `auth.users` row (`role = 'caregiver'`, `username`, `name`, bcrypt `password_hash`, `is_email_verified = true`, `is_sms_verified = true`, `needs_onboarding = false`) and immediately mint a signed HS256 JWT bearer token containing `sub` (user UUID), `email`, `name`, `username`, `role: "caregiver"`, `is_email_verified: true`, and `is_sms_verified: true`.
  2. **AuthZ**: Inject an `AffiliationProvisioner` hook (satisfied by `internal/institution.Service` or direct `institution.caregiver_affiliations` upsert to `StandaloneInstitutionID = 00000000-0000-0000-0000-000000000001`) into `internal/auth.Service` so the new caregiver has an active affiliation record in PostgreSQL, in addition to `institutionService.IsCaregiverAffiliated` and `middleware.InstitutionContext` defaulting unscoped requests to `StandaloneInstitutionID`.
  3. **Mobile Session & Resident Context Hydration**: In `elderly-mobile`, `HttpAuthRepository.finalizeCaregiverSignUp` sets `_apiClient.setAuthToken(token)`, constructs the `UserProfile` with `role: UserRole.visitingCaregiver` and default `linkedResidentId: '3b471508-d528-4cfb-a9e0-4ac4b06eeec9'` (Margaret Thompson in the standalone care context), updates `authProvider`, selects the resident in `residentProvider`, and navigates to `/portal`.
- **Rationale**:
  - Guarantees that a newly finalized caregiver is immediately authenticated and authorized across Casbin RBAC (`configs/rbac_policy.csv` grants `caregiver` role access across `/api/v1/*`), institution checks (`internal/institution`), and patient-scoped endpoints (`/api/v1/patients`, `/api/v1/activities`, `/api/v1/assessments`, `/api/v1/nutrition`, `/api/v1/moods`, `/api/v1/memories`).
- **Alternatives Considered**:
  - *Requiring manual admin invitation before a caregiver can use the app*: Rejected during clarification (Question 4: default to the standalone care context and default resident profile so the caregiver lands in a functional portal immediately).

---

## 5. Mobile Routing & Deep-Link Finalization Flow (`elderly-mobile`)

- **Decision**:
  - Register `/signup` (`CaregiverSignUpScreen`) and `/signup/finalize` (`CaregiverFinalizeSignUpScreen`, accepting query parameter `?email=...`) as unauthenticated routes in `lib/core/router/app_router.dart` (updating `isAuthPath` in the `GoRouter` redirect guard to include `/signup` and `/signup/finalize`).
  - Support both custom scheme / deep links (`kubo://signup/finalize?email=...` normalized by GoRouter) and direct in-app navigation from Step 1 (`context.go('/signup/finalize?email=${Uri.encodeComponent(email)}')`).
  - Pre-fill the editable `Username` controller on `CaregiverFinalizeSignUpScreen` with the local-part prefix of `email` (the substring before `@`), while tracking whether the user has manually edited it.
- **Rationale**:
  - Satisfies `FR-001`, `FR-002`, `FR-006`, `FR-007`, and `FR-008` while adhering to the `elderly-mobile` constitution (Riverpod state management, dual `HttpAuthRepository` + `MockAuthRepository` support, minimum 48x48dp touch targets, and `#F2FAF5` Montessori palette).
- **Alternatives Considered**:
  - *Single modal dialog on `LoginScreen`*: Rejected because a dedicated `/signup/finalize?email=...` route is required so deep links from the onboarding email can navigate directly to the finalization screen.
