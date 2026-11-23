# Tasks: Reliable Long-Running Regimen Generation & Mobile Completion Delivery

**Input**: Design documents from `/specs/013-fix-regimen-timeout-sync/`  
**Prerequisites**: [plan.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-microservices/specs/013-fix-regimen-timeout-sync/plan.md), [spec.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-microservices/specs/013-fix-regimen-timeout-sync/spec.md), [research.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-microservices/specs/013-fix-regimen-timeout-sync/research.md), [data-model.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-microservices/specs/013-fix-regimen-timeout-sync/data-model.md), [contracts/openapi.yaml](file:///Users/zlgonzalez/Documents/code/kubo/elderly-microservices/specs/013-fix-regimen-timeout-sync/contracts/openapi.yaml)

**Tests**: Included across all three repositories (`elderly-microservices`, `elderly-mobile`, `kubo-agents`) to verify the 5-minute single-pass execution window, retry budget guard, phase-by-phase timing logs, adaptive scorecard guard, and non-blocking mobile completion delivery.

**Organization**: Tasks are grouped by user story (`US1`, `US2`, `US3`) to enable independent implementation and verification of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files/repositories, no dependencies on incomplete tasks)
- **[Story]**: User story label (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Configuration & Environment Alignment)

**Purpose**: Align environment configuration defaults for the `290s` single-attempt timeout and `300s` batch job ceiling across local dev stack, Docker Compose, and `.env` templates.

- [X] T001 [P] Update `AI_BATCH_ATTEMPT_TIMEOUT_SECONDS=290` and `AI_BATCH_CEILING_SECONDS=300` defaults in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/.env.example` and `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/docker-compose.yml`
- [X] T002 [P] Update `AI_BATCH_ATTEMPT_TIMEOUT_SECONDS` default from `180` to `290` (and upgrade any legacy `180` value loaded from `.env` to `290`) in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/scripts/dev_stack.sh`
- [X] T003 [P] Update `AIBatchAttemptTimeoutSeconds` default from `180` to `290` in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/platform/config/config.go`

---

## Phase 2: Foundational (Logging & Timeout Infrastructure)

**Purpose**: Establish foundational timeout wiring in `elderly-microservices` and root application `INFO` logging in `kubo-agents` before user story execution.

**⚠️ CRITICAL**: Must complete before user story verification.

- [X] T004 [P] Update default `batchAttemptTimeout` from `180 * time.Second` to `290 * time.Second` and expose `BatchAttemptTimeout()` getter in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/ai_synthesizer.go`
- [X] T005 [P] Configure root/application `INFO` logging (`logging.basicConfig` with timestamped format and `LOG_LEVEL` support) in `/Users/zlgonzalez/Documents/code/kubo/kubo-agents/src/main.py` so `logger.info` messages from `api.*`, `services.*`, and `scorer.*` always write to `kubo-agents.log`
- [X] T006 Track `batchAttemptTimeout` (default `290 * time.Second`) and `minBatchRetryRemainingBudget` (`240 * time.Second`) on `activityService` in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/service.go` and `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/batch_worker.go`

**Checkpoint**: Timeout defaults (`290s` / `300s`) and `kubo-agents` application logging are active.

---

## Phase 3: User Story 1 - Complete Single-Pass Regimen Generation Without Premature Attempt Abandonment (Priority: P1) 🎯 MVP

**Goal**: Allow single-pass synthesis runs taking 3 to 4.8 minutes (`180s`–`290s`) to complete without premature cancellation at 3 minutes, and prevent retries unless sufficient execution budget (`>= min(240s, attemptTimeout)`) remains before the 5-minute ceiling.

**Independent Test**: Submit a batch regimen job whose primary synthesis takes longer than 3 minutes (or simulated via configurable attempt timeout and ceiling) and verify it completes on the first pass with `retry_count = 0`, and that a late failure without enough remaining budget for a full pass does not spawn a second overlapping attempt.

### Tests for User Story 1

- [X] T007 [P] [US1] Add unit test verifying single-pass completion beyond the old threshold and remaining-budget retry guard in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/activity_test.go`
- [X] T008 [P] [US1] Add integration test verifying single-pass long synthesis completion and no duplicate retry when remaining budget is below required retry threshold in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/test/integration/batch_regimen_integration_test.go`

### Implementation for User Story 1

- [X] T009 [US1] Update `synthesizeWithBatchRetries` in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/batch_worker.go` to require `time.Until(deadline) >= requiredRetryBudget + s.batchRetryBackoff` (where `requiredRetryBudget = min(240*time.Second, s.effectiveBatchAttemptTimeout())`) before launching Attempt 2
- [X] T010 [US1] Add structured batch worker log lines in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/batch_worker.go` logging attempt start, elapsed duration, retry decision (including skipped retries due to insufficient remaining budget), and plan persistence completion
- [X] T011 [US1] Update `GetActiveOrRecentBatchJobByPatient` in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/repository.go` and `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/batch_mem_repo.go` so undismissed `completed` batch jobs (both `preview` and `auto_apply=true` `applied`) remain returned with their hydrated `Plan` until dismissed or superseded
- [X] T012 [US1] Dismiss terminal batch jobs for the patient when a caregiver manually applies a preview plan in `ApplyWeeklyPlan` in `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices/internal/activity/service.go`

**Checkpoint**: User Story 1 is complete and verified via `go test ./internal/activity/... ./test/integration/...`.

---

## Phase 4: User Story 2 - Reliable Mobile Detection and Presentation of Completed Regimen Jobs (Priority: P1)

**Goal**: Ensure `elderly-mobile` reliably detects batch job completion (including fallback lookup by `job_id` and plan hydration if `getActiveBatchJob` returns null or lacks the plan), updates the banner/preview state within 1 polling interval, and keeps the app completely non-blocking across all tabs and resident switches while generation runs in the background.

**Independent Test**: Run `flutter test` on `test/unit/care_tasks_test.dart` and `test/integration/batch_regimen_spec_test.dart` to verify direct-by-`jobId` fallback polling, plan hydration, completion event emission, and non-blocking multi-tab navigation during active batch polling.

### Tests for User Story 2

- [X] T013 [P] [US2] Add unit test in `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile/test/unit/care_tasks_test.dart` verifying that `RegimenBatchNotifier.refreshActiveJob` falls back to `getBatchJob(residentId, previous.id)` when `getActiveBatchJob` returns `null` for an in-flight job and still emits `lastCompletionEvent`
- [X] T014 [P] [US2] Add integration test in `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile/test/integration/batch_regimen_spec_test.dart` verifying non-blocking navigation across tabs while a batch job is in progress and reliable completion delivery when the job finishes

### Implementation for User Story 2

- [X] T015 [US2] Update `refreshActiveJob` in `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile/lib/presentation/care_tasks/regimen_batch_provider.dart` to fall back to `_repository.getBatchJob(key, previous.id)` when `previous != null && previous.isActive` and `getActiveBatchJob(key)` returns `null` (or returns a completed job missing `plan` when `planId != null`)
- [X] T016 [US2] Update `getActiveBatchJob` and `getBatchJob` in `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile/lib/data/repositories/http_care_tasks_repository.dart` to hydrate `plan` via `GET /activities/plan/{planId}` if a `completed` batch job payload ever arrives with `plan_id != null` but `plan == null`, and guard `_mapActivityItemToTask` against malformed item elements so a single bad field never silently drops the poll update
- [X] T017 [US2] Update `_applyJobUpdate` in `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile/lib/presentation/care_tasks/regimen_batch_provider.dart` to automatically stage preview plans (`setPreviewPlanFromBatch`) or reload applied tasks (`loadTasks`) as soon as a tracked job transitions to `completed`
- [X] T018 [US2] Update `_openPreview` in `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile/lib/presentation/care_tasks/widgets/regimen_batch_banner.dart` and `_openBatchPreview` in `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile/lib/presentation/shared/responsive_layout.dart` to fall back to `getBatchJob(residentId, job.id)` if `job.plan` is null when the caregiver taps "Review & Apply" / "Review Plan"

**Checkpoint**: User Story 2 is complete and verified via `flutter analyze && flutter test`.

---

## Phase 5: User Story 3 - Prompt Synthesis Efficiency, Phase-by-Phase Timing Logs & Graceful Timeout Handling (Priority: P2)

**Goal**: Emit structured phase-by-phase duration logs in `kubo-agents` (`context_retrieval`, `prompt_build`, `llm_synthesis`, `post_process`, `scorecard`, `session_persist`, `total`) so operators can see exactly where time is spent in `kubo-agents.log`, and enforce the `240s` adaptive scorecard budget guard so slow (>4m) primary generations skip the secondary LLM call and use the instant deterministic clinical scorecard.

**Independent Test**: Run `uv run pytest` in `kubo-agents` verifying phase timing log emission and verifying that when primary generation elapsed time exceeds `240s` (threshold), `RegimenHandler.handle_generate` skips `evaluator.evaluate` and immediately attaches the deterministic clinical scorecard (`mode=heuristic_budget_guard`).

### Tests for User Story 3

- [X] T019 [P] [US3] Add unit tests in `/Users/zlgonzalez/Documents/code/kubo/kubo-agents/tests/unit/test_generator.py` verifying phase-by-phase timing log output during `generate_regimen`
- [X] T020 [P] [US3] Add integration test in `/Users/zlgonzalez/Documents/code/kubo/kubo-agents/tests/integration/test_regimen_integration_spec.py` verifying the adaptive scorecard budget guard (`>240s` skips secondary LLM evaluation and uses instant deterministic scorecard) and end-to-end timing breakdown logging

### Implementation for User Story 3

- [X] T021 [US3] Instrument `build_skill_inputs`, `_build_generation_prompt`, `invoke_regimen_skill`, and `generate_regimen` in `/Users/zlgonzalez/Documents/code/kubo/kubo-agents/src/services/generator.py` with `time.perf_counter()` timers and `logger.info` phase logs (`context_retrieval`, `prompt_build`, `llm_synthesis`, `post_process`)
- [X] T022 [US3] Instrument `AgentFramework.invoke_skill` in `/Users/zlgonzalez/Documents/code/kubo/kubo-agents/src/services/agent.py` to log LLM invocation start, model identifier, and completion duration in seconds
- [X] T023 [US3] Implement the adaptive scorecard budget guard (`SCORECARD_LLM_BUDGET_THRESHOLD_SECONDS = 240.0`) and consolidated request timing breakdown log in `RegimenHandler.handle_generate` in `/Users/zlgonzalez/Documents/code/kubo/kubo-agents/src/api/regimen_handlers.py`
- [X] T024 [US3] Ensure `RegimenEvaluator.evaluate` in `/Users/zlgonzalez/Documents/code/kubo/kubo-agents/src/scorer/evaluator.py` logs evaluation start, completion duration, and fallback reasons at `INFO`/`WARNING` level

**Checkpoint**: User Story 3 is complete and verified via `uv run pytest`.

---

## Phase 6: Polish & Cross-Cutting Verification

**Purpose**: Restart the running local dev stack and Flutter emulator session with the new code, verify live end-to-end regimen generation and phase timing logs, and synchronize spec artifacts across repositories.

- [X] T025 [P] Synchronize `specs/013-fix-regimen-timeout-sync/` artifacts across `/Users/zlgonzalez/Documents/code/kubo/elderly-microservices`, `/Users/zlgonzalez/Documents/code/kubo/elderly-mobile`, and `/Users/zlgonzalez/Documents/code/kubo/kubo-agents`
- [X] T026 Run full local test suites across `elderly-microservices` (`make test`), `kubo-agents` (`uv run pytest`), and `elderly-mobile` (`flutter analyze && flutter test`)
- [X] T027 Restart `elderly-microservices` and `kubo-agents` in the local dev stack and hot-restart `elderly-mobile` on the Android emulator (`emulator-5554`) to verify live phase logs and non-blocking regimen generation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)** & **Phase 2 (Foundational)**: Complete first (`T001`–`T006`).
- **Phase 3 (`US1` - `elderly-microservices`)**, **Phase 4 (`US2` - `elderly-mobile`)**, and **Phase 5 (`US3` - `kubo-agents`)**: Touch separate repositories and can be implemented and unit-tested in parallel after Phase 2.
- **Phase 6 (Polish & Live Dev Stack Verification)**: Depends on Phases 3, 4, and 5 completing.

### Parallel Opportunities

- `T001`, `T002`, `T003`, `T004`, `T005` can run in parallel across config and logging files.
- `US1` (`elderly-microservices`), `US2` (`elderly-mobile`), and `US3` (`kubo-agents`) reside in independent repositories and can be executed in parallel.

---

## Parallel Example: Cross-Repo Story Execution

```bash
# US1 (elderly-microservices):
Task: "T009 [US1] Update synthesizeWithBatchRetries in elderly-microservices/internal/activity/batch_worker.go"

# US2 (elderly-mobile):
Task: "T015 [US2] Update refreshActiveJob in elderly-mobile/lib/presentation/care_tasks/regimen_batch_provider.dart"

# US3 (kubo-agents):
Task: "T023 [US3] Implement adaptive scorecard budget guard and timing breakdown log in kubo-agents/src/api/regimen_handlers.py"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 - Core P1 Fix)

1. Complete Phase 1 & Phase 2 (`290s` attempt timeout default + `kubo-agents` root logging).
2. Complete Phase 3 (`US1` — prevent premature 3-minute attempt cancellation and overlapping retry in `elderly-microservices`).
3. Complete Phase 4 (`US2` — direct-by-`jobId` fallback polling and non-blocking completion delivery in `elderly-mobile`).
4. Complete Phase 5 (`US3` — phase-by-phase duration logging and `240s` adaptive scorecard budget guard in `kubo-agents`).
5. Complete Phase 6 — run all test suites and reload the running dev stack + Android emulator app.
