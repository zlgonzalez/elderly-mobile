# Implementation Plan: Montessori Care App

**Branch**: `[001-montessori-care-app]` | **Date**: 2026-04-25 | **Spec**: [spec.md](file:///Users/zlgonzalez/Documents/code/kubo/elderly-mobile/specs/001-montessori-care-app/spec.md)
**Input**: Feature specification from `/specs/001-montessori-care-app/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command.

## Summary

Implementation of the Montessori Care App using Flutter 3.27+, featuring an offline-first architecture powered by Isar local storage, state management via Riverpod, and strict Clean Architecture principles. The app provides specialized caregiving tools, role-based Zitadel authentication, and an integrated CareGuide AI Assistant for both mobile (iOS/Android) and Web platforms.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.27+
**Primary Dependencies**: Riverpod, Isar, Http (Zitadel Auth)
**Storage**: Isar Database (Local-first)
**Testing**: flutter_test, integration_test
**Target Platform**: iOS, Android, Web
**Project Type**: Multi-platform Application
**Performance Goals**: 60 fps rendering, instantaneous local data access
**Constraints**: Offline-first capability, seamless sync when online, strict adherence to Stitch design tokens
**Scale/Scope**: Facility-level deployment, supporting concurrent caregivers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

No explicit constitution violations detected. Project follows offline-first and clean architecture principles explicitly requested by the user.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── theme/          # Stitch Design Tokens (Primary #4c614b, Newsreader/Public Sans)
│   ├── router/         # GoRouter configuration
│   └── network/        # Base API clients, MCP Service Layer
├── data/
│   ├── local/          # Isar Database configuration and schemas
│   └── repositories/   # Concrete repository implementations (Offline-first sync)
├── domain/
│   ├── entities/       # Core business models (Admin, Caregiver, Resident, CareLog)
│   └── repositories/   # Abstract repository interfaces
├── presentation/
│   ├── auth/           # Zitadel Login / Re-auth Modals
│   ├── dashboard/      # Evergreen Dashboard, Caregiver Handover
│   ├── residents/      # Resident Profiles, Meaningful Work Logs
│   ├── careguide/      # CareGuide AI Assistant UI
│   └── shared/         # Common UI components, Responsive Navigation
└── main.dart           # App entry point
```

**Structure Decision**: A standard Clean Architecture structure segmented by presentation, domain, and data layers, heavily utilizing Riverpod for state injection and Isar for local data caching.

## Complexity Tracking

N/A - Standard Clean Architecture and offline-first mobile app implementation without major deviations.
