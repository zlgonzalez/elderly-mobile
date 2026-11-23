# Feature Specification: Caregiver Sign-Up for Kubo North Service

**Feature Branch**: `014-caregiver-signup`  
**Created**: 2026-11-22  
**Status**: Draft  
**Input**: User description: "Create support for signing up for the kubo north service for the caregiver persona. The caregiver persona will be able to click on the sign up button in the login page. The user will have to sign up their email address, then after the onboarding microservice receives it, it will send an email that will generate an email with a 6-digit code. This email will contain a link to finalize the sign-up in the app and add a password. After providing the password, that will setup the caregiver user name and password."

## Clarifications

### Session 2026-11-22

- Q: How should the caregiver's username be established when they finalize sign-up? → A: Include an editable "Username" field on the finalization screen (pre-filled with the email prefix) alongside the password field so the caregiver explicitly confirms or customizes their username.
- Q: After the caregiver enters the valid 6-digit code, confirms/customizes their username, and submits their password on the finalization screen, what should happen next in the app? → A: Auto-login on finalization and navigate directly into the signed-in Kubo North app experience.
- Q: How should the finalization link and the 6-digit code work together when opening the app's finalization screen? → A: Link opens the finalization screen with email pre-populated and the user enters the 6-digit code from the email (and can also reach the finalization screen directly in-app after step 1).
- Q: What resident/care context should a newly signed-up caregiver be placed in when landing in the app after finalizing sign-up? → A: Default to the standalone care context and existing default resident profile (keep "Add New Patient" UI out of scope for this feature).
- Q: How should email delivery of the 6-digit verification code and finalization link behave across production vs. local/dev/test environments? → A: Pluggable email sender (SMTP when configured; local dev outbox/log capture + dev OTP fallback in local/test mode so E2E sign-up works out of the box).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Caregiver Initiates Email Sign-Up from Login Page (Priority: P1)

A prospective caregiver opens the Kubo North application, navigates to the login screen, and selects the "Sign Up" option to create a new caregiver account. The caregiver enters their email address and submits the initial registration request. The onboarding service receives the email address, creates or updates a pending caregiver onboarding record, generates a 6-digit verification code and an in-app finalization link, and sends an email containing both the 6-digit code and the link to the caregiver's email address. The application confirms that the verification email has been sent and guides the caregiver to check their inbox or proceed to verification.

**Why this priority**: Initiating sign-up from the login page and delivering the 6-digit verification code and deep link via email is the entry point for caregiver self-onboarding; without it, no caregiver can begin registration.

**Independent Test**: Can be fully tested by clicking the "Sign Up" button on the login screen, submitting a valid unregistered email address, and confirming that the onboarding service records a pending caregiver sign-up, generates a 6-digit verification code and finalization link, and dispatches the verification email.

**Acceptance Scenarios**:

1. **Given** an unauthenticated user on the Kubo North login page, **When** they click the "Sign Up" button, **Then** the application displays the caregiver email sign-up view.
2. **Given** a caregiver on the email sign-up view, **When** they enter a valid, unregistered email address and submit, **Then** the onboarding service accepts the request, generates a 6-digit verification code and a finalization link, sends the onboarding email to that address, and the app transitions to a state instructing the user to check their email and enter their verification code.
3. **Given** a caregiver on the email sign-up view, **When** they enter a malformed email address (e.g., missing `@` or domain), **Then** the application prevents submission and displays a clear validation error message.
4. **Given** an email address that already belongs to a fully finalized account, **When** submitted for caregiver sign-up, **Then** the onboarding service rejects duplicate account creation and informs the user that the account is already registered or directs them to sign in.

---

### User Story 2 - Caregiver Finalizes Sign-Up via Email Link, 6-Digit Code, and Password Setup (Priority: P1)

After receiving the onboarding email, the caregiver clicks the finalization link in the email (or navigates directly from the step-1 confirmation state in the app). The link opens the Kubo North application on the sign-up finalization screen with their email pre-populated and an editable "Username" field pre-filled with their email prefix. The caregiver manually enters the 6-digit code from the email, confirms or customizes their username, and provides a password to complete registration. Upon submission, the onboarding service validates the 6-digit code against the pending email sign-up, sets up the caregiver's confirmed username and password credentials with the `caregiver` persona role, marks the email address as verified, and completes account setup so the caregiver can access the Kubo North service.

**Why this priority**: Finalizing the account with the 6-digit verification code and setting the caregiver's username and password completes the core end-to-end value of caregiver sign-up.

**Independent Test**: Can be fully tested by opening the finalization link from the verification email, confirming the 6-digit code, confirming or customizing the pre-filled username, entering a compliant password, submitting the form, and verifying that the caregiver account is created with verified email status and working username and password credentials.

**Acceptance Scenarios**:

1. **Given** a caregiver has received the onboarding email containing a 6-digit code and finalization link, **When** they open the link, **Then** the Kubo North app opens directly to the sign-up finalization screen displaying an editable username field pre-filled with the email local-part prefix alongside fields for the 6-digit code and password.
2. **Given** a caregiver on the sign-up finalization screen with a valid, unexpired 6-digit code for their email address, **When** they confirm or edit their username and submit a valid password, **Then** the onboarding service establishes the caregiver's chosen username and password, assigns the `caregiver` role, marks the caregiver's email as verified, issues an authenticated session, and navigates the caregiver directly into the signed-in Kubo North app experience.
3. **Given** a caregiver who has completed sign-up finalization and later signs out, **When** they sign in on the login page using their established caregiver username (or email) and password, **Then** authentication succeeds and grants access to the Kubo North caregiver experience.
4. **Given** a caregiver on the sign-up finalization screen, **When** they enter an empty/duplicate username or a password that fails minimum security criteria or mismatched password confirmation, **Then** the form prevents submission and explains the validation requirements.

---

### User Story 3 - Resending Verification Code and Handling Invalid or Expired Codes (Priority: P2)

A caregiver whose verification email was delayed, lost, or expired—or who mistypes the 6-digit code during finalization—can understand why verification failed and request a new 6-digit code and finalization link without losing their place in the sign-up flow.

**Why this priority**: Email delivery delays and mistyped 6-digit codes are common in real-world onboarding; recovery ensures caregivers are not permanently blocked from completing registration.

**Independent Test**: Can be tested independently by submitting an incorrect or expired 6-digit verification code on the finalization screen, verifying that an error message is shown and no password/account is finalized, and triggering a resend request that issues a new 6-digit code and invalidates the previous code.

**Acceptance Scenarios**:

1. **Given** a pending caregiver sign-up for an email address, **When** the user submits an incorrect or expired 6-digit code with their password, **Then** the onboarding service rejects the finalization request with a clear error message and does not activate the credentials.
2. **Given** a pending caregiver sign-up, **When** the caregiver requests to resend the verification email (or re-submits the same unverified email address), **Then** the onboarding service invalidates any previous 6-digit code for that email, generates a new 6-digit code and finalization link, and sends a fresh email.

---

### Edge Cases

- **Duplicate submission of an already-pending email**: If a caregiver submits an email address that already has an incomplete/pending sign-up, the system issues a fresh 6-digit verification code and finalization email rather than locking the email address permanently.
- **Expired or already-used 6-digit code**: Codes expire after a defined validity window (15 minutes) and are single-use; attempting to reuse a code after finalization fails with a clear message directing the caregiver to sign in.
- **Repeated invalid code attempts (brute-force protection)**: After 5 consecutive failed verification attempts for a pending sign-up code, the active 6-digit code is invalidated and the caregiver must request a new verification email.
- **Opening the finalization link on a device where the app is closed or backgrounded**: The finalization link routes into the app's finalize sign-up screen with the caregiver's email context preserved; if the caregiver switches devices or enters manually from the verification screen, they can also type the 6-digit code and password directly in the app.
- **Case-insensitive and whitespace-trimmed email/username handling**: Leading/trailing whitespace and mixed-case characters in the email address (e.g., `CareGiver@Example.com `) are normalized to lowercase trimmed form before generating the verification email or setting up the caregiver username.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001 (Login Page Sign-Up Entry Point)**: The Kubo North login page MUST provide a visible "Sign Up" interactive control that navigates unauthenticated users to the caregiver sign-up flow.
- **FR-002 (Email-First Caregiver Sign-Up Initiation)**: The caregiver sign-up flow MUST collect and validate the caregiver's email address and submit an onboarding initiation request for the `caregiver` persona.
- **FR-003 (6-Digit Verification Code & Finalization Link Generation)**: Upon receiving a valid caregiver sign-up email request for an unregistered (or pending unverified) email address, the onboarding service MUST generate a cryptographically random 6-digit numeric verification code and an application finalization link associated with that email address.
- **FR-004 (Onboarding Verification Email Delivery & Local Outbox Fallback)**: The onboarding service MUST send an email to the caregiver's email address containing both the 6-digit verification code and the link to open the app and finalize sign-up via a pluggable email transport (using configured external email delivery in production/staging and falling back to local outbox/log capture plus dev OTP allowance when local dev mode is enabled).
- **FR-005 (Code Expiration & Single-Use Lifecycle)**: Each generated 6-digit verification code MUST have a bounded validity window (15 minutes), MUST be single-use, and MUST be superseded whenever a newer verification code is generated for the same email address.
- **FR-006 (In-App Finalization via Email Link or Direct Navigation)**: The application MUST support opening the finalization screen from the email link (with the associated email address pre-populated and the editable username pre-filled with the email local-part prefix, without embedding the secret 6-digit code in the URL) as well as navigating directly to the finalization screen from the step-1 email-submission confirmation view so the caregiver can manually enter the 6-digit code and choose a password.
- **FR-007 (Username & Password Validation on Finalization)**: During sign-up finalization, the screen MUST display an editable username field pre-filled with the email address local-part prefix, and the user MUST provide a valid 6-digit verification code, a non-empty unique username (3 to 64 characters), and a password meeting minimum security requirements (at least 8 characters) with password confirmation matching.
- **FR-008 (Caregiver Username & Password Provisioning & Auto-Login)**: Upon successful verification of the 6-digit code, username, and password during finalization, the onboarding service MUST provision and activate the caregiver account with the `caregiver` role, persist the caregiver's confirmed/customized username and password credentials, mark the caregiver's email address as verified, authorize the caregiver across standalone care residents (including patient profile retrieval and regimen generation) via their standalone care context affiliation, and return an authenticated session associated with the default standalone care context and default active resident profile so the application navigates the caregiver directly into a functional signed-in Kubo North portal.
- **FR-009 (Post-Finalization Authentication Compatibility & Sign-Out)**: Once sign-up finalization succeeds, the caregiver MUST be able to sign out from the application header and re-authenticate into the Kubo North service on the login page using their established caregiver username (or email address) and password.
- **FR-010 (Duplicate Account Protection)**: If a sign-up initiation request is submitted for an email address that already belongs to a finalized account, the system MUST prevent overwriting the existing account credentials and surface an appropriate response.
- **FR-011 (Verification Retry & Resend Support)**: The caregiver MUST be able to request a new verification email containing a fresh 6-digit code and finalization link if the previous email was not received or the code expired, and the system MUST invalidate the prior code upon generating the new one.
- **FR-012 (Audit Trail for Caregiver Onboarding)**: The system MUST record audit events for caregiver sign-up initiation (verification email/code issued) and caregiver sign-up finalization (account credentials established and email verified).

### Key Entities *(include if feature involves data)*

- **Pending Caregiver Onboarding / Verification Record**: Represents an in-progress caregiver sign-up associated with a normalized email address, a hashed or stored 6-digit verification code, expiration timestamp, failed-attempt counter, target persona role (`caregiver`), and finalization status.
- **Caregiver User Account**: Represents the finalized caregiver identity in the Kubo North service, including unique identifier, verified email address, established username, password hash/credentials, assigned `caregiver` role, and onboarding completion status.
- **Onboarding Verification Email**: Represents the outbound communication sent to the prospective caregiver containing the 6-digit numeric verification code and the deep link/application URL to finalize sign-up and set a password.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of prospective caregivers can initiate email sign-up from the login screen and finalize their username and password within 2 minutes of receiving the verification email.
- **SC-002**: 100% of valid caregiver sign-up initiation requests trigger generation of a 6-digit code and finalization link within 3 seconds of submission.
- **SC-003**: 100% of finalized caregiver accounts can immediately sign in on the Kubo North login page using their established username and password on the first attempt.
- **SC-004**: 100% of expired, already-used, or mismatched 6-digit verification codes are rejected without creating or modifying caregiver credentials.

## Assumptions

- **Target Persona & Post-Signup Care Context Scope**: This sign-up flow specifically targets the `caregiver` persona signing up for the Kubo North service from the login screen; administrator (`admin`) accounts remain restricted from self-registration. Upon finalizing sign-up, the caregiver defaults to the standalone care context with the default resident profile active (and access to the existing Resident Switcher); adding a new patient/resident UI workflow is out of scope for this feature.
- **Caregiver Username Establishment**: On the finalization screen, the caregiver is presented with an editable "Username" field pre-filled with the local-part prefix of their verified email address (e.g., `jane.doe` for `jane.doe@example.com`), allowing them to confirm the default or customize their username alongside setting their password. The login screen accepts either the established username or full email address with the caregiver's password.
- **Verification Code Validity & Rate Limits**: Standard industry defaults apply: 6-digit numeric codes are valid for 15 minutes, at most 5 failed verification attempts are permitted per code before requiring a resend, and resending a code invalidates prior codes for that email.
- **Local/Development Email Delivery**: In production/staging environments with an email provider configured, the onboarding microservice sends the verification email via the configured email transport; in local development or automated test environments without an external mail server, the generated 6-digit code and finalization link are logged/captured by the local email adapter (and respect local dev OTP configuration when enabled) so end-to-end verification works out of the box.
