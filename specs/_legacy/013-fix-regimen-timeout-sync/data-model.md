# Phase 1 Data Model: Reliable Long-Running Regimen Generation & Mobile Completion Delivery

**Feature**: `013-fix-regimen-timeout-sync`  
**Date**: 2026-11-22

---

## 1. Entities & Runtime Models

### 1.1 `RegimenBatchJob` (`elderly-microservices` & `elderly-mobile`)

Persisted in PostgreSQL table `activity.regimen_batch_jobs` (no schema migration required; existing columns support all fields):

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Unique batch job identifier |
| `patient_id` | `UUID` | Target resident/patient UUID |
| `requested_by` | `UUID` | Caregiver/Admin user UUID who initiated the job |
| `job_type` | `BatchJobType` (`generation` \| `refinement`) | Type of asynchronous regimen operation |
| `status` | `BatchJobStatus` (`queued` \| `in_progress` \| `completed` \| `failed` \| `canceled`) | Lifecycle state |
| `phase` | `BatchJobPhase` (`retrieval` \| `synthesis` \| `refinement` \| `scoring` \| `completed` \| `failed` \| `canceled`) | Current execution phase |
| `target_plan_id` | `*UUID` | Target plan UUID when `job_type = refinement` |
| `plan_id` | `*UUID` | Persisted result `ActivityPlan` UUID when `status = completed` |
| `plan` | `*ActivityPlan` / `RegimenPlan?` | Hydrated 7-day regimen plan returned on `completed` jobs |
| `retry_count` | `int` | Number of primary synthesis retries executed |
| `error_message` | `string` | Actionable failure message when `status = failed` |
| `created_at` | `TIMESTAMPTZ` | Job creation timestamp (anchor for `300s` job execution ceiling) |
| `started_at` | `*TIMESTAMPTZ` | Worker start timestamp |
| `completed_at` | `*TIMESTAMPTZ` | Terminal transition timestamp (`completed`, `failed`, `canceled`) |
| `dismissed_at` | `*TIMESTAMPTZ` | Timestamp when caregiver dismissed or applied the terminal banner |

### 1.2 Timeout & Retry Budget Configuration (`elderly-microservices`)

| Parameter | Env Var | Default | Rule / Invariant |
|-----------|---------|---------|------------------|
| `AIBatchCeilingSeconds` | `AI_BATCH_CEILING_SECONDS` | `300` (`5m`) | Hard deadline from `job.CreatedAt` |
| `AIBatchAttemptTimeoutSeconds` | `AI_BATCH_ATTEMPT_TIMEOUT_SECONDS` | `290` (`4m50s`) | Single primary synthesis attempt timeout (`<= ceiling - 10s` persistence headroom in production defaults) |
| `minBatchRetryRemainingBudget` | (derived) | `min(240s, attemptTimeout)` | Minimum remaining time before `deadline` required to launch a second primary synthesis attempt after a transient failure |

### 1.3 Generation Phase Timing Telemetry (`kubo-agents`)

Structured log record fields emitted at `INFO` level during `POST /regimen/generate`:

| Phase / Metric | Description |
|----------------|-------------|
| `patient_id` | Resident identifier being synthesized |
| `model` | Configured LLM model identifier (e.g., `qwen/qwen3-14b`, `gemini-2.5-flash`) |
| `context_retrieval_s` | Elapsed seconds spent querying LanceDB Montessori RAG context and prior session history |
| `prompt_build_s` | Elapsed seconds spent sanitizing inputs and assembling the generation prompt |
| `llm_synthesis_s` | Elapsed seconds spent inside primary LLM skill invocation (`montessori-regimen-generator`) |
| `post_process_s` | Elapsed seconds spent normalizing the 7-day schedule, enforcing motor/cognitive safety gates, and mapping activities |
| `scorecard_s` | Elapsed seconds spent computing the clinical scorecard |
| `scorecard_mode` | `llm` (when primary generation `<= 240s` and evaluator succeeds within `15s`), `heuristic_budget_guard` (when primary generation `> 240s`), or `heuristic_fallback` (when LLM evaluator errors/times out) |
| `session_persist_s` | Elapsed seconds spent persisting session state in `SessionStore` |
| `total_s` | Total end-to-end wall-clock seconds for `POST /regimen/generate` |

---

## 2. State Transitions

1. **`queued` → `in_progress` (`retrieval` → `synthesis`/`refinement`)**:
   - Worker claims job and starts primary synthesis with deadline `min(jobCtx.Deadline, now + attemptTimeout)`.
2. **`in_progress` (`synthesis`/`refinement`) → Retry Check**:
   - Only retries if `attempt < 2`, `isTransientSynthesisError(err)` is true, AND `time.Until(deadline) >= requiredRetryBudget + retryBackoff` (where `requiredRetryBudget = min(240s, attemptTimeout)`).
   - Never spawns an overlapping retry while a valid 3–4.8 minute generation is still in flight.
3. **`in_progress` → `scoring` → `completed`**:
   - Persists `ActivityPlan` + `ActivityItem` rows, updates `regimen_batch_jobs.status = 'completed'`, `phase = 'completed'`, `plan_id = plan.ID`.
   - Mobile poller (`refreshActiveJob`) receives `completed` job with hydrated `plan` (via `/activities/plan/jobs/active` or fallback `/activities/plan/jobs/{jobId}`), emits `RegimenBatchCompletionEvent`, shows non-blocking SnackBar + `RegimenBatchBanner` review action, and refreshes tasks if `applied`.
