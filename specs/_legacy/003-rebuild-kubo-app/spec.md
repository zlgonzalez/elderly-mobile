# Feature Specification: Kubo North Family Care App Rebuild from Figma Design

**Feature Branch**: `003-rebuild-kubo-app`  
**Created**: 2026-09-26  
**Status**: Draft  
**Input**: User description: "Use the Figma figma-framelink MCP server and retrieve the design with id wMzyM9baD4XT5PLTu2sijV, and rebuild the full app using the designs called out here completely."

## Clarifications

### Session 2026-09-26

- Q: How should caregiver actions and sign-offs be accommodated in this family-facing application? → A: Family-first with visiting caregiver simulation: Family view is active by default; task sign-offs and vitals recording allow selecting the performing actor (Family Member vs. Visiting Caregiver/Nurse, e.g. Nurse Jane).
- Q: How should local data persistence behave when switching between different resident profiles during testing and demonstrations? → A: Independent persistent state per resident: Edits, vitals, meals, and memories persist independently per resident profile in local storage, with an explicit "Reset to Demo" action in profile settings.
- Q: How should user-uploaded media (photos and videos) be stored and handled in the Memory Box? → A: Dual input (Local File Picker with client-side compression + URL paste): Users can upload local device images/videos (automatically downscaled/compressed for client storage) or paste external media URLs.
- Q: How should the live LLM assistant service be configured in the client application? → A: Build-time environment variable only: The AI service reads from a build-time environment variable (e.g., VITE_GEMINI_API_KEY) with automatic fallback to curated Montessori guidance cards when unset or offline.
- Q: What should be the default entry screen when a user first opens the application? → A: Demo Profile Selector first: Launch directly into the one-tap demo profile cards (Margaret, Robert, Dorothy) for friction-free testing, with an accessible link to the standard username/password login screen.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Family Member Authentication & Demo Profile Switching (Priority: P1)

As a family member caring for an aging loved one, I want to sign in with my account or select from pre-configured demo family profiles (e.g., Margaret Thompson's family, Robert Chen's family, Dorothy Williams's family) so that I can quickly access and test my loved one's personalized care dashboard.

**Why this priority**: Authentication and profile access are foundational prerequisites for delivering personalized care data, loved one biographies, and family coordination.

**Independent Test**: Can be verified independently by launching the application, presenting the login screen and demo profile selector, selecting a family profile (e.g., Sarah Thompson caring for Margaret Thompson), and verifying seamless entry into the Family Portal home dashboard with personalized information.

**Acceptance Scenarios**:

1. **Given** an unauthenticated user opens the app, **When** they view the initial authentication flow, **Then** they see options to sign in with username and password, create a new account, or tap a demo profile button.
2. **Given** a user navigates to the demo login selector, **When** they view the screen, **Then** pre-configured family cards are displayed with resident names, resident age, and family member details (e.g., Margaret's family with `sarah.thompson`, Robert's family with `lisa.chen`, Dorothy's family with `james.williams`).
3. **Given** a user selects a demo family card or signs in with valid credentials, **When** the session begins, **Then** the app transitions into the Family Portal with the corresponding resident's active profile and care circle state.
4. **Given** an authenticated user is on any tab, **When** they tap the "Switch" action next to the active resident header, **Then** the user can switch between managed family profiles without losing local state.

---

### User Story 2 - Family Portal Dashboard & Daily Snapshot (Priority: P1)

As a family member, I want to view a centralized dashboard for my loved one that highlights their current status, recent mood, biographical links, Montessori care principles, and recent memories so that I stay connected with their overall wellbeing.

**Why this priority**: The Family Portal is the core landing screen and emotional anchor for families, consolidating critical daily signals and fast actions in one unified space.

**Independent Test**: Can be verified independently by navigating to the Family Portal tab, confirming that the resident header (name, age, family contact info), daily status cards, mood indicators, "Their Story" card, "Montessori Guide" banner, and latest memory previews display accurately.

**Acceptance Scenarios**:

1. **Given** the user lands on the Family Portal, **When** the dashboard renders, **Then** they see the resident header with Margaret Thompson (Age 82), family contact (Sarah Thompson, Daughter, 555-0123), and circle indicator ("Home Circle · Family Care").
2. **Given** the user is viewing the dashboard summary, **When** checking recent signals, **Then** a prominent status card indicates the latest mood assessment status, recent vitals, and scheduled routine alerts.
3. **Given** the user views the life narrative section, **When** they tap the "Their full story" action, **Then** the dedicated biographical narrative and milestone view opens smoothly.
4. **Given** the user views the memory highlight on the portal, **When** they tap "View all" or "Add Memory", **Then** the interface routes to the full Memory Box or launches the contribution sheet.

---

### User Story 3 - Senior Story & Biographical Milestones (Priority: P1)

As a family member or caregiver, I want to explore my loved one's life portrait, teaching career history, milestones, and personal philosophy so that our entire care circle honors their identity and personal history.

**Why this priority**: Centering care on the individual's life history is the bedrock of dignity-centered Montessori senior care, transforming clinical interactions into meaningful human connections.

**Independent Test**: Can be verified independently by opening "Their Story" from the Family Portal, reviewing the biographical overview (e.g. Margaret Thompson, 35-year elementary teacher in Burlington VT), browsing chronological milestones (1965 wedding, 1998 award, 2000 retirement, 2018 bereavement), and reading family memory reflections.

**Acceptance Scenarios**:

1. **Given** the user triggers "Their Story", **When** the view opens, **Then** they see the resident's Life Portrait including professional background, alma mater, education philosophy quote, and personal interests (Gardening, Reading, Watercolour painting, Birdwatching).
2. **Given** the user scrolls the biography, **When** viewing the milestone timeline, **Then** key life events with historical dates and explanatory narratives are clearly rendered in sequence.
3. **Given** the user is on the story screen, **When** they tap "Add a Memory", **Then** the multi-media memory creation dialog opens pre-linked to the resident's story.

---

### User Story 4 - Memory Box & Multi-Format Reminiscence (Priority: P2)

As a family member, I want to browse our shared family Memory Box and contribute photos, stories, letters, and videos with titles, dates, author credits, and tags so that my loved one can engage in reminiscence therapy.

**Why this priority**: Preserving and celebrating family memories stimulates cognitive engagement, decreases anxiety, and creates shared joy during visits.

**Independent Test**: Can be verified independently by opening the Memory Box tab, viewing existing memory items, tapping "Add to Memory Box", selecting a memory type (Photo, Story, Letter, Video), entering required metadata, and confirming the new memory appears in the feed.

**Acceptance Scenarios**:

1. **Given** the user is on the Memory Box tab, **When** the page renders, **Then** memory cards are displayed with media thumbnails, titles (e.g., "Wedding Day 1965", "Teaching Career", "Garden in Full Bloom"), dates, authors, and tag chips (e.g., `#wedding`, `#career`, `#garden`).
2. **Given** the user taps "Add to Memory Box", **When** the creation modal opens, **Then** they can choose between Photo, Story, Letter, or Video format tabs.
3. **Given** the user fills in the memory form, **When** providing Title (required), Photo URL/asset, Date, Shared By attribution, and comma-separated tags, and tapping "Save Memory", **Then** the memory validates, saves immediately, and appends to the memory collection.
4. **Given** the user is exploring memories, **When** they tap on an individual memory card, **Then** an expanded view displays full story text and high-resolution imagery.

---

### User Story 5 - Daily Care Tasks & Routine Coordination (Priority: P2)

As a family member or visiting caregiver, I want to view today's scheduled care activities, track completion progress, mark tasks as complete/skipped, and schedule new purposeful activities so that daily care routines are transparently coordinated.

**Why this priority**: Care circles require shared accountability to ensure physical, social, and purposeful engagement needs are fulfilled every day without duplicative or missed care.

**Independent Test**: Can be verified independently by navigating to Care Tasks, verifying the daily progress summary (e.g., "1/3 completed today"), changing a task state (Start, Complete, Skip), and using "Add Task" to schedule a new activity with custom timing and instructions.

**Acceptance Scenarios**:

1. **Given** the user opens the Care Tasks tab, **When** the screen renders, **Then** today's schedule lists activities grouped with time (e.g., 09:00 AM, 02:00 PM, 04:00 PM), category badges (`physical`, `activity`, `social`), care instructions, and completion status.
2. **Given** an active routine item (e.g., "Folding Laundry" or "Music Reminiscence Session"), **When** the user taps "Complete", **Then** the task updates to completed with recorded attribution (e.g., "✓ Sarah Thompson") and the progress meter increments.
3. **Given** the user taps "Add Task", **When** the "Schedule New Activity" sheet displays, **Then** they can enter an Activity Title (e.g., "Afternoon Garden Walk"), Description and care instructions, category type, and scheduled time.
4. **Given** the user saves a new activity, **When** the submission completes, **Then** the task appears under Today's Schedule or Upcoming section.

---

### User Story 6 - Health, Vitals & Clinical Observation Tracking (Priority: P2)

As a family member or caregiver, I want to record vital health signs (blood pressure, heart rate, body temperature, weight, mobility level, pain level, clinical notes) and view historical medical alerts so that my loved one's physical health is actively monitored.

**Why this priority**: Tracking objective physiological metrics enables early detection of health degradation or discomfort, providing peace of mind for distant family.

**Independent Test**: Can be verified independently by navigating to the Health & Vitals tab, filling out the "Record Health Vitals" form (e.g., BP 120/80, HR 72, Temp 98.6°F, Weight 150 lbs, Pain Level slider 0-10), saving the entry, and observing the updated medical summary.

**Acceptance Scenarios**:

1. **Given** the user is on Health & Vitals, **When** viewing the health dashboard, **Then** they see key medical conditions (Mild Dementia, Arthritis, Hypertension) and allergy warnings (⚠ Penicillin).
2. **Given** the user fills out the "Record Health Vitals" form, **When** they adjust numeric fields and the Pain Level rating (0 None to 10 Severe), and tap "Record Vital Signs", **Then** values are validated and persisted to the health log.
3. **Given** invalid or out-of-range vitals are entered, **When** submitted, **Then** clear inline validation prevents corrupt entries and guides corrective input.

---

### User Story 7 - Meal Tracker & Curated Food Nutrition Library (Priority: P2)

As a family member or caregiver, I want to log daily meals (Breakfast, Lunch, Dinner, Snack) using a comprehensive 35+ item Food Library or custom food entries, record expected vs. actual intake percentages, and view daily macronutrient targets so that nutritional intake is maintained.

**Why this priority**: Malnutrition and dehydration are critical risks for seniors with cognitive decline; tracking actual intake percentages and macronutrients prevents subtle decline.

**Independent Test**: Can be verified independently by opening the Meal Tracker, selecting a meal time (Breakfast 🌅, Lunch ☀️, Dinner 🌙, Snack 🍎), opening the Food Library, searching for items (e.g., "Oatmeal", "Vegetable Soup"), selecting portion sizes, setting actual intake percentage (e.g., 75%), and verifying today's nutrition targets update accordingly.

**Acceptance Scenarios**:

1. **Given** the user is logging a meal, **When** they select "Food Library", **Then** a searchable modal renders with 35+ pre-defined dietary items showing portion size and nutritional breakdown (calories, protein, carbs, fat).
2. **Given** the user needs to log a meal not found in the library, **When** they select "Custom Food", **Then** a dedicated entry form allows specifying custom food name, portion, calories, protein, carbs, and fat.
3. **Given** food items are selected, **When** setting expected intake (e.g. 100%) and actual intake (e.g., 75% ¾ eaten, or 50% half eaten) along with meal observations, **Then** the meal record calculates net consumed nutrition and updates Today's Nutrition progress bars (Calories, Protein, Carbs, Fat) against daily goals.
4. **Given** logged meals exist for the day, **When** viewing "Today's Meals", **Then** chronological meal cards show itemized dishes, intake percentages, macros, and caregiver notes.

---

### User Story 8 - Daily Mood Journal & Emotional Trend Logging (Priority: P2)

As a family member or caregiver, I want to record daily emotional states and behavioral observations so that our family circle can observe patterns, identify distress triggers, and celebrate calm days.

**Why this priority**: Emotional wellbeing directly correlates with cognitive stability in dementia care, helping families plan visits when loved ones are most receptive.

**Independent Test**: Can be verified independently by opening the Mood Journal tab, selecting "Log Current Mood", picking an emotional descriptor, adding optional observational context, and checking that the mood history updates.

**Acceptance Scenarios**:

1. **Given** the user is on the Mood Journal tab, **When** no entries have been logged yet today, **Then** a friendly empty state ("No mood entries yet") invites the user to log the first entry.
2. **Given** the user taps "Log Current Mood", **When** they select an emotional state (e.g., Happy, Calm, Anxious, Agitated, Tired) and add notes, **Then** the record saves with timestamp and logger attribution.
3. **Given** mood entries exist, **When** viewing the Mood Journal, **Then** a visual timeline summarizes emotional trends across the week.

---

### User Story 9 - Montessori Activity Guide & Engagement Facilitation (Priority: P3)

As a family member visiting my loved one, I want to explore a curated catalog of Montessori-inspired engagement activities tailored to Margaret's life history and hobbies (gardening, reading, fibre arts, painting, tea ritual), filtered by category, with step-by-step facilitation instructions so that our visits are purposeful and dignity-affirming.

**Why this priority**: Visiting families often struggle with how to engage loved ones living with dementia; practical Montessori activities replace awkward visits with shared, purposeful accomplishments.

**Independent Test**: Can be verified independently by navigating to the Activity Guide tab, browsing category filters (Practical Life, Cognitive, Creative, Sensory, Social), selecting an activity card (e.g., "Seed Sorting & Planting Tray"), reading "Why this matters for Margaret" and "How to do this activity", and following guided steps.

**Acceptance Scenarios**:

1. **Given** the user opens the Activity Guide, **When** viewing the screen, **Then** the Montessori core principle banner is displayed: *"Real work, done with real materials, for a real purpose... Their dignity comes from doing — not watching."*
2. **Given** the user views category filters, **When** inspecting available options, **Then** filter pills show item counts: Practical Life (3), Cognitive (1), Creative (1), Sensory (2), Social (2), Physical (0).
3. **Given** the user explores activities, **When** viewing individual cards, **Then** each card specifies duration (e.g., 20–30 minutes), category badge, description, and an expandable section detailing "Why this matters for Margaret" and "How to do this activity".
4. **Given** any activity is selected, **When** launching facilitation steps, **Then** actionable instructions emphasize preparing the environment, inviting without insisting, and stepping back.

---

### User Story 10 - Contextual "Ask Kubo AI" Family Assistant (Priority: P3)

As a family member navigating any section of the app, I want to access a contextual "Ask Kubo AI" assistant tailored to that specific screen (Family Portal, Memory Box, Care Tasks, Health & Vitals, Mood Journal, Activity Guide) so that I receive immediate, dementia-informed guidance and suggestions.

**Why this priority**: Real-time supportive guidance provides families with instant answers on dementia behaviors, communication tips, and visit ideas right when they need help.

**Independent Test**: Can be verified independently by tapping the "Ask Kubo AI" button from within any of the 6 tabs, confirming the greeting and contextual question prompt chips, submitting a query, and reviewing a compassionate, practical response.

**Acceptance Scenarios**:

1. **Given** the user is on any tab, **When** they tap the persistent floating or bottom "Ask Kubo North AI" trigger, **Then** the AI assistant modal opens with context tuned to that specific tab.
2. **Given** the assistant opens, **When** the user views suggested questions, **Then** relevant prompt chips are offered (e.g., "How can I stay connected with my loved one?", "What should I bring on visits?", "How do I handle it when they don't recognise me?", "Tips for caring for someone at home?").
3. **Given** the user taps a suggested chip or submits a typed query, **When** the assistant processes the request, **Then** a supportive, practical response is displayed with clear actionable suggestions.

---

### Edge Cases

- **Offline Operation**: If device connectivity is lost, all browsing (Portal, Stories, Memories, Care Tasks, Health Records, Activities) must remain fully accessible via local cache, and new offline entries (vitals, meals, tasks, memories) must queue locally for synchronization.
- **Empty / Incomplete Resident Profiles**: When switching to a newly created or empty resident profile without existing vitals, meals, or memories, screens must render encouraging empty states with direct primary CTAs rather than broken layouts or error alerts.
- **Multiple Dietary Items Logged Simultaneously**: When a user selects multiple items in the Food Library (e.g., Oatmeal + Earl Grey Tea + Banana), individual nutrients must accumulate correctly into total calories, protein, carbs, and fat before applying the actual intake multiplier.
- **Extreme Intake Percentages**: When a resident consumes 0% (refused meal) or over 100% (extra portions), calculations and UI progress meters must handle boundaries gracefully without visual overflow or negative numbers.
- **Large Memory Media Uploads**: When attaching image or video files, high-resolution media must be handled with appropriate client-side thumbnail downscaling and loading skeletons.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present the Demo Profile Selector as the default initial entry screen upon application launch, featuring one-tap family profile cards (Margaret's family, Robert's family, Dorothy's family) alongside an option to transition to the standard username/password login and account creation screen.
- **FR-002**: System MUST implement a primary navigation hierarchy providing seamless switching across the 6 core views: Family Portal, Memory Box, Mood Journal, Care Tasks, Health & Vitals, and Activity Guide.
- **FR-003**: System MUST display an active resident header on all main screens displaying resident name (Margaret Thompson), age (82), circle relationship (Sarah Thompson, Daughter, 555-0123), and an interactive "Switch" profile button.
- **FR-004**: System MUST provide the Family Portal dashboard summarizing daily wellbeing, recent mood status, quick actions, "Their Story" launch point, Montessori Guide entry, and recent memory preview cards.
- **FR-005**: System MUST provide a dedicated "Their Story" biographical narrative view detailing personal life portraits, educator career history, life milestones (1965 to 2018), and family memory reflections.
- **FR-006**: System MUST provide a Memory Box interface allowing users to view, filter, and create memories across 4 distinct formats: Photo, Story, Letter, and Video.
- **FR-007**: System MUST validate that all created memories include Title, format type, author attribution, date, and media asset; media input MUST support both local device file selection (with client-side downscaling and compression) and external URL pasting.
- **FR-008**: System MUST provide a Care Tasks management interface tracking daily routines with category tags (`physical`, `activity`, `social`), status badges (Start, Complete, Skip), completion progress (e.g., 2/3 completed), and a "Schedule New Activity" creation flow.
- **FR-009**: System MUST record vital signs via a structured entry form capturing Blood Pressure, Heart Rate, Temperature, Weight, Mobility Level, Pain Level (0–10 scale), and Clinical Notes.
- **FR-010**: System MUST maintain resident medical condition badges (Mild Dementia, Arthritis, Hypertension) and high-visibility allergy warnings (⚠ Penicillin) on health tracking screens.
- **FR-011**: System MUST provide a Meal Tracker with support for 4 meal categories (Breakfast 🌅, Lunch ☀️, Dinner 🌙, Snack 🍎), expected vs. actual intake percentage calculations, and observational notes.
- **FR-012**: System MUST include a searchable Food Library with 35+ pre-populated nutritional items containing portion size, calories, protein, carbs, and fat, as well as a Custom Food entry option.
- **FR-013**: System MUST provide an Activity Guide containing categorized Montessori engagement activities with category counts (Practical Life, Cognitive, Creative, Sensory, Social), estimated durations, "Why this matters", and step-by-step facilitation instructions.
- **FR-014**: System MUST support a hybrid AI assistant mode configured via build-time environment variable (e.g., `VITE_GEMINI_API_KEY`) that streams real-time responses via LLM when configured and connected, with instant fallback to curated Montessori care guidance and dementia support cards when the key is omitted or the device is offline.
- **FR-015**: System MUST display an active wellbeing alert banner on the Family Portal Home dashboard whenever actual meal intake drops below 50% or vital signs exceed safe clinical baseline thresholds, while retaining detailed warning badges in the Meal Tracker.
- **FR-016**: System MUST support visiting caregiver and nurse simulation within task completion and vital signs logging, allowing users to attribute actions to either family members or visiting care professionals (e.g., Nurse Jane, Tom Garcia) without requiring separate clinical portal authentication.
- **FR-017**: System MUST isolate and persist data independently per resident profile in local browser storage across profile switches, and MUST provide an accessible "Reset to Demo" capability to restore initial Figma fixture data.

---

### Key Entities

- **Resident (Loved One)**: The senior receiving care. Key attributes: resident ID, full name, age, profile photo, biography, philosophy quote, career history, hobbies, medical conditions, allergy alerts.
- **Care Circle / Family Member**: Authenticated user in the circle. Key attributes: user ID, full name, relationship to resident, phone number, permissions.
- **Memory Item**: A preserved life moment. Key attributes: memory ID, format (Photo, Story, Letter, Video), title, description/story text, media URL, date, shared-by name, tags array.
- **Care Task**: A scheduled routine or activity. Key attributes: task ID, title, description/care instructions, time, category (physical, activity, social, purposeful), status (pending, in-progress, completed, skipped), completed-by attribution.
- **Vital Signs Record**: A physiological log entry. Key attributes: timestamp, blood pressure, heart rate, temperature, weight, mobility level, pain rating (0-10), recorder name, clinical notes.
- **Meal Log Entry**: A nutrition record. Key attributes: meal ID, timestamp, meal type (breakfast, lunch, dinner, snack), logged items array, expected intake percentage, actual intake percentage, net calories, net protein, net carbs, net fat, observations, recorder name.
- **Food Library Item**: A nutritional reference unit. Key attributes: item name, standard portion, calories, protein grams, carbohydrate grams, fat grams, category.
- **Montessori Activity**: A structured engagement guideline. Key attributes: activity ID, title, category, duration range, description, why-it-matters explanation, step-by-step facilitation instructions.
- **Mood Entry**: A daily emotional record. Key attributes: timestamp, mood state, context notes, recorder name.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Family members can review their loved one's daily status, latest vitals, and today's completed routines within 5 seconds of opening the application.
- **SC-002**: A family member can create, tag, and publish a new photo or story memory to the Memory Box in under 45 seconds.
- **SC-003**: 100% of the screens, modals, and interaction states defined in Figma design `wMzyM9baD4XT5PLTu2sijV` (Login, Demo Profiles, Family Portal, Their Story, Montessori Guide, Memory Box, Add Memory, Mood Journal, Care Tasks, Add Task, Health & Vitals, Food Library, Custom Food, and Contextual Ask Kubo AI) are faithfully reproduced with exact visual fidelity, typography, and responsive layouts.
- **SC-004**: Logging a meal with multiple food items from the Food Library and calculating actual consumed calories/macros completes with fewer than 4 user taps after selecting food items.
- **SC-005**: All interactive elements maintain touch targets of at least 48x48 points and pass WCAG 2.1 AA accessibility contrast standards for elder and family readability.
- **SC-006**: 95% of first-time users can locate, open, and start a Montessori activity from the Activity Guide without instructional walkthroughs in under 30 seconds.

---

## Assumptions

- **Target Audience**: Family members, daughters/sons, and informal caregivers managing or monitoring care for an aging loved one living with mild dementia or age-related care needs.
- **Design Baseline**: The visual language, color tokens (soft calming greens, warm neutrals, high-contrast text), typography, spacing, and interaction patterns directly mirror Figma design file `wMzyM9baD4XT5PLTu2sijV` ("Kubo North (Family only)").
- **Form Factor**: Designed primarily for mobile screen viewports (standard ~390px to ~401px width as laid out in the Figma canvas frames), with responsive elasticity for tablets and desktop browsers.
- **Offline & Local Resilience**: The application is fully testable and functional offline using local browser storage/fixtures, enabling immediate testing and demoing without requiring a live cloud backend.
- **Care Circle Model**: Single resident focus per session with convenient profile switching between Margaret Thompson, Robert Chen, and Dorothy Williams demo fixtures.
