# Quickstart: Montessori Care App

## Prerequisites
- Flutter SDK 3.27+
- Dart SDK 3.x
- iOS Simulator / Android Emulator / Chrome for Web
- Zitadel Instance Configuration (Client ID, Issuer URL)

## Environment Setup
1. Clone the repository and navigate to the root directory.
2. Ensure you are on the feature branch: `git checkout 001-montessori-care-app` (or create it).
3. Run `flutter pub get` to install dependencies (Riverpod, Isar, etc.).
4. Run Isar code generation: `flutter pub run build_runner build --delete-conflicting-outputs`.
5. Configure your `.env` file with Zitadel credentials and MCP service endpoints.

## Running the App
- **iOS**: `flutter run -d ios`
- **Android**: `flutter run -d android`
- **Web**: `flutter run -d chrome`

## Project Structure Highlights
- `lib/core/theme`: Contains the Stitch "Prepared Environment" design tokens.
- `lib/data/local`: Contains Isar database schemas.
- `lib/presentation/`: Contains all UI components and screens, segmented by feature.
