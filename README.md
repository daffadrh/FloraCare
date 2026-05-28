# FloraCare 🌿

FloraCare is a mobile application designed to help users track and care for their plants, aligned with UN Sustainable Development Goals (SDG 11, 12, 13, and 15).

---

## 🚀 Getting Started 

When you pull this repository for the first time, you must run the following commands to install dependencies and run the application.

### 1. Install Dependencies
Retrieve all necessary package dependencies (Firebase, Provider, etc.) specified in the project:
```bash
flutter pub get
```

### 2. Run the Application
Start the application on your connected device or emulator:
```bash
flutter run
```

---

## 📁 Project Structure & Feature Division

To avoid Git merge conflicts, we use a **feature-first folder structure**. Each team member's code is isolated within their respective feature folder:

```
lib/
├── core/
│   ├── constants/       # Theme colors, dimensions, and typography styles
│   ├── navigation/      # Bottom Navigation Bar (app shell structure)
│   └── theme/           # Light and Dark Material 3 theme configurations
└── features/
    ├── home/            # Welcome Dashboard & ECO-Tips (Shared)
    ├── auth/            # Firebase Authentication (Shared)
    ├── inventory/       # Feature 1: Plant Inventory CRUD (Member 1)
    ├── schedule/        # Feature 2: Care Schedule & Tasks (Member 2 - Placeholder)
    └── journal/         # Feature 3: Health Journal & APIs (Member 3 - Placeholder)
```

### 👥 Member Assignments & Ownership
*   **Plant Inventory**: Work inside `lib/features/inventory/`. Implements plant lists, details, and creation forms.
*   **Care Schedule**: Work inside `lib/features/schedule/`. Implements watering calendars and daily reminder triggers.
*   **Health Journal**: Work inside `lib/features/journal/`. Implements image-based diagnosis scanning (Plant.id API) and environmental integrations (OpenWeather API).

---

## 🔑 Firebase Configuration

*   **Firebase Options**: The Firebase configuration is contained in `lib/firebase_options.dart`. This is already tracked and committed, meaning the application will connect to the group's Firebase Auth and Cloud Firestore project right out of the box when you run the app.
*   **Offline Mock Mode**: If Firebase initialization fails (e.g. while running offline), the app automatically shifts to an offline mock database. You will still be able to create, read, update, and delete plants locally in-memory without crashes.