# Implementation Plan: Reliable Long-Running Regimen Generation & Mobile Completion Delivery

**Branch**: `013-fix-regimen-timeout-sync` | **Date**: 2026-11-22 | **Spec**: [spec.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-microservices/specs/013-fix-regimen-timeout-sync/spec.md)  
**Input**: Feature specification from `/specs/013-fix-regimen-timeout-sync/spec.md`

## Summary

Fix the multi-repository timeout and completion-delivery gap where a 3.5–4.5 minute 7-day Montessori regimen synthesis in `kubo-agents` was prematurely canceled at 3 minutes (`180s`) by `elderly-microservices`, retried concurrently against the local LLM, and killed at the 5-minute (`300s`) ceiling before `elderly-mobile` could receive the finished plan. The solution:
1. **`elderly-microservices`**: Aligns the default primary batch attempt timeout to `290s` inside the `300s` batch ceiling (`10s` persistence headroom), adds a remaining-budget retry guard (`>= min(240s, attemptTimeout)`) so long attempts are never retried when insufficient budget remains, and ensures completed batch jobs remain queryable with hydrated plans until dismissed.
2. **`kubo-agents`**: Enables application-level `INFO` logging and adds phase-by-phase duration instrumentation (`context_retrieval`, `prompt_build`, `llm_synthesis`, `post_process`, `scorecard`, `session_persist`, `total`) plus an adaptive scorecard budget guard (`<= 240s` bounded `15s` LLM evaluator vs. `> 240s` instant deterministic scorecard).
3. **`elderly-mobile`**: Adds direct-by-`jobId` fallback polling in `RegimenBatchNotifier.refreshActiveJob` (and plan hydration fallback if `plan` is missing on a completed job) while preserving non-blocking background polling across all tabs and resident switches.

## Technical Context

**Language/Version**: Go 1.22 (`elderly-microservices`), Python 3.12 (`kubo-agents`), Dart 3.x / Flutter 3.x (`elderly-mobile`)  
**Primary Dependencies**: `chi/v5`, `pgx/v5` (Go); `FastAPI`, `Uvicorn`, `Pydantic v2`, `OpenTelemetry` (Python); `flutter_riverpod`, `go_router`, `http` (Flutter)  
**Storage**: PostgreSQL 16 (`activity.regimen_batch_jobs`, `activity.activity_plans`, `activity.activity_items`), Redis / in-memory `SessionStore` & LanceDB (`kubo-agents`)  
**Testing**: `go test ./...`, `uv run pytest`, `flutter analyze && flutter test`  
**Target Platform**: Linux/macOS servers & Docker (`elderly-microservices`, `kubo-agents`), Android & iOS (`elderly-mobile`)  
**Project Type**: Multi-repository mobile app + Go modular monolith + Python AI agent platform  
**Performance Goals**: Single-pass completion for 7-day regimen generations taking up to `290s`; `<100ms` p95 batch status polling latency; `<3s` (1 poll interval) mobile UI completion detection; `0ms` scorecard overhead when primary synthesis exceeds `240s`  
**Constraints**: `300s` (5-minute) maximum batch job execution ceiling; zero modal UI blocking on `elderly-mobile` during background batch execution  
**Scale/Scope**: Touches 3 repositories (`elderly-microservices`, `kubo-agents`, `elderly-mobile`) on branch `013-fix-regimen-timeout-sync`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Service Independence**: PASS — All changes remain within their respective service boundaries (`internal/activity` in `elderly-microservices`, `src/api` & `src/services` in `kubo-agents`, `lib/presentation/care_tasks` & `lib/data/repositories` in `elderly-mobile`) communicating via existing REST contracts.
- **II. Identity-First (ZITADEL)**: PASS — All batch job endpoints continue enforcing bearer token authentication and caregiver/admin RBAC + patient access checks.
- **III. Observability & Auditing (NON-NEGOTIABLE)**: PASS — Batch lifecycle transitions continue emitting audit events (`BATCH_JOB_SUBMITTED`, `BATCH_JOB_STARTED`, `BATCH_JOB_COMPLETED`, `BATCH_JOB_FAILED`), and `kubo-agents` gains structured phase-level timing logs at `INFO` level.
- **IV. Contract-First**: PASS — Updated contract documented in `specs/013-fix-regimen-timeout-sync/contracts/openapi.yaml`; backward-compatible with existing endpoints.
- **V. Test-Driven Foundations (MANDATORY)**: PASS — Unit and integration tests planned across all three repositories (`elderly-microservices`, `kubo-agents`, `elderly-mobile`).
- **Open Feature & Canonical Spec Synchronization**: PASS — `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/openapi.yaml`, and `quickstart.md` are maintained in lockstep under `specs/013-fix-regimen-timeout-sync/`.

## Project Structure

### Documentation (this feature)

```text
specs/013-fix-regimen-timeout-sync/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/
│   └── openapi.yaml     # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (across the 3 repositories)

```text
elderly-microservices/
├── .env.example
├── docker-compose.yml
├── scripts/
│   └── dev_stack.sh
├── internal/
│   ├── platform/config/config.go
│   └── activity/
│       ├── ai_synthesizer.go
│       ├── batch_worker.go
│       ├── batch_mem_repo.go
│       ├── repository.go
│       ├── service.go
│       └── activity_test.go
└── test/integration/
    └── batch_regimen_integration_test.go

kubo-agents/
├── src/
│   ├── main.py
│   ├── api/regimen_handlers.py
│   └── services/
│       ├── generator.py
│       └── agent.py
└── tests/
    ├── unit/test_generator.py
    └── integration/test_regimen_integration_spec.py

elderly-mobile/
├── lib/
│   ├── data/repositories/http_care_tasks_repository.dart
│   └── presentation/
│       ├── care_tasks/
│       │   ├── regimen_batch_provider.dart
│       │   └── widgets/regimen_batch_banner.dart
│       └── shared/
│           └── responsive_layout.dart
└── test/
    ├── unit/care_tasks_test.dart
    └── integration/batch_regimen_spec_test.dart
```

**Structure Decision**: Multi-repository enhancement across `elderly-microservices`, `kubo-agents`, and `elderly-mobile`, modifying existing activity batch worker, AI regimen generator/handler, and Flutter Riverpod batch polling modules in place.

## Complexity Tracking

No constitution violations; complexity tracking table not required.
