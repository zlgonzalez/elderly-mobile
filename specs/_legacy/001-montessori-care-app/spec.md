# Feature Specification: Montessori Care App

**Feature Branch**: `[001-montessori-care-app]`  
**Created**: 2026-04-25  
**Status**: Draft  
**Input**: User description: "Using the Stitch MCP, fetch the current designs for the 'Montessori Senior Care Guide' project. Generate a comprehensive specification for a Flutter mobile application targeting Web, iOS, and Android. Key Objectives: Visual Fidelity, Platform Adaptation, Microservice Integration Readiness."

## Clarifications

### Session 2026-04-25

- Q: Offline Capability Requirement → A: Offline-First (Local data cache, allows offline reads and writes with background sync)
- Q: Role/Permission Differentiation → A: Role-Based (Admins manage staff/settings; caregivers only view assigned residents and log care)
- Q: Empty State UX Strategy → A: Encouraging & Action-Oriented (e.g., "All tasks complete! Review past meaningful work logs.")
- Q: Authentication Token Expiration Handling → A: Graceful Re-login (Prompt user to re-authenticate via a modal, preserving their current unsubmitted data/state)
- Q: Dark Mode UI Adaptation → A: Lock to Light Mode (Enforce Light Mode at the application level to preserve the specific Montessori aesthetic)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure Staff Authentication (Priority: P1)

As a caregiver or facility staff member, I want to securely log into the application so that I can access my personalized dashboard and resident information.

**Why this priority**: Essential for protecting sensitive health data and providing role-based access.

**Independent Test**: Can be fully tested by launching the app, seeing the Welcome to Evergreen screen, navigating to the Staff Login screen, logging in successfully, and being redirected to the Evergreen Dashboard.

**Acceptance Scenarios**:

1. **Given** a new or unauthenticated user opens the app, **When** the app loads, **Then** they see the "Welcome to Evergreen" onboarding screen.
2. **Given** the user is on the Staff Login screen, **When** they enter valid credentials, **Then** they are authenticated via Zitadel and redirected to their dashboard.
3. **Given** the user is on the Staff Login screen, **When** they enter invalid credentials, **Then** an error message is displayed and access is denied.

---

### User Story 2 - Multi-Platform Navigation (Priority: P1)

As a user on a mobile device or desktop browser, I want a navigation layout that is optimized for my screen size so that I can easily move between the Dashboard, Residents list, and Care Logs.

**Why this priority**: Central to providing a unified but responsive experience across Web, iOS, and Android.

**Independent Test**: Can be fully tested by resizing the window or launching on different platforms to verify the navigation pattern switches between Sidebar and Bottom Nav.

**Acceptance Scenarios**:

1. **Given** the application is running on Web or Desktop (wide viewport), **When** the user opens the app, **Then** a persistent Sidebar navigation menu is displayed.
2. **Given** the application is running on iOS or Android (narrow viewport), **When** the user opens the app, **Then** a Bottom Navigation bar is displayed.

---

### User Story 3 - Caregiver Handover & Dashboard (Priority: P2)

As a caregiver, I want to view my current shift's priorities and a summary of my residents' status so that I can organize my daily tasks effectively.

**Why this priority**: Core workflow for the staff members interacting with the residents.

**Independent Test**: Can be fully tested by navigating to the Evergreen Dashboard and observing the summary data.

**Acceptance Scenarios**:

1. **Given** the caregiver is authenticated, **When** they access the Evergreen Dashboard, **Then** they see a personalized summary of their shift and tasks.
2. **Given** the caregiver is on the Facility Caregiver Dashboard, **When** they select "Caregiver Handover", **Then** they see critical updates from the previous shift.

---

### User Story 4 - Resident Profile & Care Logs (Priority: P2)

As a caregiver, I want to access a resident's profile and log meaningful work or care activities so that there is an accurate record of their daily engagement.

**Why this priority**: Essential for fulfilling the "Montessori Senior Care" philosophy by tracking meaningful engagement.

**Independent Test**: Can be fully tested by selecting a resident and adding a new entry to the Meaningful Work Log.

**Acceptance Scenarios**:

1. **Given** the user is viewing the "My Residents" list, **When** they select a resident, **Then** the detailed Resident Profile is displayed.
2. **Given** the user is on a Resident Profile, **When** they submit a Care Log entry, **Then** the record is saved and visible in the resident's history.

---

### User Story 5 - CareGuide AI Assistant (Priority: P3)

As a caregiver, I want to ask the CareGuide AI Assistant questions about a resident's care plan or general Montessori techniques so that I can provide better, personalized care.

**Why this priority**: A value-added feature that enhances care quality but isn't required for basic data entry and tracking.

**Independent Test**: Can be fully tested by opening the CareGuide AI Assistant, submitting a query, and receiving a relevant response.

**Acceptance Scenarios**:

1. **Given** the user is on the CareGuide AI Assistant screen, **When** they ask a question, **Then** they receive a response formatted according to the application's design system.

---

### User Story 6 - Profile Settings (Priority: P3)

As a caregiver, I want to view and manage my profile settings so that I can configure my application preferences.

**Why this priority**: Necessary for basic user management, but not blocking core daily caregiving workflows.

**Independent Test**: Can be fully tested by navigating to the Profile Settings screen and updating a preference.

**Acceptance Scenarios**:

1. **Given** the user is authenticated, **When** they navigate to the Profile Settings screen, **Then** they can view their profile information and adjust app settings.

---

### Edge Cases

- **Network Loss**: The application is offline-first. If internet connectivity is lost while submitting a Care Log, the data is cached locally and synchronized automatically in the background when connectivity is restored.
- **Empty States**: If a list or dashboard is empty (e.g., no assigned residents or tasks), the UI displays encouraging, action-oriented text (e.g., "All tasks complete! Review past meaningful work logs.") rather than standard error/no-data messages.
- **Token Expiration**: If the session token expires, the user is presented with a graceful re-authentication modal that preserves their unsubmitted data and state while they log back in.
- **Dark Mode**: The application enforces a Light Mode theme to preserve the therapeutic "Prepared Environment" aesthetic, ignoring system-wide Dark Mode settings.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-000**: System MUST implement an offline-first architecture, allowing local caching of data and background synchronization for reads and writes when offline.
- **FR-001**: System MUST provide a unified Flutter codebase deployable to iOS, Android, and Web.
- **FR-002**: System MUST implement responsive navigation: Sidebar for wide viewports (Web) and Bottom Navigation for narrow viewports (Mobile).
- **FR-003**: System MUST adhere strictly to the "Prepared Environment" design system tokens (Primary: `#4c614b`, Typography: Newsreader/Public Sans).
- **FR-004**: System MUST authenticate users against a Zitadel identity provider.
- **FR-005**: System MUST structure state management and data access layers to facilitate future integration with separate microservices.
- **FR-006**: System MUST display caregiver-specific dashboards (Evergreen Dashboard, Caregiver Handover).
- **FR-007**: System MUST allow users to view resident profiles and submit entries to the Care Log and Meaningful Work Log.
- **FR-008**: System MUST include a conversational interface for the CareGuide AI Assistant.
- **FR-009**: System MUST provide a Profile Settings screen for users to manage their preferences.

### Key Entities *(include if feature involves data)*

- **Admin**: Facility staff with privileges to manage settings and staff assignments.
- **Caregiver**: Staff member with access limited to viewing assigned residents and logging care.
- **Resident**: Senior individual receiving care, associated with specific profiles and logs.
- **Care Log / Activity**: Record of an event or meaningful work associated with a Resident.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The application successfully builds and runs on iOS, Android, and Web platforms from a single codebase.
- **SC-002**: The UI visually matches the provided Stitch designs, scoring >95% fidelity in design reviews regarding colors, fonts, and spacing.
- **SC-003**: Navigation layout dynamically and correctly switches between Sidebar and Bottom Nav based on the viewport width (e.g., breakpoint at 800px).
- **SC-004**: The application successfully authenticates a user via Zitadel and retrieves a valid session token.
- **SC-005**: The architecture utilizes a clearly defined repository pattern, ensuring that data-fetching logic is decoupled from UI components.

## Assumptions

- Users have stable internet connectivity for authenticating and fetching initial data.
- The Zitadel instance is already configured and accessible.
- Microservice APIs are either defined or will follow REST/gRPC standards, so the Flutter app should implement abstract repository interfaces to mock data until APIs are ready.

