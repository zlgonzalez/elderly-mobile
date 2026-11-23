# Phase 1 Data Model: Caregiver Sign-Up & Modular AuthN/AuthZ Provisioning

**Feature**: `014-caregiver-signup`  
**Date**: 2026-11-22  
**Repositories**: `elderly-microservices` (PostgreSQL 16 + Go models), `elderly-mobile` (Dart domain models)

---

## 1. Backend PostgreSQL Schema & Go Entities (`elderly-microservices`)

### 1.1 `auth.users` (Extended)

Extends the existing `auth.users` table in `internal/platform/database/migrations.go` and `auth.User` struct in `internal/auth/model.go` with an explicit `username` column.

| Column / Field | SQL Type | Go Type | Constraints & Defaults | Description |
|----------------|----------|---------|------------------------|-------------|
| `id` | `UUID` | `uuid.UUID` | `PRIMARY KEY` | Unique user identifier |
| `email` | `TEXT` | `string` | `NOT NULL UNIQUE` (normalized lowercase) | User's verified email address |
| `username` | `TEXT` | `string` | `UNIQUE` (case-insensitive index `LOWER(username)`), backfilled from `SPLIT_PART(email, '@', 1)` | Login username confirmed or customized during finalization |
| `name` | `TEXT` | `string` | `NOT NULL` | Display name (defaults to `username` if not separately provided) |
| `role` | `TEXT` | `auth.Role` | `NOT NULL` (`admin`, `caregiver`, `family`) | Persona role (`caregiver` for this flow) |
| `phone_number` | `TEXT` | `*string` | Nullable | Optional phone number |
| `password_hash` | `TEXT` | `string` | `NOT NULL` (bcrypt hash) | Hashed user password |
| `is_email_verified` | `BOOLEAN` | `bool` | `NOT NULL DEFAULT FALSE` (`TRUE` upon finalization) | Email verification status |
| `is_sms_verified` | `BOOLEAN` | `bool` | `NOT NULL DEFAULT FALSE` (`TRUE` for finalized caregivers) | Secondary verification flag |
| `needs_onboarding` | `BOOLEAN` | `bool` | `NOT NULL DEFAULT TRUE` (`FALSE` upon finalization) | Onboarding completion status |
| `created_at` | `TIMESTAMPTZ` | `time.Time` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `time.Time` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

**Validation & Invariants**:
- `email` MUST be trimmed, lowercased, and match valid email syntax (`user@domain.tld`).
- `username` MUST be trimmed, non-empty (`3..64` characters), and unique case-insensitively across `auth.users`.
- `Login` (`POST /api/v1/auth/login`) resolves a user where `LOWER(email) = LOWER($1) OR LOWER(username) = LOWER($1)`.

---

### 1.2 `auth.onboarding_verifications` (New Table)

Tracks pending caregiver email sign-up verification codes and single-use finalization state (`internal/platform/database/migrations.go` & `internal/auth/model.go`).

| Column / Field | SQL Type | Go Type | Constraints & Defaults | Description |
|----------------|----------|---------|------------------------|-------------|
| `id` | `UUID` | `uuid.UUID` | `PRIMARY KEY` | Unique verification record ID |
| `email` | `TEXT` | `string` | `NOT NULL UNIQUE` (normalized lowercase) | Prospective caregiver's email address |
| `code_hash` | `TEXT` | `string` | `NOT NULL` | Bcrypt or SHA-256 hash of the 6-digit verification code |
| `role` | `TEXT` | `auth.Role` | `NOT NULL DEFAULT 'caregiver'` | Target persona role (`caregiver`) |
| `attempts` | `INT` | `int` | `NOT NULL DEFAULT 0` | Consecutive failed verification attempts (locked at `>= 5`) |
| `expires_at` | `TIMESTAMPTZ` | `time.Time` | `NOT NULL` (`NOW() + 15 minutes`) | Expiration timestamp for the 6-digit code |
| `consumed_at` | `TIMESTAMPTZ` | `*time.Time` | Nullable | Timestamp when code was successfully used to finalize sign-up |
| `created_at` | `TIMESTAMPTZ` | `time.Time` | `NOT NULL DEFAULT NOW()` | Initial sign-up request timestamp |
| `updated_at` | `TIMESTAMPTZ` | `time.Time` | `NOT NULL DEFAULT NOW()` | Last code generation or attempt timestamp |

**State Transitions**:
1. **Initiated / Resent (`Pending`)**: Upserts row for normalized `email`, sets fresh 6-digit `code_hash`, resets `attempts = 0`, sets `expires_at = NOW() + 15m`, and clears `consumed_at = NULL`. (Rejected with `409 Conflict` / `400 Bad Request` if an active, finalized `auth.users` account with `is_email_verified = true` and `needs_onboarding = false` already exists for `email`).
2. **Failed Attempt (`Attempts Incremented`)**: If code does not match and `attempts < 5`, increments `attempts = attempts + 1`. When `attempts >= 5`, the code is invalidated (`ErrInvalidOTP`) until a resend is requested.
3. **Expired**: If `NOW() > expires_at`, verification fails (`ErrInvalidOTP`) until a resend is requested.
4. **Finalized (`Consumed`)**: Sets `consumed_at = NOW()`, creates/activates the `auth.users` record, provisions the `institution.caregiver_affiliations` record for `StandaloneInstitutionID`, logs `CAREGIVER_SIGNUP_FINALIZED`, and returns `AuthResponse{Token, User}`.

---

### 1.3 `institution.caregiver_affiliations` (Automatic AuthZ Provisioning)

Existing table in `internal/platform/database/migrations.go` and `internal/institution/model.go`. During caregiver sign-up finalization, an active affiliation row is automatically upserted:

| Column | Value on Caregiver Finalization |
|--------|---------------------------------|
| `id` | `uuid.New()` |
| `caregiver_id` | `<new user.ID>` |
| `institution_id` | `00000000-0000-0000-0000-000000000001` (`StandaloneInstitutionID`) |
| `status` | `'active'` (`ON CONFLICT (caregiver_id, institution_id) DO UPDATE SET status = 'active'`) |

---

## 2. Mobile Domain & DTO Entities (`elderly-mobile`)

### 2.1 `CaregiverSignUpInitiationResult` (`lib/domain/entities/user_profile.dart` or `lib/data/repositories/auth_repository.dart`)

| Field | Dart Type | Description |
|-------|-----------|-------------|
| `email` | `String` | Normalized email address to which the 6-digit code was sent |
| `finalizationLink` | `String` | In-app route / deep link (`/signup/finalize?email=<encoded>`) |
| `expiresInSeconds` | `int` | Validity duration in seconds (`900` for 15 minutes) |
| `message` | `String` | User-facing confirmation message |

### 2.2 `UserProfile` (`lib/domain/entities/user_profile.dart`)

Upon successful `finalizeCaregiverSignUp(email, code, username, password)`:
- `id`: Backend user UUID
- `username`: Confirmed/customized caregiver username
- `fullName`: Caregiver display name (defaults to `username`)
- `role`: `UserRole.visitingCaregiver`
- `relation`: `'Caregiver'`
- `linkedResidentId`: `'3b471508-d528-4cfb-a9e0-4ac4b06eeec9'` (default standalone care resident Margaret Thompson)
