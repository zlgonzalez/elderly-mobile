# Feature Specification: Reliable Long-Running Regimen Generation & Mobile Completion Delivery

**Feature Branch**: `013-fix-regimen-timeout-sync`  
**Created**: 2026-11-22  
**Status**: Draft  
**Input**: User description: "Regimen generation from the elderly-mobile app isn't working since it hit the 5 minute mark, but when you look at the logs, it shows that the regimen generation completed with a response. For some reason, the mobile app did not see it somehow. Not sure where the issue is, but it will be in one of these repositories. Ensure that this works."

## Clarifications

### Session 2026-11-22

- Q: What execution timeout budget should we enforce for a primary synthesis attempt and the overall batch job ceiling? → A: Keep the 5-minute (`300s`) job ceiling and expand the single-attempt timeout to `290s` (`10s` persistence headroom), only retrying fast transient failures when at least `240s` remains in the job budget.
- Q: How should inline clinical scorecard computation behave during `POST /regimen/generate`? → A: Use an adaptive budget guard: run bounded (`15s`) LLM scorecard evaluation when primary generation completes in `<=240s`, and immediately use the deterministic clinical scorecard when primary generation took `>240s`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete Single-Pass Regimen Generation Without Premature Attempt Abandonment (Priority: P1)

A caregiver initiates a 7-day Montessori activity regimen generation from the mobile application for an assigned resident. Even when the AI synthesis engine requires several minutes (e.g., 3 to 4.5 minutes) to produce and score a complete 7-day personalized plan, the system waits for that active generation pass to finish rather than prematurely abandoning the in-flight pass and spawning a competing retry that exhausts the 5-minute budget. As soon as synthesis finishes within the overall execution window, the completed regimen plan is persisted and delivered to the caregiver in the mobile app.

**Why this priority**: This directly resolves the primary failure where the AI synthesis engine successfully finishes generating a regimen in ~4 minutes, but the orchestration layer abandons the first attempt at 3 minutes, triggers a duplicate overlapping attempt, and fails the job at the 5-minute mark.

**Independent Test**: Can be independently tested by submitting a regimen generation job whose primary synthesis takes between 3 and 4.5 minutes and verifying that the job completes on the first pass without triggering a duplicate retry or failing at the 5-minute mark.

**Acceptance Scenarios**:

1. **Given** a caregiver submits a regimen generation request and the synthesis engine takes 3.5 to 4.5 minutes to return a valid 7-day regimen, **When** the synthesis response completes within the overall execution budget, **Then** the job transitions to `completed`, persists the resulting 7-day plan, and does not issue a duplicate synthesis request.
2. **Given** an in-flight synthesis pass is actively generating a regimen, **When** the elapsed time is still within the single-attempt execution window, **Then** the system does not cancel the request or start a second overlapping generation pass against the synthesis engine.
3. **Given** a synthesis attempt fails quickly with a transient error (e.g., connection refusal or immediate upstream failure) while sufficient time remains in the overall execution window for a full retry pass, **When** the system evaluates whether to retry, **Then** it retries only when the remaining execution budget is large enough to accommodate a complete synthesis pass.

---

### User Story 2 - Reliable Mobile Detection and Presentation of Completed Regimen Jobs (Priority: P1)

While a caregiver is viewing the mobile application after starting a regimen generation or refinement job, the mobile app continuously tracks the job until it reaches a terminal state (`completed` or `failed`) and reliably retrieves the completed regimen plan—even if a poll request experiences a transient delay, if the caregiver switches tabs or backgrounds/resumes the app, or if the job completes near the end of the execution window.

**Why this priority**: Even when the backend marks a batch job as `completed` and attaches the generated regimen plan, the caregiver cannot review or apply the schedule unless the mobile app reliably detects the terminal job transition and loads the associated plan payload.

**Independent Test**: Can be independently tested by running the mobile app against a batch job that transitions from `in_progress` to `completed` after several minutes of polling and verifying that the banner and preview/applied schedule update immediately in the UI.

**Acceptance Scenarios**:

1. **Given** a batch regimen job is tracked as active on the mobile app, **When** the job transitions to `completed` on the backend, **Then** the next mobile status check receives the completed job and its attached 7-day regimen plan, updates the batch banner to its completed state, and enables immediate preview or schedule refresh.
2. **Given** the mobile app is tracking a specific batch job ID and the active-job lookup returns empty or encounters a transient parsing/network issue, **When** the app reconciles job status, **Then** it falls back to querying the tracked job directly by its job ID so a completed or failed terminal transition is never missed.
3. **Given** a caregiver navigates between tabs (such as Care Tasks and Activity Guide) while a batch job completes, **When** the job reaches `completed`, **Then** the completion state and generated regimen plan are preserved and displayed consistently across screens without requiring an app restart.

---

### User Story 3 - Prompt Synthesis Efficiency & Graceful Timeout Handling (Priority: P2)

When generating a 7-day Montessori regimen, the AI synthesis service produces the required 7-day schedule and clinical scorecard as efficiently as possible so typical generations complete well inside the execution budget, and if an upstream synthesis request genuinely exceeds the maximum allowed window, it terminates cleanly without leaving orphaned background LLM work running after the job has already ended.

**Why this priority**: Reducing unnecessary synthesis latency and preventing orphaned overlapping LLM runs ensures predictable completion times under local and cloud model deployments.

**Independent Test**: Can be independently tested by measuring end-to-end regimen generation duration and verifying that canceled or timed-out upstream requests stop further evaluation work rather than continuing to run duplicate model invocations in the background.

**Acceptance Scenarios**:

1. **Given** a regimen generation request with inline clinical scorecard evaluation enabled, **When** the primary 7-day regimen synthesis finishes, **Then** the clinical scorecard is produced immediately (using deterministic clinical scoring when appropriate or bounded evaluation) without pushing total request time past the single-attempt deadline.
2. **Given** the requester disconnects or the batch job reaches its maximum execution deadline, **When** the synthesis service detects disconnection or timeout, **Then** no additional downstream evaluation or duplicate generation work is started for that abandoned request.

---

### Edge Cases

- **Synthesis completes between the 3-minute and 5-minute marks**: The single-attempt deadline must align with the overall execution budget so a valid 3.5–4.5 minute synthesis response is accepted and persisted rather than killed at 3 minutes and retried with insufficient remaining time.
- **Insufficient remaining budget for a retry**: If a primary synthesis attempt fails when too little time remains in the overall job ceiling to complete another full synthesis pass, the system must not start a doomed retry that overloads the AI engine; it should immediately proceed to configured fallback or fail cleanly with actionable guidance.
- **Active-job endpoint returns null or omits plan details after completion**: If the active-job query does not include the tracked job or its embedded plan payload, the mobile client must query the specific tracked job ID (and plan ID if needed) before concluding the job disappeared.
- **Overlapping requests on single-GPU/local model servers**: Retrying while a previous slow LLM call is still executing on the model server doubles inference time; attempt timeouts and retry guards must prevent overlapping primary synthesis calls for the same job.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The batch regimen orchestration service MUST default to a `290s` single-attempt synthesis timeout within the `300s` (5-minute) job execution ceiling (leaving `10s` persistence headroom) so synthesis runs completing in 3 to 4.8 minutes are not prematurely canceled at 3 minutes.
- **FR-002**: The batch regimen orchestration service MUST NOT trigger a retry attempt unless the previous attempt failed with a transient error and at least `240s` of remaining execution budget exists before the job execution ceiling.
- **FR-003**: When a synthesis attempt completes with a valid 7-day schedule before the job execution ceiling expires, the system MUST persist the generated regimen plan, transition the batch job to `completed` with the associated `plan_id` and embedded plan payload, and expose it immediately to status queries.
- **FR-004**: The active and by-ID batch job status endpoints MUST always return the most recent terminal (`completed` or `failed`) undefeated/undismissed batch job for a resident along with its hydrated 7-day regimen plan when `status` is `completed`.
- **FR-005**: The mobile application MUST poll active batch jobs and, if the active-job lookup returns empty or lacks the hydrated plan for a known in-flight `job_id`, MUST query the batch job directly by `job_id` so terminal completion or failure states are never silently lost.
- **FR-006**: When a polled batch job transitions to `completed` with an attached regimen plan, the mobile application MUST immediately update the caregiver's UI state (showing the ready-for-review banner or refreshing applied tasks) without requiring manual screen reload.
- **FR-007**: The AI regimen synthesis service MUST use an adaptive budget guard for inline clinical scorecard evaluation—running bounded (`15s`) LLM scorecard evaluation when primary generation finishes in `<=240s` and immediately using the deterministic clinical scorecard when primary generation exceeds `240s`—so scorecard computation never pushes a completed 7-day regimen past the `290s` attempt window.
- **FR-008**: Local development stack defaults and runtime configuration MUST configure aligned timeout budgets across the mobile client, backend batch worker, and AI synthesis service so end-to-end local regimen generation succeeds reliably.
- **FR-009**: The AI regimen synthesis service (`kubo-agents`) MUST configure application-level `INFO` logging and emit phase-by-phase duration logs for each step of regimen generation (context/RAG retrieval, prompt construction, primary LLM synthesis, schedule mapping/normalization, scorecard evaluation with mode `llm` vs. `heuristic`, and total request duration) so operators can determine where execution time is spent from `kubo-agents.log`.
- **FR-010**: While a batch regimen generation or refinement job is queued or in progress, the mobile application (`elderly-mobile`) MUST remain non-blocking—allowing users to freely navigate across all tabs, switch residents, and interact with existing care tasks while background polling tracks job progress and surfaces completion notifications and review banners across the app.
- **FR-011**: The mobile application (`elderly-mobile`) MUST render both the post-generation 7-day regimen preview panel (`RegimenPreviewSheet`) and the post-apply activity review panel (`CareTasksScreen` task detail sheet) using the official Dart A2UI v1.0 renderer (`a2ui_flutter` + `a2ui_core`) with a dedicated Kubo Regimen A2UI catalog (`RegimenClinicalScorecard`, `RegimenDaySchedule`, `RegimenActivityCard`), normalizing facilitation step text to strip redundant leading numbers (preventing `"1. 1. ..."` duplication) and presenting structured headings, checkable tray materials, and clinical guidance callouts.
- **FR-012**: The AI regimen synthesis service (`kubo-agents`) MUST pass a lean LLM `response_schema` (`LeanMontessoriRegimenOutput`) containing only `safety_flags`, `emergency_escalation_required`, and `weekly_regimen` (with only the activity fields consumed by the backend and mobile app) to minimize output tokens and synthesis latency while preserving backward-compatible `MontessoriRegimenOutput` conversion on the REST response.

### Key Entities *(include if feature involves data)*

- **Regimen Batch Job**: Represents an asynchronous 7-day regimen generation or refinement request for a resident, tracking `id`, `patient_id`, `status` (`queued`, `in_progress`, `completed`, `failed`, `canceled`), `phase`, `retry_count`, `plan_id`, `error_message`, timestamps, and the hydrated result plan.
- **Generated Regimen Plan**: The resulting 7-day Montessori activity schedule (`preview` or `applied`), including daily activity items, synthesis notes, safety flags, and clinical scorecard.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of regimen generation jobs whose primary AI synthesis finishes within the configured execution window (up to 5 minutes) transition to `completed` on the first pass without being canceled by a premature mid-window attempt timeout.
- **SC-002**: 0 duplicate overlapping synthesis requests are sent to the AI synthesis engine for the same batch job while an active synthesis attempt is still within its execution budget.
- **SC-003**: Within 1 polling interval (3 seconds) of a batch job reaching `completed` in the backend logs, the mobile app displays the completed regimen state and allows the caregiver to preview or view the applied 7-day schedule in 100% of test runs.
- **SC-004**: When a batch job genuinely exceeds the maximum execution ceiling or encounters an unrecoverable error, the mobile app transitions out of the `in_progress` state within 1 polling interval and presents clear recovery options (retry or apply clinical baseline).

## Assumptions

- Local and self-hosted LLM deployments (such as 14B-parameter models) can take 3 to 4.5 minutes to synthesize a complete 7-day Montessori JSON schedule, whereas the previous 3-minute per-attempt cutoff (`180s`) inside a 5-minute (`300s`) ceiling guaranteed that any 3–5 minute generation would be canceled at 3 minutes and fail its retry at 5 minutes.
- A generous default execution window (at least 5 to 6 minutes for a single primary attempt and aligned overall job ceiling) combined with fast deterministic/bounded scorecard evaluation ensures single-pass completion without premature retries.
- Existing batch job endpoints (`POST /api/v1/activities/plan/jobs`, `GET /api/v1/activities/plan/jobs/active`, `GET /api/v1/activities/plan/jobs/{jobId}`) remain the contract between `elderly-mobile` and `elderly-microservices`.
