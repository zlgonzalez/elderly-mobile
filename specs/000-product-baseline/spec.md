# Product Baseline Specification: Kubo Elderly Mobile (Montessori Care App)

**Feature ID**: `000-product-baseline`  
**Status**: Canonical Living Baseline (Reverse-Engineered from Shipped Code)  
**Architectural Companion**: `.specify/memory/blueprint.md`

> This specification is the canonical behavioral source of truth ("What") for currently shipped functionality. Implementation structure, file paths, frameworks, and subsystem dependencies live in `.specify/memory/blueprint.md`.

---

## 1. User Roles & Actors

| Role | Description | Key Capabilities |
| :--- | :--- | :--- |
| **Family Member** (`familyMember`) | Relative linked to a resident profile | Sign in (demo or credentials), view Family Portal & Their Story, add/delete memories, log mood entries, view/manage care tasks and regimens, log vitals and meals, browse Montessori activities, ask Kubo AI |
| **Visiting Caregiver** (`visitingCaregiver`) | Care staff member supporting residents | Same care, clinical, activity, and AI workflows as Family Member, with caregiver attribution on recorded entries |
| **Administrator** (`admin`) | Facility/platform administrator | Full access across resident profiles, demo resets, and care/clinical workflows |

*(Note: Client-side route guards enforce authentication vs. unauthenticated access, while fine-grained per-role action restrictions are not yet differentiated in the mobile UI `[NEEDS CLARIFICATION: whether family members should be restricted from clinical vitals editing or regimen approval on the client]`.)*

---

## 2. Domain 1: Authentication, Session Access & Server Configuration

### Requirements

- **FR-001 (Authentication Gate):** Unauthenticated users MUST be redirected to the demo login entry screen when attempting to access any protected care tab or resident story screen. Authenticated users navigating to the demo login or credential login screen MUST be redirected to the Family Portal.
- **FR-002 (Demo Profile Login):** The application MUST present available demo accounts (with resident linkage and role metadata) and allow one-tap sign-in into a selected demo profile.
- **FR-003 (Credential Login & Error Handling):** Users MUST be able to sign in with username and password. Invalid credentials MUST keep the user unauthenticated and display a user-facing error message (`Invalid username or password` or the underlying server error).
- **FR-004 (Logout):** Authenticated users MUST be able to sign out, clearing the active user session and returning to the unauthenticated state.
- **FR-005 (Environment & Mock/Live Mode):** The application MUST support `Local Dev`, `UAT / Staging`, and `Production` environment presets, and toggle seamlessly between offline mock data mode and live backend API mode.
- **FR-006 (Configurable API Base URL):** Users MUST be able to open Server Settings from the login screens or resident header to view, test, save, or reset a custom API base URL.
- **FR-007 (URL Normalization & Validation):** Custom server URLs MUST be validated before testing or saving: empty strings and inputs containing spaces MUST be rejected with a clear validation message. Shorthand host/IP inputs without a scheme MUST normalize by prepending `http://`, defaulting to port `:8080`, appending `/api/v1` when no path is provided, and stripping trailing slashes.
- **FR-008 (Post-Save Context Refresh):** Saving a valid custom API base URL MUST persist the override across app restarts, invalidate cached demo accounts, re-authenticate the active demo user if signed in, and refresh the active resident profile.

### Acceptance Scenarios

- **Given** an unauthenticated user attempts to open Care Tasks or Their Story, **When** navigation resolves, **Then** the user is redirected to the Demo Login screen.
- **Given** a user enters `192.168.1.50` in Server Settings and taps Save, **When** validation succeeds, **Then** the URL is normalized to `http://192.168.1.50:8080/api/v1`, persisted locally, and active demo/resident data is refreshed.
- **Given** a user enters `http://bad host` in Server Settings, **When** they tap Test Connection or Save, **Then** the form blocks submission and displays `Server URL cannot contain spaces`.

---

## 3. Domain 2: Resident Profiles, Family Portal & Their Story

### Requirements

- **FR-009 (Active Resident Switching):** Authenticated users MUST be able to switch between available resident profiles (including demo profiles Margaret, Robert, and Dorothy in mock mode) and have all care, clinical, mood, memory, and activity views update to the selected resident.
- **FR-010 (Demo State Reset):** Users MUST be able to reset demo data from the resident switcher, restoring default tasks, memories, vitals, meals, moods, and resident attributes.
- **FR-011 (Their Story Life Portrait):** Users MUST be able to open a dedicated full-screen Their Story view displaying the active resident's biography, personal quote, education, interests, life milestones timeline, medical conditions, allergies, and emergency/family contacts.
- **FR-012 (Family Portal Overview & Wellbeing Alerts):** The Family Portal MUST present the resident header, a wellbeing alert banner, and at-a-glance care/activity summary cards. `[NEEDS CLARIFICATION: the Family Portal wellbeing alert banner currently renders static lunch-intake copy and a navigation snackbar rather than dynamically binding to live abnormal vitals or low-intake meal state]`
- **FR-013 (Responsive Shell Navigation):** The application MUST provide 6 primary care destinations (Family Portal, Memory Box, Mood Journal, Care Tasks, Health & Vitals, Activity Guide), adapting between a persistent sidebar on wide viewports and bottom navigation on compact viewports, while preserving tab state across switches.

### Acceptance Scenarios

- **Given** an authenticated user is viewing Margaret's Family Portal, **When** they switch to Robert via the Resident Switcher, **Then** the active resident context updates to Robert across all six primary tabs.
- **Given** an authenticated user taps Their Story, **When** the screen opens, **Then** the resident's biography, milestones, interests, conditions, and allergies are displayed.

---

## 4. Domain 3: Care Tasks & Weekly Montessori Regimen Planning

### Requirements

- **FR-014 (Care Task Management):** Users MUST be able to view care tasks for the active resident, filter tasks by category (`Physical`, `Activity`, `Social`, `Purposeful`), create new tasks, and update task status across `pending`, `inProgress`, `completed`, and `skipped` (with optional completion attribution, notes, or skip reason).
- **FR-015 (Weekly Regimen Generation & Lifecycle Phases):** Users MUST be able to generate a personalized 7-day Montessori regimen for the active resident, tracking generation progress through `idle`, `retrieval`, `synthesis`, `refinement`, `scoring`, and `completed` phases, and capturing resident cognitive/physical capabilities when needed.
- **FR-016 (Asynchronous Batch Regimen Jobs):** Users MUST be able to enqueue weekly regimen generation or refinement as an asynchronous background batch job (`queued`, `in_progress`, `completed`, `failed`, `canceled`), view live job progress in a persistent banner across Care Tasks and Activity Guide, cancel an active job, or dismiss a finished job. Only one active batch job per resident MUST be permitted at a time; conflicting requests MUST surface a conflict error referencing the active job.
- **FR-017 (Regimen Preview, Iterative Refinement & Immediate Baseline Fallback):** Generated regimens MUST support previewing activities grouped by day (days 1–7) alongside synthesis notes and clinical scorecard metrics, submitting natural-language refinement instructions, or falling back to an immediate clinical baseline plan when needed.
- **FR-018 (Clinical Safety & Low-Score Gates):**
  - A regimen plan flagged with `emergencyEscalationRequired` or containing a `CRITICAL`, `EMERGENCY`, or `ESCALAT` safety flag MUST be treated as having a critical safety block.
  - A regimen plan with a clinical scorecard `compositeScore < 70` MUST require explicit low-score confirmation (`acknowledgeLowScore`) before being applied to the resident's schedule.

### Acceptance Scenarios

- **Given** a resident has no active batch job, **When** a caregiver enqueues weekly regimen generation, **Then** the job enters `queued`/`in_progress`, displays a progress banner, and upon `completed` allows opening the 7-day regimen preview.
- **Given** a generated regimen has a clinical scorecard composite score of `62`, **When** the caregiver attempts to apply the plan, **Then** the system flags `requiresLowScoreConfirmation` and requires explicit acknowledgment before applying tasks.
- **Given** a caregiver updates a care task status to `skipped` with a skip reason, **When** saved, **Then** the task reflects `skipped` status in the resident's task list.

---

## 5. Domain 4: Health Vitals & Meal/Nutrition Tracking

### Requirements

- **FR-019 (Health Vitals Recording & History):** Users MUST be able to view historical vital signs (blood pressure, heart rate, temperature, optional weight, mobility level, pain level, recorder, and clinical notes) and record new vital-sign readings for the active resident.
- **FR-020 (Abnormal Vitals Clinical Thresholds):** A recorded vital sign MUST be flagged as abnormal whenever ANY of the following thresholds is met:
  - Systolic blood pressure `>= 140` mmHg or diastolic blood pressure `>= 90` mmHg,
  - Heart rate `> 100` bpm or `< 55` bpm,
  - Temperature `> 100.4` °F or `< 96.0` °F,
  - Pain level `>= 7`.
- **FR-021 (Food Library & Custom Foods):** Users MUST be able to browse and search the food library by keyword and category, select foods to compose a meal, and add custom food items with nutritional values.
- **FR-022 (Meal Logging, Intake Scaling & Low-Intake Flag):** Users MUST be able to log meals by meal type (`Breakfast`, `Lunch`, `Dinner`, `Snack`) with expected and actual intake percentages. Consumed calories, protein, carbohydrates, and fat MUST scale proportionally by the actual intake percentage against daily nutrition targets (calories, protein, carbs, fat, fluid ml). Any meal with `actualIntakePercent <= 50` MUST be flagged as low intake.

### Acceptance Scenarios

- **Given** a caregiver records vitals with blood pressure `145/88`, heart rate `76`, temperature `98.6`, and pain `2`, **When** evaluated, **Then** the vital sign is flagged as abnormal due to systolic pressure `>= 140`.
- **Given** a caregiver logs a Lunch meal with `actualIntakePercent = 50`, **When** saved, **Then** consumed nutrients are scaled to 50% of the plated food items and the meal is flagged as low intake (`isLowIntake == true`).

---

## 6. Domain 5: Mood Journal, Memory Box, Activity Guide & Kubo AI Assistant

### Requirements

- **FR-023 (Mood Journal & Weekly Trends):** Users MUST be able to log mood entries for the active resident using the six supported mood states (`happy`, `content`, `neutral`, `sad`, `anxious`, `upset`) with optional notes, view chronological mood history, and inspect weekly mood frequency trends.
- **FR-024 (Memory Box):** Users MUST be able to browse shared family memories for the active resident, inspect full memory details, create new memory entries, and delete existing memories.
- **FR-025 (Montessori Activity Guide):** Users MUST be able to browse and filter curated Montessori activities across five categories (`Practical Life`, `Cognitive`, `Creative`, `Sensory`, `Social`) and by search query, viewing duration, materials, step-by-step instructions, why it matters, dignity tips, safety comfort notes, and script prompts.
- **FR-026 (Contextual Kubo AI Assistant):** Users MUST be able to open the Kubo AI Assistant drawer from any primary care tab, receiving responses tailored to the active resident and current screen context via streaming or single-shot replies.

### Acceptance Scenarios

- **Given** a family member logs a `content` mood entry with a note, **When** submitted, **Then** the entry appears in the resident's mood history and updates the weekly trends counts.
- **Given** a caregiver opens the Kubo AI Assistant while on the Health & Vitals tab, **When** they submit a question, **Then** the assistant includes both the active resident context and the `Health & Vitals` screen context in the request and streams the reply into the drawer.

---

## 7. Domain 6: Telemetry, Privacy & Observability

### Requirements

- **FR-027 (W3C Distributed Tracing & Route Sanitization):** Outgoing HTTP requests MUST attach a W3C `traceparent` header (`00-<traceId>-<spanId>-01`) when absent and emit network tracing telemetry with UUIDs and numeric path segments replaced by `{id}` placeholders.
- **FR-028 (Zero-PII Telemetry Sanitization):** Before any telemetry payload is buffered or dispatched, sensitive keys (passwords, tokens, secrets, auth headers, names, email, phone, SSN/government IDs, clinical notes, diagnosis, medical history) MUST be recursively redacted to `[REDACTED]`, while user/account/caregiver/admin identifiers MUST be pseudonymized using HMAC-SHA256. Query parameters MUST be stripped from sanitized URLs.
- **FR-029 (Category Sampling & Remote/Debug Overrides):** Telemetry collection MUST gate events by category (`CRASH_AND_EXCEPTIONS`, `NETWORK_TRACING`, `UI_INTERACTIONS`, `LOCAL_DATA_OPS`, `BUSINESS_EVENTS`) using configurable enablement, sample rates (`0.0–1.0`), and Wi-Fi-only flags, supporting remote config updates and temporary debug overrides.
- **FR-030 (Bounded Buffering & Batched Delivery):** Telemetry events MUST be stored in a bounded ring buffer capped at `5 MB` (evicting lowest-priority events when full) and flushed in compressed batches (default batch size `50`, flush interval `30s`) with backoff on dispatch failure.

### Acceptance Scenarios

- **Given** a telemetry event payload contains `patient_name: "Margaret"`, `clinical_notes: "Elevated BP"`, and `caregiver_id: "cg_123"`, **When** sanitized prior to buffering, **Then** `patient_name` and `clinical_notes` are replaced with `[REDACTED]` and `caregiver_id` is replaced with its deterministic HMAC-SHA256 hex digest.
- **Given** the local telemetry buffer reaches its `5 MB` limit, **When** a new crash event arrives, **Then** lower-priority buffered events are evicted to preserve the memory cap without crashing the app.

---

## 8. Domain 7: Reliable Batch Regimen Delivery & A2UI Review Surfaces

### Requirements

- **FR-031 (Direct-by-Job-ID Fallback Polling & Non-Blocking Completion Delivery):** While a batch regimen job is active, caregivers MUST be able to navigate freely across all tabs and switch residents without blocking modals. If `getActiveBatchJob` returns `null` or omits the hydrated `plan` for a known in-flight `job_id`, the app MUST fall back to `getBatchJob(residentId, jobId)` (and hydrate missing plans via `GET /activities/plan/{planId}`) so terminal completion or failure transitions are delivered reliably within one polling interval.
- **FR-032 (A2UI v1.0 Regimen Review Panels & Step Normalization):** Both the post-generation 7-day regimen preview sheet (`RegimenPreviewSheet`) and the post-apply care task detail sheet (`CareTasksScreen`) MUST render through the official Dart A2UI v1.0 renderer (`a2ui_flutter` + `a2ui_core`) using the Kubo Regimen A2UI catalog (`RegimenClinicalScorecard`, `RegimenDaySchedule`, `RegimenActivityCard`). Facilitation steps MUST strip redundant leading numbering prefixes (preventing `"1. 1. ..."` duplication) and display numbered step badges, checkable tray materials, and clinical guidance callouts.

### Acceptance Scenarios

- **Given** an in-flight batch regimen job where `getActiveBatchJob` returns `null` right as the backend finishes, **When** the next poll ticks, **Then** the app falls back to `getBatchJob(residentId, jobId)`, emits the completion event, and stages the hydrated preview plan without losing the result.
- **Given** a generated or applied activity whose facilitation steps contain `"1. Prepare Tray & Seating: ..."`, **When** opened in either the regimen preview or task detail sheet, **Then** the A2UI surface renders a single numbered badge (`1`) with bold heading `Prepare Tray & Seating` and never displays `"1. 1."`.
