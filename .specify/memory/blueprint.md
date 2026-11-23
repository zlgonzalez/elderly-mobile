# elderly-mobile Blueprint

**Status**: Living document — the authoritative backlog + architecture map for this project.

<!--
  HOW THIS DOCUMENT WORKS
  =======================
  Decreasing-detail map. Sections are DETAILED (backlog: design pending), SETTLED
  (digest + pointer; owner is a feature spec specs/<slug> or the CODE itself —
  brownfield), or CONTEXT (framing; never backlog). Ground truth is the filesystem;
  the machine-readable provenance markers under each heading are what the oracle
  reads — banners and prose are cosmetic. To change a code-owned slice:
  /speckit.specify it as usual; distill collapses its section when the spec ships.
  STRUCTURE IS COMPUTED (blueprint-slice.sh scaffold), never improvised: to change
  the cut, edit blueprint-config.yml and re-derive; the check gate validates
  structural conformance.
-->

## Table of Contents

- `android` — Android native host shell that embeds the Flutter engine and configures Gradle builds, launcher icons, and manifests; **code-owned**
- `assets` — Bundled static visual assets packaged into the Flutter application; **code-owned**
- `ios` — iOS native host shell that bootstraps the Flutter engine, plugins, storyboards, and Xcode bundle metadata; **code-owned**
- `lib/core` — Cross-cutting application infrastructure: runtime environment/server URL configuration, HTTP API client with W3C tracing, GoRouter navigation shell, zero-PII telemetry pipeline, and light theme tokens; **distilled** → `specs/000-product-baseline`
- `lib/data` — Data access layer providing abstract repository contracts, paired Mock and HTTP implementations, demo seed fixtures, and local demo-reset orchestration; **distilled** → `specs/000-product-baseline`
- `lib/domain` — Pure Dart domain model defining the immutable entities, enums, clinical validation rules, and JSON mappers shared across data and presentation layers; **distilled** → `specs/000-product-baseline`
- `lib/presentation` — Riverpod state notifiers and responsive Flutter UI screens across all user workflows: authentication, Family Portal, Their Story, Memory Box, Mood Journal, Care Tasks & AI Regimen planning, Health & Vitals, Meal Tracking, Activity Guide, AI Assistant drawer, and Server Settings; **distilled** → `specs/000-product-baseline`
- `lib` (remainder) — Application entrypoint that initializes Flutter bindings, telemetry, Hive config storage, and launches the Riverpod-wrapped MontessoriCareApp; **distilled** → `specs/000-product-baseline`
- `linux` — Linux desktop host shell built with CMake and GTK to embed the Flutter engine; **code-owned**
- `macos` — macOS desktop host shell that configures the Cocoa window, entitlements, and Flutter view controller; **code-owned**
- `test` — Automated verification suite covering unit logic, widget screens/modals, end-to-end regimen specs, and Android/iOS platform harnesses; **code-owned**
- `web` — Web host shell providing the HTML entry page, PWA manifest, and web icons for Flutter web builds; **code-owned**
- `windows` — Windows desktop host shell built with CMake and Win32 to host the Flutter engine; **code-owned**
- `Regimen Timeout Sync & Delivery` — Delivers non-blocking background batch regimen completion with direct-by-job-ID fallback polling and renders both preview and applied activity reviews via the official Dart A2UI v1.0 renderer; **distilled** → `specs/013-fix-regimen-timeout-sync`

---

## android
<!-- blueprint:section state=code -->
> **Distilled — owned by code at `android/`.** (no spec yet) The implementation
> is the source of truth; this section maps it. To change it, `/speckit.specify`
> the area as usual and `distill` it when the spec ships.
<!-- blueprint:code path=android sha=e20486e91a2db2d3daab88442666aa3be76666fc -->

Android native host shell that embeds the Flutter engine and configures Gradle builds, launcher icons, and manifests. At a glance:

- **Entry point** — MainActivity extends FlutterActivity as the Android launch activity.
- **Build config** — Gradle Kotlin DSL configures Android SDK targets, signing, and Flutter plugin integration.
- **Manifest** — AndroidManifest declares permissions, launch activity metadata, and cleartext/network settings.

For exact behavior, read the code under `android/`. Do not restate it here.
---

## assets
<!-- blueprint:section state=code -->
> **Distilled — owned by code at `assets/`.** (no spec yet) The implementation
> is the source of truth; this section maps it. To change it, `/speckit.specify`
> the area as usual and `distill` it when the spec ships.
<!-- blueprint:code path=assets sha=c2ee77e7719f04ee343be41373dbb9ad0f0beeb1 -->

Bundled static visual assets packaged into the Flutter application. At a glance:

- **Brand mark** — Primary Kubo application logo image bundled via pubspec.yaml.

For exact behavior, read the code under `assets/`. Do not restate it here.
---

## ios
<!-- blueprint:section state=code -->
> **Distilled — owned by code at `ios/`.** (no spec yet) The implementation
> is the source of truth; this section maps it. To change it, `/speckit.specify`
> the area as usual and `distill` it when the spec ships.
<!-- blueprint:code path=ios sha=2cedcba88c84738d02dd52cd04a96a100d915bf3 -->

iOS native host shell that bootstraps the Flutter engine, plugins, storyboards, and Xcode bundle metadata. At a glance:

- **Entry point** — AppDelegate registers generated Flutter plugins and launches the Runner scene.
- **Bundle metadata** — Info.plist defines iOS app display name, bundle identifiers, and permissions.

For exact behavior, read the code under `ios/`. Do not restate it here.
---

## lib/core
<!-- blueprint:section state=distilled owner=specs/000-product-baseline -->
> **Distilled — owned by `specs/000-product-baseline`** (implemented at `lib/core/`).
> The full behavioral requirements live in that spec, which is the source of truth.
<!-- blueprint:code path=lib/core sha=0059f660eb9703e9230c0b2164f634d2be0849de -->

Cross-cutting application infrastructure: runtime environment/server URL configuration, HTTP API client with W3C tracing, GoRouter navigation shell, zero-PII telemetry pipeline, and light theme tokens. At a glance:

- **Configuration** — AppConfig and AppConfigStorage manage Local/UAT/Production presets, custom base URL normalization/validation, and Hive-backed persistence with in-memory test fallback.
- **Networking** — ApiClient attaches bearer tokens, institution headers, and localhost fallbacks over TelemetryHttpClient, which injects W3C traceparent headers and sanitizes route IDs.
- **Routing** — routerProvider defines GoRouter auth redirects and a 6-branch StatefulShellRoute for Portal, Memories, Mood, Tasks, Health, and Activity Guide plus full-screen /story.
- **Telemetry** — TelemetryService enforces remote/debug sampling, HMAC-SHA256 pseudonymization and PHI/PII redaction in PIISanitizer, 5 MB BoundedRingBuffer eviction, and gzipped BatchDispatcher delivery.
- **Theme** — AppTheme and AppColors define the warm-neutral Montessori light theme and custom scroll behavior.

For every requirement, threshold, and entity shape, see `specs/000-product-baseline/spec.md`.
Do not restate those details here — this section indexes the spec.
---

## lib/data
<!-- blueprint:section state=distilled owner=specs/000-product-baseline -->
> **Distilled — owned by `specs/000-product-baseline`** (implemented at `lib/data/`).
> The full behavioral requirements live in that spec, which is the source of truth.
<!-- blueprint:code path=lib/data sha=99784d4ef8964903a8f00484439023be2a352ac8 -->

Data access layer providing abstract repository contracts, paired Mock and HTTP implementations, demo seed fixtures, and local demo-reset orchestration. At a glance:

- **Dual-mode repositories** — Eight Riverpod repository providers (auth, resident, care tasks, health vitals, meals, mood, memory, montessori, AI assistant) switch between Mock* and Http* implementations based on AppConfig.useMockData.
- **Regimen & batch HTTP client** — HttpCareTasksRepository integrates synchronous and async batch weekly Montessori regimen generation, refinement, scoring, cancellation, dismissal, and baseline fallback endpoints.
- **Seed fixtures** — Resident, food library, and Montessori activity fixtures provide offline demo profiles (Margaret, Robert, Dorothy) and ID mapping helpers.
- **Demo reset** — ProfileStorageManager resets mock repository state, HTTP task caches, and active resident state back to demo defaults.

For every requirement, threshold, and entity shape, see `specs/000-product-baseline/spec.md`.
Do not restate those details here — this section indexes the spec.
---

## lib/domain
<!-- blueprint:section state=distilled owner=specs/000-product-baseline -->
> **Distilled — owned by `specs/000-product-baseline`** (implemented at `lib/domain/`).
> The full behavioral requirements live in that spec, which is the source of truth.
<!-- blueprint:code path=lib/domain sha=2274ca4ee76ecb6377f37740e44c926303fa8459 -->

Pure Dart domain model defining the immutable entities, enums, clinical validation rules, and JSON mappers shared across data and presentation layers. At a glance:

- **Identity & profiles** — UserProfile (familyMember, visitingCaregiver, admin), DemoAccount, and Resident (biography, milestones, conditions, allergies, cognitive/physical capabilities) model users and care recipients.
- **Care tasks & regimens** — CareTask, RegimenPlan, RegimenBatchJob, and ClinicalScorecard model scheduled care tasks, async batch jobs, safety blocks, and low-score confirmation thresholds (compositeScore < 70).
- **Clinical & nutrition rules** — VitalSign.isAbnormal flags hypertension (>=140/90), heart rate (<55 or >100), fever/hypothermia (>100.4 or <96.0 F), and severe pain (>=7); MealLog.isLowIntake flags <=50% intake.
- **Wellbeing & memories** — MoodEntry, MemoryItem, MontessoriActivity, and AiMessage represent mood logs, shared family memories, curated Montessori activities, and Kubo AI chat turns.

For every requirement, threshold, and entity shape, see `specs/000-product-baseline/spec.md`.
Do not restate those details here — this section indexes the spec.
---

## lib/presentation
<!-- blueprint:section state=distilled owner=specs/000-product-baseline -->
> **Distilled — owned by `specs/000-product-baseline`** (implemented at `lib/presentation/`).
> The full behavioral requirements live in that spec, which is the source of truth.
<!-- blueprint:code path=lib/presentation sha=dedf285d02e9970255b13827c4a3d3a78c88d926 -->

Riverpod state notifiers and responsive Flutter UI screens across all user workflows: authentication, Family Portal, Their Story, Memory Box, Mood Journal, Care Tasks & AI Regimen planning, Health & Vitals, Meal Tracking, Activity Guide, AI Assistant drawer, and Server Settings. At a glance:

- **Auth & resident context** — AuthNotifier and ResidentNotifier manage credential login, demo profile switching, logout, and active resident selection.
- **Care tasks & regimen flows** — CareTasksNotifier and RegimenBatchNotifier manage task creation/status updates, async batch regimen polling, preview/refinement/apply sheets, and clinical safety/low-score gates.
- **Clinical & nutrition UI** — HealthVitalsNotifier and MealTrackerNotifier drive vitals recording, abnormal-vitals flagging, food library search, custom food entry, and daily nutrient target progress.
- **Engagement & AI UI** — FamilyPortalScreen, MemoryBoxScreen, MoodJournalScreen, ActivityGuideScreen, TheirStoryScreen, and AiAssistantDrawer deliver resident summaries, wellbeing alerts, memories, moods, activities, and contextual Kubo AI chat.
- **Responsive shell & settings** — ResponsiveLayout adapts between desktop SidebarNav and mobile AppBottomNav, while ServerSettingsModal allows runtime API URL validation, testing, and persistence.

For every requirement, threshold, and entity shape, see `specs/000-product-baseline/spec.md`.
Do not restate those details here — this section indexes the spec.
---

## lib (remainder)
<!-- blueprint:section state=distilled owner=specs/000-product-baseline -->
> **Distilled — owned by `specs/000-product-baseline`** (implemented at `lib/main.dart`).
> The full behavioral requirements live in that spec, which is the source of truth.
<!-- blueprint:code path=lib/main.dart sha=ffb2cc52a8b0b74901c1c4979d3c84493409668d -->

Application entrypoint that initializes Flutter bindings, telemetry, Hive config storage, and launches the Riverpod-wrapped MontessoriCareApp. At a glance:

- **Bootstrap** — main() initializes TelemetryService, filters transient Google Fonts network errors, loads AppConfigStorage, and runs ProviderScope(child: MontessoriCareApp()).
- **Global messenger** — Exposes rootScaffoldMessengerKey for shell-wide snackbar feedback.

For every requirement, threshold, and entity shape, see `specs/000-product-baseline/spec.md`.
Do not restate those details here — this section indexes the spec.
---

## linux
<!-- blueprint:section state=code -->
> **Distilled — owned by code at `linux/`.** (no spec yet) The implementation
> is the source of truth; this section maps it. To change it, `/speckit.specify`
> the area as usual and `distill` it when the spec ships.
<!-- blueprint:code path=linux sha=090caac750464503cf208a8bce8f822cdedfd364 -->

Linux desktop host shell built with CMake and GTK to embed the Flutter engine. At a glance:

- **Entry point** — main.cc launches MyApplication to host the Flutter view on Linux desktop.
- **Window setup** — my_application.cc configures the GTK window and registers Flutter plugins.

For exact behavior, read the code under `linux/`. Do not restate it here.
---

## macos
<!-- blueprint:section state=code -->
> **Distilled — owned by code at `macos/`.** (no spec yet) The implementation
> is the source of truth; this section maps it. To change it, `/speckit.specify`
> the area as usual and `distill` it when the spec ships.
<!-- blueprint:code path=macos sha=10070f5b7c7fb664425905b2ba1efb167f12ce08 -->

macOS desktop host shell that configures the Cocoa window, entitlements, and Flutter view controller. At a glance:

- **Entry point** — AppDelegate manages macOS application lifecycle for the Flutter runner.
- **Window controller** — MainFlutterWindow attaches FlutterViewController and registers generated plugins.

For exact behavior, read the code under `macos/`. Do not restate it here.
---

## test
<!-- blueprint:section state=code -->
> **Distilled — owned by code at `test/`.** (no spec yet) The implementation
> is the source of truth; this section maps it. To change it, `/speckit.specify`
> the area as usual and `distill` it when the spec ships.
<!-- blueprint:code path=test sha=cf8860e42371926b717c99a49074197b0dba6183 -->

Automated verification suite covering unit logic, widget screens/modals, end-to-end regimen specs, and Android/iOS platform harnesses. At a glance:

- **Unit tests** — Verifies AppConfig URL normalization/validation, ApiClient security/lifecycle, HTTP repositories, vitals thresholds, nutrient math, mood/memory repositories, and telemetry privacy/ring buffer/batching.
- **Widget tests** — Exercises CareTasks, HealthVitals, MealTracker, MoodJournal, MemoryBox, ActivityGuide, FamilyPortal, TheirStory, AiAssistantDrawer, and ServerSettingsModal.
- **Integration & platform tests** — Validates weekly regimen and async batch regimen workflows plus Android/iOS demo login, family portal, and story modal flows via platform_harness.dart.

For exact behavior, read the code under `test/`. Do not restate it here.
---

## web
<!-- blueprint:section state=code -->
> **Distilled — owned by code at `web/`.** (no spec yet) The implementation
> is the source of truth; this section maps it. To change it, `/speckit.specify`
> the area as usual and `distill` it when the spec ships.
<!-- blueprint:code path=web sha=4fe9534992c6f0ad350005e3b3349d3801becd8e -->

Web host shell providing the HTML entry page, PWA manifest, and web icons for Flutter web builds. At a glance:

- **Entry page** — index.html loads flutter_bootstrap.js and sets web page metadata.
- **PWA manifest** — manifest.json defines web app name, colors, and home-screen icons.

For exact behavior, read the code under `web/`. Do not restate it here.
---

## windows
<!-- blueprint:section state=code -->
> **Distilled — owned by code at `windows/`.** (no spec yet) The implementation
> is the source of truth; this section maps it. To change it, `/speckit.specify`
> the area as usual and `distill` it when the spec ships.
<!-- blueprint:code path=windows sha=9a06d64dbc8d50f869db87e8cc11820ce9805823 -->

Windows desktop host shell built with CMake and Win32 to host the Flutter engine. At a glance:

- **Entry point** — main.cpp initializes COM/Win32 and opens FlutterWindow.
- **Window host** — flutter_window.cpp embeds FlutterViewController and registers plugins.

For exact behavior, read the code under `windows/`. Do not restate it here.
---

## Regimen Timeout Sync & Delivery
<!-- blueprint:section state=distilled owner=specs/013-fix-regimen-timeout-sync -->
> **Distilled — owned by `specs/013-fix-regimen-timeout-sync`.** (implemented at `lib/presentation/a2ui/`, `lib/presentation/care_tasks/`, and `lib/data/repositories/`) The full detail lives in that feature spec, which is the source of truth. This section is a summary + index.
<!-- blueprint:code path=lib/presentation/a2ui sha=15f5bb7c6c984048b23a8d7ac3f3c6714ebe0455 -->

Delivers non-blocking background batch regimen completion with direct-by-job-ID fallback polling and renders both preview and applied activity reviews via the official Dart A2UI v1.0 renderer. At a glance:

- **Direct-by-ID fallback** — Falls back to getBatchJob(residentId, jobId) and plan hydration whenever getActiveBatchJob returns null or lacks the completed plan.
- **Non-blocking navigation** — Keeps all care tabs and resident switching interactive while background polling tracks active jobs and surfaces completion banners.
- **A2UI v1.0 review panels** — Renders RegimenPreviewSheet and applied CareTasksScreen detail sheets with a2ui_flutter and custom Kubo Regimen catalog components, stripping duplicate step prefixes.

For every requirement, threshold, and entity shape, see `specs/013-fix-regimen-timeout-sync/spec.md`.
Do not restate those details here — this section indexes the spec.
---

## Architecture — subsystem relations
<!-- blueprint:section state=context -->

Rendered from the recovery facts; every edge below is machine-validated by
the check gate (endpoints on the map, evidence tracked in git).

| from | kind | to | why |
|---|---|---|---|
| lib | uses | lib/core | Bootstraps TelemetryService, AppConfigStorage, AppTheme, AppScrollBehavior, and routerProvider. |
| lib/core | crosscuts | lib | Application bootstrap initializes TelemetryService, AppConfigStorage, AppTheme, and routerProvider. |
| lib/core | crosscuts | lib/data | Repositories read appConfigProvider to toggle mock vs HTTP mode and share apiClientProvider. |
| lib/core | crosscuts | lib/presentation | Screens and providers consume AppTheme/AppColors, appConfigProvider, apiClientProvider, and GoRouter navigation. |
| lib/core | uses | lib/presentation | GoRouter wires routes directly to presentation screens and the ResponsiveLayout shell (cycle with lib/presentation). |
| lib/data | uses | lib/core | Repositories depend on AppConfig for mock/live switching and ApiClient for authenticated HTTP requests. |
| lib/data | uses | lib/domain | Repositories and fixtures serialize, deserialize, and return domain entities across all care domains. |
| lib/data | uses | lib/presentation | ProfileStorageManager invokes residentProvider.notifier.resetToDemo() during full demo reset (cycle with lib/presentation). |
| lib/presentation | uses | lib | ResponsiveLayout references rootScaffoldMessengerKey from main.dart for global snackbar notifications (cycle with lib). |
| lib/presentation | uses | lib/core | Presentation consumes AppTheme/AppColors, appConfigProvider, apiClientProvider, and GoRouter. |
| lib/presentation | uses | lib/data | State notifiers invoke repository providers and ProfileStorageManager for all data reads and mutations. |
| lib/presentation | uses | lib/domain | Screens and notifiers render and mutate domain entities and enforce entity-level clinical flags. |
| test | uses | lib/core | Unit and widget tests verify AppConfig, ApiClient, and TelemetryService behavior directly. |
| test | uses | lib/data | Repository and integration tests exercise both Mock* and Http* repository implementations. |
| test | uses | lib/domain | Unit and widget tests construct domain entities and assert clinical/nutrition invariants. |
| test | uses | lib/presentation | Widget and platform tests pump presentation screens and Riverpod notifiers. |

<!-- blueprint:relation from=lib to=lib/core kind=uses evidence=lib/main.dart#routerProvider -->
<!-- blueprint:relation from=lib/core to=lib kind=crosscuts evidence=lib/main.dart#TelemetryService -->
<!-- blueprint:relation from=lib/core to=lib/data kind=crosscuts evidence=lib/data/repositories/care_tasks_repository.dart#appConfigProvider -->
<!-- blueprint:relation from=lib/core to=lib/presentation kind=crosscuts evidence=lib/presentation/shared/server_settings_modal.dart#appConfigProvider -->
<!-- blueprint:relation from=lib/core to=lib/presentation kind=uses evidence=lib/core/router/app_router.dart#ResponsiveLayout -->
<!-- blueprint:relation from=lib/data to=lib/core kind=uses evidence=lib/data/repositories/http_care_tasks_repository.dart#ApiClient -->
<!-- blueprint:relation from=lib/data to=lib/domain kind=uses evidence=lib/data/repositories/care_tasks_repository.dart#RegimenPlan -->
<!-- blueprint:relation from=lib/data to=lib/presentation kind=uses evidence=lib/data/local/profile_storage_manager.dart#residentProvider -->
<!-- blueprint:relation from=lib/presentation to=lib kind=uses evidence=lib/presentation/shared/responsive_layout.dart#rootScaffoldMessengerKey -->
<!-- blueprint:relation from=lib/presentation to=lib/core kind=uses evidence=lib/presentation/shared/server_settings_modal.dart#ServerSettingsModal -->
<!-- blueprint:relation from=lib/presentation to=lib/data kind=uses evidence=lib/presentation/auth/auth_provider.dart#authRepositoryProvider -->
<!-- blueprint:relation from=lib/presentation to=lib/domain kind=uses evidence=lib/presentation/care_tasks/care_tasks_provider.dart#RegimenPlan -->
<!-- blueprint:relation from=test to=lib/core kind=uses evidence=test/unit/config_test.dart#app_config.dart -->
<!-- blueprint:relation from=test to=lib/data kind=uses evidence=test/unit/http_repositories_test.dart#http_meal_repository.dart -->
<!-- blueprint:relation from=test to=lib/domain kind=uses evidence=test/unit/vitals_validation_test.dart#vital_sign.dart -->
<!-- blueprint:relation from=test to=lib/presentation kind=uses evidence=test/widget/server_settings_modal_test.dart#server_settings_modal.dart -->
