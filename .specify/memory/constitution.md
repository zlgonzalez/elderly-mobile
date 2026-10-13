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
