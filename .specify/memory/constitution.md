# Kubo North Mobile App Constitution

## Core Principles

### I. Self-Contained Feature Architecture
Maintain a clean separation between Presentation (`lib/presentation/`), Domain entities (`lib/domain/entities/`), Data repositories (`lib/data/repositories/`), and Core infrastructure (`lib/core/`). Widgets must not perform direct HTTP calls; all data access flows through Riverpod providers and repository interfaces.

### II. Microservice Pluggability
Every data domain exposes an abstract repository interface with both an HTTP implementation (`Http*Repository`) and a local fallback/mock implementation (`Mock*Repository`), routed through the centralized `ApiClient` (`apiClientProvider`) and `AppConfig` (`appConfigProvider`).

### III. Test-First & Platform Coverage
All core configuration, data repositories, and interactive UI flows must be covered by automated `flutter_test` unit and widget tests that run cleanly without external network dependencies.

### IV. Environment-Aware Configuration
All backend microservice URLs and environment flags must be managed centrally via `AppConfig` (`lib/core/config/app_config.dart`), supporting compile-time `--dart-define` defaults, platform-aware localhost routing, and runtime user-configurable base URL overrides persisted on the device.

## Quality & UX Constraints

- **Accessibility & Touch Targets**: Minimum 48x48dp interactive touch targets and WCAG 2.1 AA contrast compliance using the calming `#F2FAF5` palette.
- **Resilience**: Network requests must enforce bounded timeouts and degrade gracefully when a local or remote server is unreachable.

## Development Workflow

- Verify all changes with `flutter analyze` and `flutter test` prior to completion.
- Keep dependencies minimal; reuse the established Flutter + Riverpod + Hive + GoRouter + `http` stack.

## Governance

This constitution governs all specifications, implementation plans, and code changes in `elderly-mobile`.

**Version**: 1.0.0 | **Ratified**: 2026-09-26 | **Last Amended**: 2026-10-12

<!-- KUBO_SPEC_SYNC_RULE_START -->
## Open Feature Spec Synchronization (NON-NEGOTIABLE)

Before merging or archiving (for example, distilling via `/speckit.blueprint-index.distill`) any branch with an open feature spec under `specs/<feature>/`, every surgical or out-of-band code change made during implementation, debugging, or review **MUST** be reflected back into the open feature's `spec.md` (and `plan.md`, `data-model.md`, `contracts/`, or `tasks.md` when affected).

- **No silent drift:** Never merge or archive a feature when the implemented behavior, interfaces, edge cases, constraints, or data models diverge from its open `spec.md`.
- **Update in the same branch:** Whenever a surgical code change alters behavior, constraints, edge cases, or contracts, update the currently open feature spec before merging and archiving.
- **Pre-merge verification:** Confirm the open feature spec accurately reflects the final code diff before merging and archiving.
<!-- KUBO_SPEC_SYNC_RULE_END -->

## Canonical Spec-Code Synchronization (Mandatory)

1. **Canonical Sources of Truth:** `.specify/memory/blueprint.md` is the canonical architectural map ("How") and `specs/000-product-baseline/spec.md` is the canonical behavioral baseline ("What"). Consult both before designing new features or modifying existing domains.
2. **Standard Feature Entry:** Start new features with `/speckit.specify` in `specs/<###-feature>/` so existing Spec Kit workflows remain intact.
3. **Surgical Edit Lockstep:** Whenever a prompt requests a behavioral, contract, data-model, or architectural change outside `/speckit.implement`, locate the active branch's `specs/<###-feature>/` folder (or `specs/000-product-baseline/` if patching a baseline domain directly) and update `spec.md`, `plan.md`, and `contracts/` in the **same turn** as the code change. Preserve existing `FR-###` IDs.
4. **Pre-Merge Canonical Rollup:** Before merging any feature branch, run `/speckit.blueprint-index.distill` on the active feature folder, fold added/modified behavioral requirements into `specs/000-product-baseline/spec.md`, and confirm `bash .specify/extensions/blueprint-index/scripts/bash/blueprint-state.sh check` exits 0 with zero drift.
