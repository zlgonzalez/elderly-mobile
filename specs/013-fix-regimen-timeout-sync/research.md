# Phase 0 Research: Reliable Long-Running Regimen Generation & Mobile Completion Delivery

**Feature**: `013-fix-regimen-timeout-sync`  
**Date**: 2026-11-22

---

## 1. Single-Pass Batch Attempt Timeout vs. Overall Job Ceiling (`elderly-microservices`)

### Decision
Change the default `AI_BATCH_ATTEMPT_TIMEOUT_SECONDS` from `180` (3 minutes) to **`290` seconds (4 minutes 50 seconds)** inside the **`300`-second (5-minute)** `AI_BATCH_CEILING_SECONDS` budget (leaving `10s` persistence headroom), and require at least **`240` seconds** of remaining budget before starting a retry attempt (`minBatchRetryRemainingBudget = 240 * time.Second`, capped by `attemptTimeout` when shorter timeouts are injected in unit tests).

### Rationale
- **Root cause of the 5-minute failure**: In live execution against `qwen/qwen3-14b`, a single 7-day Montessori synthesis pass in `kubo-agents` took `238.9s` (~3m 59s). Because `AI_BATCH_ATTEMPT_TIMEOUT_SECONDS` was `180s`, `elderly-microservices` canceled Attempt 1's HTTP context at `180s` (59 seconds before Attempt 1 finished with HTTP 200 in `kubo-agents`) and immediately launched Attempt 2 at `182s`. Attempt 2 then ran concurrently with the tail of Attempt 1 on the model server and was killed at `300s` when the 5-minute job ceiling expired.
- Giving Attempt 1 up to `290s` allows 3–4.8 minute local/self-hosted LLM generations to complete in a single pass within the 5-minute ceiling.
- Requiring sufficient remaining budget (`>= min(240s, attemptTimeout)`) before retrying prevents launching a doomed second LLM call when a long attempt fails near the end of the 5-minute window, while still permitting retries when an attempt fails fast (e.g., an immediate network/503 error in the first few seconds).

### Alternatives Considered
- **Extending job ceiling to 10 minutes (`600s`)**: Rejected during clarification (Option A selected) to preserve the 5-minute SLA while eliminating the premature 3-minute cutoff.

---

## 2. Phase-by-Phase Timing Observability & Adaptive Scorecard Guard (`kubo-agents`)

### Decision
1. Configure Python application logging in `kubo-agents/src/main.py` (`logging.basicConfig(level=..., format=...)`) so `INFO` logs from `api.*`, `services.*`, `scorer.*`, and `store.*` are emitted to `kubo-agents.log` alongside Uvicorn logs (previously Python's root logger defaulted to `WARNING`, dropping all application `logger.info` messages).
2. Instrument `RegimenHandler.handle_generate` (`src/api/regimen_handlers.py`), `RegimenGenerator.generate_regimen` / `invoke_regimen_skill` (`src/services/generator.py`), and `AgentFramework.invoke_skill` (`src/services/agent.py`) with `time.perf_counter()` phase timers that log start, completion, and a consolidated timing breakdown (`context_retrieval_s`, `prompt_build_s`, `llm_synthesis_s`, `post_process_s`, `scorecard_s`, `session_persist_s`, `total_s`, `model`, `scorecard_mode`).
3. Add an **adaptive scorecard budget guard** (`SCORECARD_LLM_BUDGET_THRESHOLD_SECONDS = 240.0`) in `RegimenHandler.handle_generate`: when primary regimen generation takes `<= 240s`, run the bounded (`15s`) LLM scorecard evaluator with heuristic fallback; when primary generation already took `> 240s`, skip the secondary LLM call and compute `_compute_heuristic_scorecard` immediately (~0ms) so scorecard generation never pushes a 4-minute synthesis past the `290s` attempt window.

### Rationale
- Tailing `kubo-agents.log` previously only showed verbose JSON OpenTelemetry span dumps on span completion, making it hard to see live progress or a clear breakdown of where time was spent (RAG vs. prompt building vs. LLM inference vs. post-processing vs. scorecard evaluation).
- Skipping a second LLM round-trip when primary synthesis has already consumed >4 minutes saves 15+ seconds on single-GPU local LLM servers.

### Alternatives Considered
- **Always using heuristic scorecard**: Rejected in clarification in favor of Option A (adaptive budget guard).

---

## 3. Reliable Completion Detection & Non-Blocking Mobile Experience (`elderly-mobile` & `elderly-microservices`)

### Decision
1. **Direct-by-ID Fallback in `RegimenBatchNotifier.refreshActiveJob` (`elderly-mobile/lib/presentation/care_tasks/regimen_batch_provider.dart`)**:
   - When polling a resident with a known previous job (`previous != null`), if `getActiveBatchJob(key)` returns `null` (or returns a `completed` job whose embedded `plan` is `null` despite `planId != null`), automatically query `_repository.getBatchJob(key, previous.id)` (and if `plan == null && planId != null`, fetch the plan or hydrate it) so terminal transitions (`completed` or `failed`) are never missed.
2. **Backend Active/Recent Job Query Consistency (`elderly-microservices/internal/activity/repository.go` & `batch_mem_repo.go`)**:
   - When a caregiver manually applies a preview plan via `ApplyWeeklyPlan` (`internal/activity/service.go`), dismiss terminal batch jobs for that patient (`DismissTerminalBatchJobsForPatient`) so applied preview banners clear cleanly.
   - In `GetActiveOrRecentBatchJobByPatient`, keep returning undismissed `completed` jobs within 24 hours unless their plan was `superseded` (or manually applied and dismissed), ensuring both `preview` and `auto_apply=true` completed jobs remain visible to `GET /api/v1/activities/plan/jobs/active` until dismissed.
3. **Uninterrupted Non-Blocking Navigation (`elderly-mobile`)**:
   - Ensure `RegimenBatchNotifier` polling continues globally in the Riverpod provider while the user navigates freely across all tabs (`ResponsiveLayout`), switches residents, or completes/skips existing care tasks, and ensure `RegimenBatchBanner` + global `SnackBar` completion notifications surface immediately upon job completion without modal blocking.

### Rationale
- Defense-in-depth between `GET /api/v1/activities/plan/jobs/active` and `GET /api/v1/activities/plan/jobs/{jobId}` guarantees that even if an active-job query races with plan application or status transitions, the mobile client tracking `previous.id` always observes the exact terminal state and hydrated 7-day plan.
