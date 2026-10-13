# Feature Specification: Configurable Server Connection Settings

**Feature Branch**: `004-configurable-api-url`  
**Created**: 2026-10-12  
**Status**: Draft  
**Input**: User description: "Create a settings panel in the mobile app so that the base url for the microservices is something that can be modified. This should be the base url that will be used in the mobile app. The goal is to be able to let this mobile app installed in a Google pixel phone can use the microservices stack running on my macbook if both the phone and the macbook are on the same WiFi."

## Clarifications

### Session 2026-10-12

- Q: How should the Settings panel handle shorthand entries (such as entering just the MacBook's IP address `192.168.1.50` or `192.168.1.50:8080`)? → A: Smart shorthand + Full URL (accept either a full URL or a bare IP/host, auto-prepending `http://`, defaulting port `:8080` if omitted for bare hosts/IPs, and appending `/api/v1` if no path is given).
- Q: When a user is already signed into the main care portal and changes or resets the microservices Base URL, how should the app handle their active session and loaded data? → A: Refresh in-place (keep the user on the current screen and immediately reload active resident and portal data from the new server URL).
- Q: How should the Settings panel be presented when the user taps the Settings button? → A: Modal bottom sheet / overlay (opens over the current screen and dismisses cleanly when saved or closed).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Custom Server Address from Sign-In Screen (Priority: P1)

A tester or caregiver using the mobile app on a physical phone (such as a Google Pixel) connected to the same local Wi-Fi network as a computer running the backend services needs to point the mobile app to that computer's network address before signing in, so the app can load demo profiles, authenticate, and fetch care data from the local server.

**Why this priority**: Without the ability to change the server address on the initial welcome/sign-in screen, a user on a physical phone cannot load dynamic demo profiles or sign in against a local network server, blocking all downstream app usage.

**Independent Test**: Open the mobile app on a phone, open the Settings panel from the welcome/sign-in screen, enter the local network address of the computer running the services, save the change, and verify that the app immediately uses the new address to load accounts and sign in.

**Acceptance Scenarios**:

1. **Given** the user is on the initial welcome/demo profile screen or sign-in screen, **When** they tap the Settings icon/button, **Then** the Server Connection Settings modal bottom sheet/overlay opens over the current screen displaying the currently active server base URL.
2. **Given** the Server Connection Settings panel is open, **When** the user enters a valid local network base URL (e.g., `http://192.168.1.100:8080/api/v1`) or shorthand IP/host (e.g., `192.168.1.100`) and saves, **Then** the app normalizes and updates its active base URL immediately, dismisses the modal, and reloads the available demo profiles from that server.
3. **Given** a custom base URL has been saved, **When** the user closes and restarts the mobile app, **Then** the previously saved custom base URL remains active without requiring re-entry.

---

### User Story 2 - Modify or Reset Server Address While Signed In (Priority: P2)

An authenticated user already inside the main care portal wants to inspect, update, or reset the server base URL back to the default address without having to reinstall the app or clear device storage.

**Why this priority**: Allows users and testers to switch between different local machines or restore default settings at any point during an active session.

**Independent Test**: From the main care portal header, open the Settings panel, click "Reset to Default", and verify the base URL returns to the platform default and persists across restarts.

**Acceptance Scenarios**:

1. **Given** the user is signed into the main portal, **When** they open the Settings panel from the app header, **Then** the modal bottom sheet/overlay opens over the current screen so they can view and edit the current base URL.
2. **Given** the user is signed in and saves a new base URL or selects "Reset to Default" in the Settings panel, **Then** the base URL updates immediately, the user remains on their current screen, and active resident/portal data refreshes in-place from the new server URL.

---

### User Story 3 - Validate Server URL and Test Connection (Priority: P3)

When entering a network address on a mobile keyboard, a user wants immediate validation of the address format and a way to verify whether the target server is reachable on the Wi-Fi network before leaving the Settings panel.

**Why this priority**: Prevents frustrating silent failures caused by typos in IP addresses, missing port numbers, or Wi-Fi firewall/isolation issues.

**Independent Test**: Open the Settings panel, enter an invalid address or unreachable IP, tap "Test Connection" or "Save", and verify clear feedback is displayed indicating whether the format is valid and whether the server responded.

**Acceptance Scenarios**:

1. **Given** the user is editing the base URL in the Settings panel, **When** they attempt to save an empty or malformed address (e.g., invalid host characters or unsupported scheme), **Then** the panel displays a clear validation message and prevents saving the invalid address.
2. **Given** the user has entered a valid base URL or shorthand IP/host in the Settings panel, **When** they tap "Test Connection", **Then** the app normalizes the input, attempts to reach the server, and displays a clear success or unreachable error message within 5 seconds.

---

### Edge Cases

- What happens when the user enters a shorthand IP/host (e.g., `192.168.1.50` or `192.168.1.50:8080`) or a URL with a trailing slash (e.g., `http://192.168.1.50:8080/api/v1/`)? The system automatically normalizes the input by prepending `http://` if no scheme is present, defaulting to port `:8080` if no port is specified on a shorthand entry, appending `/api/v1` if no path is provided, and trimming any trailing slashes.
- What happens when the configured local network server becomes unreachable (e.g., the laptop goes to sleep or Wi-Fi disconnects)? The app fails gracefully within the standard request timeout, displays user-friendly error/fallback states, and still allows the user to open the Settings panel to update or reset the URL.
- What happens when a physical Android device connects to an unencrypted `http://` local network IP address (e.g., `http://192.168.x.x:8080`)? The mobile app permits cleartext HTTP traffic for local network connections so physical phones can communicate with local development servers over Wi-Fi without security policy blocks.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The mobile app MUST provide a Settings panel presented as a modal bottom sheet/overlay accessible from both the unauthenticated welcome/sign-in screens and the authenticated main portal header.
- **FR-002**: The Settings panel MUST display the currently active microservices base URL and allow the user to input and save a custom base URL or shorthand host/IP.
- **FR-003**: The system MUST validate the input before saving, ensuring it is non-empty and resolves to a valid `http://` or `https://` URL with a valid host or IP address.
- **FR-004**: The system MUST normalize saved base URLs by auto-prepending `http://` when no scheme is provided, applying default port `:8080` when no port is given for shorthand entries, appending `/api/v1` when no path is specified, and removing any trailing slashes.
- **FR-005**: All backend service requests and media URL resolutions across the mobile app MUST dynamically use the currently configured base URL immediately after it is updated, refreshing active resident and portal data in-place without signing out or requiring an app restart.
- **FR-006**: The system MUST persist the user's configured base URL locally on the device so that it is automatically restored when the app is closed and reopened.
- **FR-007**: The Settings panel MUST provide a "Reset to Default" action that clears any custom override and restores the platform's default base URL.
- **FR-008**: The Settings panel MUST provide a "Test Connection" action that checks reachability of the entered base URL and reports success or failure to the user.
- **FR-009**: The mobile app on physical devices MUST support HTTP connections to local network IP addresses (such as `192.168.x.x`, `10.x.x.x`, and `172.16.x.x`–`172.31.x.x`) over Wi-Fi.

### Key Entities

- **Server Connection Configuration**: Represents the user's server endpoint preferences, including the active base URL, whether a custom URL override is currently in effect, and the platform default base URL.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user on a physical phone can open the Settings panel, enter a local network base URL, and save the configuration in under 30 seconds.
- **SC-002**: 100% of backend service requests (authentication, resident profiles, care tasks, vitals, meals, mood journal, memory box, activities, and AI assistant) route to the newly saved base URL immediately upon saving, with 0 app restarts required.
- **SC-003**: Custom base URL settings persist across 100% of app restarts until explicitly changed or reset by the user.
- **SC-004**: Connection test feedback is presented to the user within 5 seconds of initiating a connection test, clearly distinguishing between a reachable server and an unreachable address.

## Assumptions

- Both the mobile device (e.g., Google Pixel phone) and the host computer (e.g., MacBook) are connected to the same Wi-Fi network and the network router allows client-to-client local communication.
- All backend microservices are accessed through a single unified gateway base URL (e.g., `http://<macbook-ip>:8080/api/v1`) rather than requiring separate URLs for each individual microservice.
- Any user with access to the device can modify the server base URL via the Settings panel without requiring special administrative credentials, as this setting is needed prior to sign-in.
