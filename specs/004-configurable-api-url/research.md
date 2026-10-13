# Phase 0 Research: Configurable Server Connection Settings

**Feature**: `004-configurable-api-url`  
**Date**: 2026-10-12

## 1. Local Persistence Mechanism on Device

- **Decision**: Use `hive_flutter` (`Hive.openBox('app_settings')` storing key `'custom_base_url'`) which is already declared in `pubspec.yaml` (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`).
- **Rationale**: The project already depends on `hive` and `hive_flutter`. Using a lightweight Hive box in `main()` before `runApp()` requires zero new package dependencies, works identically across Android (Google Pixel), iOS, macOS, and Web, and allows synchronous reading of the persisted custom URL when initializing `AppConfigNotifier`. For unit/widget tests where `Hive.initFlutter()` has not been called, `AppConfigStorage` falls back gracefully to in-memory storage.
- **Alternatives considered**:
  - `shared_preferences`: Would require adding a new dependency to `pubspec.yaml` and running native plugin registration rebuilds when `hive_flutter` is already installed and linked.
  - File-system JSON via `path_provider`: Lower-level and requires manual async file I/O compared to Hive's key-value box.

## 2. Ensuring 100% of Microservices Use the Configured Base URL

- **Decision**:
  1. Synchronize all service URL fields in `AppConfig` (`apiBaseUrl`, `authServiceUrl`, `careServiceUrl`, `aiServiceUrl`) whenever `setCustomBaseUrl()` or `resetBaseUrl()` is invoked on `AppConfigNotifier`.
  2. Route all 8 HTTP microservice repositories through `apiClientProvider` (`ref.watch(apiClientProvider)`), which watches `appConfigProvider`:
     - `HttpAuthRepository` (`/auth/demo-accounts`, `/auth/login`)
     - `HttpResidentRepository` (`/patients`, `/patients/{id}`)
     - `HttpCareTasksRepository` (`/care-tasks`)
     - `HttpHealthVitalsRepository` (`/vitals`)
     - `HttpMealRepository` (`/nutrition/foods`, `/nutrition/summary`, `/nutrition/meals`)
     - `HttpMoodRepository` (`/moods`)
     - `HttpMemoryRepository` (`/memories`)
     - `HttpMontessoriRepository` (`/montessori/activities`)
     - `HttpAiAssistantRepository` (`/ai/chat`, `/ai/prompt-suggestions`)
  3. Preserve authentication state (`authToken` and `activeInstitutionId`) across `apiClientProvider` rebuilds so that changing the base URL while signed in does not drop the bearer token or institution header.
  4. Trigger in-place data refresh when `apiBaseUrl` changes by invalidating/reloading `demoAccountsProvider` and re-fetching the active resident in `residentProvider` (`selectById(currentResident.id)`), while all feature providers (`careTasksProvider`, `healthVitalsProvider`, `mealTrackerProvider`, `moodJournalProvider`, `memoryBoxProvider`, `montessoriProvider`, `aiAssistantProvider`) automatically rebuild because they watch their respective repository providers.
- **Rationale**: Guarantees that every single microservice call and media asset URL resolution (`ApiClient.resolveMediaUrl`) immediately reflects the new base URL with zero app restarts and without losing the user's current screen or session.
- **Alternatives considered**:
  - Mutating `ApiClient.baseUrl` in-place without triggering Riverpod state changes: Rejected because widgets and providers watching `demoAccountsProvider` or `residentProvider` would not automatically refresh their displayed data.

## 3. Smart Shorthand & Full URL Normalization

- **Decision**: Implement a pure, deterministic helper `AppConfig.normalizeBaseUrl(String rawInput)` and validator `AppConfig.validateBaseUrl(String rawInput)`:
  - Trims whitespace and trailing slashes.
  - If no `http://` or `https://` scheme is present, prepends `http://`.
  - Parses with `Uri.tryParse`. Rejects empty hosts, spaces, or schemes other than `http`/`https`.
  - If the user entered a shorthand host/IP without an explicit port (and scheme was omitted or host is a local IP/hostname without path), defaults port to `:8080` when no port was specified in shorthand mode (`!rawInput.contains('://') && !uri.hasPort`).
  - If the URI path is empty or `'/'`, appends `/api/v1`.
  - Strips any trailing `/` from the final normalized URL.
- **Rationale**: Typing `192.168.1.50` on a Google Pixel phone immediately normalizes to `http://192.168.1.50:8080/api/v1`, while typing a full custom URL like `http://192.168.1.50:9000/api/v1` or `https://uat-api.kubocare.com/api/v1` preserves the explicit scheme, port, and path.
- **Alternatives considered**:
  - Requiring full `http://...:8080/api/v1` string entry: Error-prone on mobile keyboards.

## 4. Connection Testing & Physical Device Wi-Fi Reachability

- **Decision**:
  - Add `Future<ConnectionTestResult> testConnection(String baseUrl)` (executing a `GET` request to `<normalizedBaseUrl>/auth/demo-accounts` with a 4-second timeout).
  - Verify Android manifest configuration: `android/app/src/main/AndroidManifest.xml` already has `<uses-permission android:name="android.permission.INTERNET"/>` and `android:usesCleartextTraffic="true"`, which allows physical Google Pixel devices to make cleartext `http://` requests to local network IPs (`192.168.x.x`, `10.x.x.x`, `172.16.x.x`).
- **Rationale**: Testing against `/auth/demo-accounts` validates both TCP/HTTP reachability to the MacBook on Wi-Fi and confirms that the `/api/v1` gateway routing is active and responding with JSON within the 5-second success criterion (`SC-004`).
- **Alternatives considered**:
  - Raw socket ping: Does not verify HTTP gateway routing or `/api/v1` base path correctness.
