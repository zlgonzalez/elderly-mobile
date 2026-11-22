# Quickstart Guide: Kubo North Mobile App

## 1. Prerequisites
- **Flutter SDK**: 3.44.x or higher (Dart 3.12.x+)
- **Operating Systems**: macOS (iOS Simulator / Android Emulator), Linux, Windows
- **Tools**: Make (via command line)

---

## 2. Running with Make

The project includes a root `Makefile` to simplify all common development workflows.

### 2.1 Run in Debug Mode (Default: Mock Data)
```bash
make run
```
Launches the Flutter application with local mock data providers enabled.

### 2.2 Run with Real Microservices
```bash
make run-prod API_URL=https://api.kubonorth.example.com
```
Disables mock data providers and points the client HTTP repositories to the provided microservice base URL.

### 2.3 Run Tests
```bash
# Run all tests
make test

# Run iOS-specific widget and unit tests
make test-ios

# Run Android-specific widget and unit tests
make test-android
```

### 2.4 Code Analysis & Formatting
```bash
make analyze
make format
```

### 2.5 Multi-Platform Builds
```bash
# Android APK
make build-apk

# iOS Archive / Bundle
make build-ios
```

---

## 3. Microservice Integration Strategy

### 3.1 Tagged Integration Points
All data repositories use abstract interfaces. Every place where real microservices must be connected is annotated with:
```dart
// [MICROSERVICE_INTEGRATION_POINT]: <Service Name> - <Endpoint description>
// TODO(microservice): Replace mock data with: final res = await apiClient.get('/api/v1/...');
```

### 3.2 Toggling Mock Mode
You can toggle between mock data and real microservices without code changes via `--dart-define`:
```bash
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://your-server:8080/api/v1
```
Or in code by switching the `useMockDataProvider` Riverpod override.
