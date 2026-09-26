# Data Model: Kubo North Family Care App Rebuild

**Feature**: `003-rebuild-kubo-app`  
**Date**: 2026-09-26  
**Status**: Completed  

---

## 1. Domain Entities & Value Objects

### 1.1 Resident (`Resident`)
Represents the loved one receiving family care.
- `id` (String): Unique identifier (e.g. `res_margaret_thompson`).
- `name` (String): Full name (e.g. "Margaret Thompson").
- `age` (int): Age in years (e.g. 82).
- `avatarUrl` (String): Profile image URL or asset path.
- `biography` (String): Life story summary ("Elementary School Teacher (35 years), Burlington, Vermont...").
- `quote` (String): Guiding personal philosophy quote.
- `education` (String): Alma mater and degree ("B.Ed., University of Vermont, 1965").
- `interests` (List<String>): Hobbies (e.g. `["Gardening", "Reading", "Watercolour painting", "Birdwatching"]`).
- `milestones` (List<Milestone>): Chronological historical milestones.
- `conditions` (List<String>): Medical conditions (e.g. `["Mild Dementia", "Arthritis", "Hypertension"]`).
- `allergies` (List<String>): Medical allergies (e.g. `["⚠ Penicillin"]`).
- `contacts` (List<ContactPerson>): Family contacts (e.g. Sarah Thompson, Daughter, 555-0123).

### 1.2 Milestone (`Milestone`)
- `year` (int): Year of the milestone (e.g. 1965, 1998, 2000, 2018).
- `title` (String): Milestone heading (e.g. "Wedding Day 1965", "Received Vermont Educator Award").
- `description` (String): Contextual reflection.

### 1.3 User / Profile (`UserProfile`)
Represents an active member in the family circle or visiting caregiver.
- `id` (String): Unique user identifier.
- `username` (String): Login handle (e.g. `sarah.thompson`, `lisa.chen`, `james.williams`).
- `fullName` (String): Full name (e.g. "Sarah Thompson").
- `role` (UserRole): Enum (`familyMember`, `visitingCaregiver`).
- `relation` (String): Relation to resident (e.g. "Daughter", "Visiting Nurse").
- `phone` (String): Contact phone number.
- `linkedResidentId` (String): Identifier of primary managed resident.

### 1.4 Memory Item (`MemoryItem`)
Represents a memory stored in the Memory Box.
- `id` (String): Unique memory ID.
- `residentId` (String): Foreign key to Resident.
- `format` (MemoryFormat): Enum (`photo`, `story`, `letter`, `video`).
- `title` (String): Memory title (e.g. "Wedding Day 1965").
- `content` (String?): Description or text body.
- `mediaUrl` (String?): Web URL or local base64/cached media path.
- `date` (DateTime): Date of the memory event or publication.
- `sharedBy` (String): Author name (e.g. "Sarah Thompson").
- `tags` (List<String>): Searchable tags (e.g. `["#wedding", "#family", "#milestone"]`).

### 1.5 Care Task (`CareTask`)
Represents scheduled routines and purposeful activities.
- `id` (String): Unique task ID.
- `residentId` (String): Foreign key to Resident.
- `title` (String): Activity title (e.g. "Morning Garden Walk", "Folding Laundry").
- `description` (String): Care instructions and purpose notes.
- `time` (String): Scheduled time string (e.g. "09:00 AM", "02:00 PM").
- `category` (TaskCategory): Enum (`physical`, `activity`, `social`, `purposeful`).
- `status` (TaskStatus): Enum (`pending`, `inProgress`, `completed`, `skipped`).
- `completedBy` (String?): Sign-off actor attribution (e.g. "Nurse Jane", "Sarah Thompson").
- `completionNote` (String?): Post-activity note (e.g. "Enjoyed the sunshine, watered tomatoes").

### 1.6 Vital Sign Entry (`VitalSign`)
Represents physiological and observational records.
- `id` (String): Unique record ID.
- `residentId` (String): Foreign key to Resident.
- `timestamp` (DateTime): Timestamp of the measurement.
- `bloodPressure` (String): Formatted reading (e.g. "120/80").
- `systolic` (int): 120.
- `diastolic` (int): 80.
- `heartRate` (int): Beats per minute (e.g. 72).
- `temperature` (double): Fahrenheit (e.g. 98.6).
- `weight` (double): Pounds (e.g. 150.0).
- `mobilityLevel` (String): e.g. "Independent", "Assisted".
- `painLevel` (int): 0–10 scale.
- `recordedBy` (String): e.g. "Nurse Jane".
- `clinicalNotes` (String?): Observations or changes in condition.

### 1.7 Meal Log (`MealLog`)
Represents a meal intake record.
- `id` (String): Unique meal record ID.
- `residentId` (String): Foreign key to Resident.
- `timestamp` (DateTime): Meal time.
- `mealType` (MealType): Enum (`breakfast`, `lunch`, `dinner`, `snack`).
- `items` (List<LoggedFoodItem>): List of consumed food items with portion sizes.
- `expectedIntakePercent` (int): Target intake (e.g. 100%).
- `actualIntakePercent` (int): Consumed intake (e.g. 75%, 50%).
- `recordedBy` (String): Name of person who logged the meal (e.g. "Nurse Jane", "Tom Garcia").
- `observations` (String?): Notes (e.g. "Ate well, left a bit of the banana").
- Computed getters:
  - `totalCalories`: Summed item calories * (actualIntakePercent / 100.0).
  - `totalProtein`: Summed item protein * (actualIntakePercent / 100.0).
  - `totalCarbs`: Summed item carbs * (actualIntakePercent / 100.0).
  - `totalFat`: Summed item fat * (actualIntakePercent / 100.0).

### 1.8 Food Library Item (`FoodItem`)
Nutritional unit in the 35+ item reference library.
- `id` (String): Unique item ID.
- `name` (String): Food name (e.g. "Oatmeal", "Vegetable Soup", "Scrambled Eggs").
- `portion` (String): Standard serving (e.g. "1 cup", "2 eggs", "1 slice", "200 ml").
- `calories` (int): kcal per portion.
- `protein` (int): grams of protein.
- `carbs` (int): grams of carbohydrates.
- `fat` (int): grams of fat.
- `category` (String): e.g. "Grains", "Protein", "Dairy", "Beverages", "Soups".

### 1.9 Montessori Activity (`MontessoriActivity`)
Engagement activity in the Montessori care guide.
- `id` (String): Unique activity ID.
- `title` (String): e.g. "Seed Sorting & Planting Tray", "Watercolour from Observation".
- `category` (MontessoriCategory): Enum (`practicalLife`, `cognitive`, `creative`, `sensory`, `social`, `physical`).
- `duration` (String): e.g. "20–30 minutes", "15–20 minutes".
- `description` (String): Activity overview.
- `whyItMatters` (String): Personalized rationale tied to Margaret's life story.
- `howTo` (List<String>): Step-by-step facilitation instructions.

### 1.10 Daily Mood Entry (`MoodEntry`)
- `id` (String): Unique mood ID.
- `residentId` (String): Foreign key to Resident.
- `timestamp` (DateTime): Entry time.
- `moodState` (String): e.g. "Joyful", "Calm", "Reflective", "Anxious", "Fatigued".
- `note` (String?): Contextual observation.
- `recordedBy` (String): Logger identity.

---

## 2. Configuration & Runtime Model (`AppConfig`)

- `apiBaseUrl` (String): Microservice gateway endpoint.
- `authServiceUrl` (String): Authentication microservice endpoint.
- `careServiceUrl` (String): Care & resident microservice endpoint.
- `aiServiceUrl` (String): AI assistant backend endpoint.
- `geminiApiKey` (String): Optional build-time API key.
- `useMockData` (bool): Master toggle (defaults to `true`).
- `environment` (String): "dev", "staging", "prod".
