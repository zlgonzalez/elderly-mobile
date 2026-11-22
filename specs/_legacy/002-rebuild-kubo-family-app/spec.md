# Feature Specification: Kubo Family App Rebuild from Figma Design

**Feature Branch**: `002-rebuild-kubo-family-app`  
**Created**: 2026-09-26  
**Status**: Draft  
**Input**: User description: "Use the Figma MCP server and retrieve the design with id SS7uN9hhaRvAmZDkyk5B9j, and rebuild the full app using the designs called out here completely."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Family Member Onboarding & Profile Access (Priority: P1)

As a family member caring for an aging loved one, I want to authenticate smoothly or select a pre-configured family profile so that I can immediately view my loved one's daily dashboard and personal updates.

**Why this priority**: Authentication and profile selection are the gateway to all family care interactions, ensuring authorized and personalized access.

**Independent Test**: Can be tested independently by launching the application, presenting the login screen with demo profile switching, authenticating as a family member, and landing on the Family Portal home screen.

**Acceptance Scenarios**:

1. **Given** an unauthenticated family member opens the app, **When** they view the login screen, **Then** they see options to log in with credentials or choose from available demo family member profiles.
2. **Given** a family member selects a valid profile or enters valid credentials, **When** the authentication succeeds, **Then** they are redirected to the Family Portal Home screen with their loved one's current status displayed.
3. **Given** a user enters invalid credentials, **When** the login attempt is processed, **Then** an informative error message is displayed and secure access is denied.

---

### User Story 2 - Family Portal Overview & Senior Story (Priority: P1)

As a family member, I want to navigate the central Family Portal to view my loved one's daily snapshot, read "Their Story", explore the Montessori Care Guide, and access quick actions so that I stay connected with their holistic wellbeing.

**Why this priority**: The Family Portal is the core landing hub where families review daily moments, senior background narratives, and care guidance principles.

**Independent Test**: Can be tested independently by opening the Family Portal, reviewing the daily highlights, tapping "Their Story" to review the biography/life narrative, and accessing the "Montessori Guide" principles.

**Acceptance Scenarios**:

1. **Given** a logged-in family member is on the Family Portal, **When** they view the screen, **Then** they see their loved one's summary, quick actions, recent memory previews, and daily status cards.
2. **Given** the user is on the Family Portal, **When** they tap "Their Story", **Then** a dedicated interactive narrative view opens showing the senior's biographical milestones, personal preferences, and background history.
3. **Given** the user is on the Family Portal, **When** they tap the "Montessori Guide Interaction", **Then** the application displays practical guidance on dignity-centered, independence-promoting Montessori senior care techniques.

---

### User Story 3 - Interactive Memory Box & Reminiscence (Priority: P2)

As a family member, I want to browse our shared Memory Box and contribute new photos, audio recordings, or memorable moments so that my loved one can engage in reminiscence therapy and maintain strong family connections.

**Why this priority**: Reminiscence is a cornerstone of Montessori dementia and senior care, reducing anxiety and strengthening identity.

**Independent Test**: Can be tested independently by opening the Memory Box tab, viewing the timeline/gallery of existing memories, tapping "Add to Memory Box", filling in memory details with media, and seeing the new memory published.

**Acceptance Scenarios**:

1. **Given** the user is on the Memory Box tab, **When** the screen renders, **Then** they see a chronological or thematic gallery of family memories, photos, and stories.
2. **Given** the user wishes to add a memory, **When** they tap "Add to Memory Box Interaction" and provide a title, description, and media asset, **Then** the memory is saved and immediately reflected in the Memory Box feed.
3. **Given** the user is exploring memories, **When** they tap "View all memories interaction", **Then** an expanded browsable catalog of historical family moments is displayed with filtering options.

---

### User Story 4 - Daily Mood Journal & Behavioral Tracking (Priority: P2)

As a family member or caregiver, I want to view and log daily mood states and behavioral observations so that our family and care circle can identify emotional patterns and trigger factors early.

**Why this priority**: Tracking emotional trends allows proactive interventions when mood drops, ensuring emotional safety and peace of mind.

**Independent Test**: Can be tested independently by navigating to the Mood Journal tab, reviewing historical mood trends, and recording a new daily mood evaluation.

**Acceptance Scenarios**:

1. **Given** the user is on the Mood Journal tab, **When** the page loads, **Then** they see historical mood graphs/cards showing emotional wellbeing trends over the week or month.
2. **Given** the user wants to log a mood observation, **When** they select an emotional state and optional context notes, **Then** the journal entry is saved and timeline trends update accordingly.

---

### User Story 5 - Care Tasks & Routine Management (Priority: P2)

As a family member, I want to track daily care tasks, view completed routines, and add new tasks for family or caregivers so that essential daily needs (hydration, walks, social activities) are never missed.

**Why this priority**: Routine care management coordinates family members and caregivers, distributing responsibilities clearly.

**Independent Test**: Can be tested independently by visiting the Care Tasks tab, checking off an active care task, and tapping "Add Tasks Interaction" to create a new scheduled care item.

**Acceptance Scenarios**:

1. **Given** the user is on the Care Tasks tab, **When** the page displays, **Then** they see scheduled tasks categorized by time of day (Morning, Afternoon, Evening) with completion status.
2. **Given** the user opens "Add Tasks Interaction", **When** they specify a task title, due time, and instructions, **Then** the task appears on the daily care schedule.
3. **Given** a pending task is due, **When** a family member marks it complete, **Then** the task status updates in real time for all family members.

---

### User Story 6 - Health, Vitals & Food Nutrition Tracking (Priority: P2)

As a family member, I want to review vital health measurements and log meal/hydration intake from a curated food library or custom items so that my loved one's physical health is closely monitored.

**Why this priority**: Physical health monitoring (blood pressure, hydration, nutrition) is vital for preventative care and safety.

**Independent Test**: Can be tested independently by navigating to Health & Vitals, inspecting vital statistic charts, browsing the Food Library, and logging custom food or hydration intake.

**Acceptance Scenarios**:

1. **Given** the user is on the Health and Vitals Homepage, **When** the view loads, **Then** vitals (blood pressure, resting heart rate, hydration level, sleep, weight) are clearly presented with indicator statuses.
2. **Given** the user accesses "Food Library Interaction", **When** they search or browse pre-defined dietary options, **Then** nutritional items can be selected and added to the daily intake log.
3. **Given** a senior consumes a homemade or non-standard meal, **When** the user uses "Custom Food Interaction" to record custom meal details and portion size, **Then** the entry is recorded under today's nutrition log.

---

### User Story 7 - Montessori Activity Guide (Priority: P3)

As a family member visiting my loved one, I want to access guided Montessori activities specifically curated for cognitive, sensory, and motor engagement so that our visits are purposeful and joyful.

**Why this priority**: Provides actionable ideas for meaningful visits, avoiding passive interactions and fostering autonomy.

**Independent Test**: Can be tested independently by opening the Activity Guide tab, browsing activity categories, selecting an activity, and reading step-by-step engagement instructions.

**Acceptance Scenarios**:

1. **Given** the user opens the Activity Guide, **When** they view the catalog, **Then** activities are organized by cognitive stage, sensory focus, and duration.
2. **Given** the user selects an activity, **When** the detail card opens, **Then** it presents the required materials, step-by-step facilitation prompts, and expected engagement benefits.

---

### User Story 8 - Contextual "Ask Kubo AI" Assistant (Priority: P3)

As a family member navigating any section of the app, I want to consult an intelligent "Ask Kubo AI" assistant tailored to that specific context (Family Portal, Memory Box, Mood Journal, Care Tasks, Health & Vitals) so that I receive immediate, compassionate guidance.

**Why this priority**: Contextual intelligence empowers families with expert answers on dementia care, memory cues, mood changes, and nutritional guidance without leaving their current task.

**Independent Test**: Can be tested independently by tapping the "Ask Kubo AI" button from within any tab, submitting a question or picking suggested prompts, and receiving a contextual response.

**Acceptance Scenarios**:

1. **Given** the user is on any tab (Family Portal, Memory Box, Mood Journal, Care Tasks, or Health & Vitals), **When** they tap the corresponding "Ask Kubo AI" interaction, **Then** the assistant opens pre-seeded with context relevant to that tab.
2. **Given** the user sends a query or selects a suggested question prompt, **When** the AI processes the prompt, **Then** a supportive, dementia-informed answer is provided with actionable suggestions.

---

### Edge Cases

- **Offline / Low-Connectivity Access**: When the device loses network connectivity, the system must allow viewing cached memories, vitals, care tasks, and offline draft submission with automatic synchronization when back online.
- **Missing or Partial Health Data**: If a senior has no recorded vitals or meal logs for the current day, the system must display reassuring empty states that encourage logging rather than alarming error warnings.
- **Large Multimedia Uploads in Memory Box**: If a family member attempts to upload high-resolution media under poor network conditions, the upload must queue gracefully in the background with visible progress indication.
- **Multiple Family Members Updating Concurrently**: When two family members complete or edit the same care task simultaneously, conflict resolution must favor the latest completed state without data loss.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a secure authentication screen with support for demo profile switching to enable quick multi-user testing and production sign-in.
- **FR-002**: System MUST display a primary navigation structure providing seamless access to the 6 core tabs: Family Portal, Memory Box, Mood Journal, Care Tasks, Health & Vitals, and Activity Guide.
- **FR-003**: System MUST provide the Family Portal dashboard showing daily senior status, recent family memories, and entry points into "Their Story" and the "Montessori Guide".
- **FR-004**: System MUST allow users to view biographical narrative cards and life history milestones in the "Their Story" section.
- **FR-005**: System MUST provide a visual Memory Box timeline where users can view, filter, and contribute new memories with titles, descriptions, and media attachments.
- **FR-006**: System MUST track daily mood assessments, displaying emotional trend charts and logging observations with contextual tags.
- **FR-007**: System MUST provide a Care Tasks checklist organized by time of day, allowing family members and caregivers to mark tasks complete and create custom care routines.
- **FR-008**: System MUST display vital signs tracking (blood pressure, heart rate, hydration, weight, sleep) with status indicators and historical graphs.
- **FR-009**: System MUST provide both a searchable Food Library and a Custom Food logging flow for tracking meals and hydration intake.
- **FR-010**: System MUST provide an interactive Activity Guide with Montessori-aligned activities filtered by cognitive level, sensory type, and duration.
- **FR-011**: System MUST provide contextual "Ask Kubo AI" interaction surfaces accessible from each major tab (Family Portal, Memory Box, Mood Journal, Care Tasks, Health & Vitals).
- **FR-012**: System MUST adhere strictly to the visual design tokens, color palette (`#F2FAF5` base background, calm restorative tones), typography, and component hierarchy extracted from Figma design `SS7uN9hhaRvAmZDkyk5B9j`.
- **FR-013**: System MUST support [NEEDS CLARIFICATION: AI query mode - streaming LLM response vs pre-baked conversational guidance cards when offline].
- **FR-014**: System MUST support [NEEDS CLARIFICATION: User role scope - family-only interface vs unified toggle between Family and Staff/Caregiver views].
- **FR-015**: System MUST support [NEEDS CLARIFICATION: Default launch destination - start with Demo Profile Selector vs direct Login screen].

### Key Entities

- **Senior Resident / Loved One**: The individual at the center of care (name, photo, biography, care notes, cognitive baseline).
- **Family Member Profile**: The authenticated user (name, relationship to senior, contact info, permissions).
- **Memory Item**: A recorded memory unit (title, description, timestamp, author, media asset URLs, tags).
- **Mood Entry**: An emotional status record (date/time, mood score/category, behavioral notes, logger identity).
- **Care Task**: A scheduled care obligation (title, due time, recurrence, category, completion status, assigned caregiver/family member).
- **Vital Sign Log**: A physiological measurement entry (metric type, value, unit, timestamp, status indicator).
- **Food / Hydration Log**: A nutritional intake record (item name, portion/quantity, meal type, calories/nutritional breakdown, timestamp).
- **Montessori Activity**: A structured engagement activity (title, category, cognitive level, materials required, step-by-step instructions, benefits).
- **AI Conversation Context**: Contextual dialogue history and suggested prompt chips associated with a specific tab.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Family members can view their loved one's daily status and latest vitals within 5 seconds of opening the application.
- **SC-002**: A family member can create and publish a new memory to the Memory Box in under 60 seconds.
- **SC-003**: 100% of the screens, dialogs, and interactions defined in Figma file `SS7uN9hhaRvAmZDkyk5B9j` (Login, Family Portal, Memory Box, Mood Journal, Care Tasks, Health & Vitals, Activity Guide, and contextual AI screens) are faithfully represented with high visual fidelity.
- **SC-004**: Family members can mark a care task complete with a single tap, with confirmation feedback appearing in under 300 milliseconds.
- **SC-005**: All primary screens render responsively with comfortable tap targets (minimum 48x48 points) and high contrast typography meeting senior and family accessibility standards.
- **SC-006**: 90% of first-time family testers successfully locate and launch a recommended Montessori activity in under 30 seconds without prior training.

## Assumptions

- Target audience consists of family members and loved ones of seniors in memory care or home-assisted living.
- Visual theme defaults to the calming, accessible light aesthetic defined in the Figma designs (soft greens, warm neutrals, high-legibility sans-serif typography).
- Mobile device form factor (iOS and Android, standard viewport width ~401px as specified in the Figma design frames) is the primary target, with responsive adaptation for wider tablet/web viewports.
- Local persistence allows full inspection, demoing, and offline testing of all feature journeys even without an active cloud backend connection.
