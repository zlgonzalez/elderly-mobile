# Quickstart: Verifying Reliable Regimen Generation & Phase Timing Logs

**Feature**: `013-fix-regimen-timeout-sync`  
**Date**: 2026-11-22

---

## 1. Start the Local Dev Stack

```bash
cd /Users/zlgonzalez/Documents/code/kubo/elderly-microservices
./scripts/dev_stack.sh
```

`dev_stack.sh` exports:
- `AI_BATCH_ATTEMPT_TIMEOUT_SECONDS=290` (4m 50s single-attempt budget)
- `AI_BATCH_CEILING_SECONDS=300` (5m overall batch job ceiling)

---

## 2. Inspect Phase-by-Phase Timing Logs in `kubo-agents`

Tail the `kubo-agents` log file while a regimen generation job runs:

```bash
tail -f /Users/zlgonzalez/Documents/code/kubo/elderly-microservices/.dev-stack/kubo-agents.log
```

You will see structured `INFO` timing logs for each generation phase:
- `[REGIMEN] Starting generation for patient_id=...`
- `[REGIMEN] Phase 1/4 context_retrieval completed in ...s`
- `[REGIMEN] Phase 2/4 prompt_build completed in ...s`
- `[REGIMEN] Phase 3/4 llm_synthesis completed in ...s`
- `[REGIMEN] Phase 4/4 scorecard completed in ...s (mode=llm|heuristic_budget_guard|heuristic_fallback)`
- `[REGIMEN] Completed /regimen/generate in ...s (breakdown: context=...s, prompt=...s, llm=...s, post_process=...s, scorecard=...s, session_persist=...s)`

---

## 3. Run Automated Tests Across All 3 Repositories

```bash
# 1. kubo-agents
cd /Users/zlgonzalez/Documents/code/kubo/kubo-agents
uv run pytest tests/unit/test_generator.py tests/integration/test_regimen_integration_spec.py -v

# 2. elderly-microservices
cd /Users/zlgonzalez/Documents/code/kubo/elderly-microservices
go test -v ./internal/activity/... ./test/integration/...

# 3. elderly-mobile
cd /Users/zlgonzalez/Documents/code/kubo/elderly-mobile
flutter analyze && flutter test test/unit/care_tasks_test.dart test/widget/care_tasks_test.dart test/integration/batch_regimen_spec_test.dart
```
