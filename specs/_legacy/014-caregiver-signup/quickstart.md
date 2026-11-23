# Quickstart: Caregiver Sign-Up & Modular AuthN/AuthZ Provisioning

**Feature**: `014-caregiver-signup`  
**Date**: 2026-11-22

---

## 1. Backend Verification (`elderly-microservices`)

### Run Unit & Integration Tests
```bash
cd /Users/zlgonzalez/Documents/code/kubo/elderly-microservices
go test ./internal/auth/... ./internal/institution/... ./test/integration/...
```

### Exercise the Caregiver Onboarding Endpoints via `curl` & Local Dev SMTP Server (`mailpit`)

0. **Start the Dev SMTP Server (`mailpit` in `docker-compose.yml`)**:
   ```bash
   cd /Users/zlgonzalez/Documents/code/kubo/elderly-microservices
   docker compose up -d mailpit
   ```
   - SMTP listens on `localhost:1025`; Web UI & REST API listen on `http://localhost:8025` (also started automatically by `./scripts/dev_stack.sh`).

1. **Initiate Caregiver Sign-Up**:
   ```bash
   curl -s -X POST http://localhost:8080/api/v1/auth/onboarding/initiate \
     -H "Content-Type: application/json" \
     -d '{"email": "jane.caregiver@example.com"}' | jq
   ```
   - Generates a 6-digit verification code (valid for 15 minutes) and dispatches the onboarding email via SMTP (`localhost:1025`) containing both the 6-digit code and the finalization link (`/signup/finalize?email=jane.caregiver%40example.com`).
   - Open `http://localhost:8025` in a browser (or query `curl -s http://localhost:8025/api/v1/messages | jq`) to inspect the delivered email in Mailpit, or use the dev verification code (`123456`) when `ALLOW_INSECURE_DEV_TOKENS=true`.

2. **Finalize Caregiver Sign-Up (Verify 6-Digit Code + Set Username & Password)**:
   ```bash
   curl -s -X POST http://localhost:8080/api/v1/auth/onboarding/finalize \
     -H "Content-Type: application/json" \
     -d '{
       "email": "jane.caregiver@example.com",
       "code": "123456",
       "username": "jane.caregiver",
       "password": "CaregiverPassword123!"
     }' | jq
   ```
   - Returns `{ "token": "<jwt>", "user": { "id": "...", "email": "jane.caregiver@example.com", "username": "jane.caregiver", "role": "caregiver", "is_email_verified": true, "needs_onboarding": false } }`.
   - Automatically provisions an active caregiver affiliation with `StandaloneInstitutionID` (`00000000-0000-0000-0000-000000000001`).

3. **Verify Immediate Authorization & Credential Login**:
   ```bash
   # Log in with the newly established caregiver username and password
   TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username": "jane.caregiver", "password": "CaregiverPassword123!"}' | jq -r .token)

   # Access protected caregiver endpoints immediately
   curl -s http://localhost:8080/api/v1/patients \
     -H "Authorization: Bearer $TOKEN" | jq
   ```

---

## 2. Mobile Verification (`elderly-mobile`)

### Run Analyzer & Widget/Unit Tests
```bash
cd /Users/zlgonzalez/Documents/code/kubo/elderly-mobile
flutter analyze
flutter test
```

### End-to-End Mobile User Flow
1. Open the Kubo North app and tap **Sign In with Credentials** to reach `LoginScreen` (`/login`).
2. Tap **Sign Up as Caregiver** (`Key('login_signup_button')`) to navigate to `/signup`.
3. Enter `jane.caregiver@example.com` and tap **Send Verification Email**.
4. Open the finalization link from the email (`/signup/finalize?email=jane.caregiver%40example.com`) or tap **Enter 6-Digit Code to Finalize** in the app.
5. Verify that `Email` is pre-populated (`jane.caregiver@example.com`) and the editable `Username` field is pre-filled with `jane.caregiver`.
6. Enter the 6-digit code, confirm or edit the `Username`, enter and confirm a password (8+ chars), and tap **Complete Sign Up**.
7. Confirm the caregiver is automatically authenticated and navigated directly to `/portal` with the default standalone resident active.
