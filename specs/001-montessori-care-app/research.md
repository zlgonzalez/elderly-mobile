# Research & Decisions

## Context
The application is a Flutter-based mobile and web application for elderly care, utilizing a Stitch design system ("Prepared Environment").

## Decisions

### State Management
- **Decision**: Riverpod
- **Rationale**: Highly recommended by the Flutter community for scalable, compile-safe state management. It seamlessly integrates with Clean Architecture and allows easy injection of the Isar database and external service clients.
- **Alternatives considered**: Provider (too basic), BLoC (too much boilerplate for this specific feature set).

### Local Storage
- **Decision**: Isar Database
- **Rationale**: User explicitly requested Isar for local-first data. It is extremely fast, type-safe, and natively supports Flutter across multiple platforms, making it ideal for offline-first synchronization.
- **Alternatives considered**: Hive (less query capability), SQLite/sqflite (requires more boilerplate and is slower).

### Architecture Pattern
- **Decision**: Clean Architecture (Data, Domain, Presentation)
- **Rationale**: User explicitly requested this. Ensures separation of concerns, making the repository pattern (data fetching) entirely decoupled from the UI (presentation). This is critical for eventually swapping the mocked data layer with actual microservice integrations.
- **Alternatives considered**: Feature-First (used in previous projects, but explicitly overridden here by user request).

### External Integrations
- **Decision**: Dedicated Service Layer for MCP and LLMs
- **Rationale**: User requested a specific service layer for MCP servers and backend LLMs. This will live in the `core/network` layer and be injected via Riverpod to the `domain` repositories.
