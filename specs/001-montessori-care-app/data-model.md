# Data Model

## Core Entities

### User (Zitadel Identity)
- `id` (String): Unique identifier provided by Zitadel
- `email` (String): User's email
- `role` (Enum): `Admin` or `Caregiver`
- `name` (String): Display name

### Resident
- `id` (String): Unique identifier
- `firstName` (String): Resident's first name
- `lastName` (String): Resident's last name
- `dateOfBirth` (DateTime): Resident's DOB
- `roomNumber` (String): Room assignment
- `carePlan` (String): Markdown/Text describing specific Montessori care needs
- `assignedCaregivers` (List<String>): List of User IDs assigned to this resident

### CareLog (Activity)
- `id` (String): Unique identifier
- `residentId` (String): Reference to Resident
- `caregiverId` (String): Reference to User who created the log
- `timestamp` (DateTime): When the activity occurred
- `activityType` (Enum): Type of meaningful work (e.g., `PracticalLife`, `Sensorial`, `Cognitive`, `Social`)
- `notes` (String): Details of the engagement
- `syncStatus` (Enum): `Pending`, `Synced`, `Failed` (For offline-first management)

## Offline-First Synchronization Strategy
- **Isar Database**: Stores `Resident` and `CareLog` data locally.
- **Background Sync**: A dedicated service periodically checks for `CareLog` records with `syncStatus == Pending` and attempts to push them to the backend API when connectivity is restored.
- **Conflict Resolution**: Last-write-wins based on `timestamp`, but practically, CareLogs are append-only so conflicts are rare.
