# Concrete Architecture Plan: Flutter Expense Manager

## 1. Architecture Style & Reasoning
**Style**: Feature-First Clean Architecture combined with Riverpod-MVVM (Model-View-ViewModel).

**Reasoning**:
- **Feature-First**: Organizes code by features (e.g., `transactions`, `budget`) rather than layers (e.g., all `models`, all `views`). This ensures scalability without causing massive, unreadable folders as the app grows.
- **Clean Architecture (Pragmatic)**: UI never talks directly to the database. We separate concerns into Data (Sources/DB), Domain (Models/Repositories), and Presentation (UI/Controllers).
- **Beginner-Readable / No Overengineering**: We bypass redundant "UseCase" wrappers. The Riverpod Provider (ViewModel) communicates directly with the Repository interface. This reduces boilerplate while maintaining testability.
- **MVVM Integration**: Riverpod's `NotifierProvider` acts as the ViewModel, holding state and exposing methods to the UI (View).

---

## 2. FULL Folder Structure
```text
lib/
├── core/                                # Global infrastructure
│   ├── database/                        # SQLite/Hive configuration & initialization
│   ├── error/                           # Custom app exceptions
│   ├── router/                          # go_router configuration
│   └── theme/                           # Material 3 definitions
├── features/                            # Application modules
│   ├── auth/
│   │   ├── domain/                      # Models, Repository Interfaces
│   │   ├── data/                        # Local/Remote DataSources, Repository Impl
│   │   └── presentation/                # Screens, Widgets, Riverpod Providers
│   ├── dashboard/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── transactions/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── categories/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── reports/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── budget/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   └── settings/
│       ├── domain/
│       ├── data/
│       └── presentation/
└── main.dart                            # Composition root & app entry
```

---

## 3. Data Models
*Data is stored and passed locally via SQLite.*

- **User**: 
  - `id` (String)
  - `name` (String)
  - `email` (String)
  - `preferredCurrency` (String)
  - `createdAt` (DateTime)
- **Transaction**: 
  - `id` (String)
  - `amount` (double)
  - `date` (DateTime)
  - `note` (String)
  - `type` (Enum: income/expense/transfer)
  - `categoryId` (String)
  - `userId` (String)
- **Category**: 
  - `id` (String)
  - `name` (String)
  - `iconPath` (String)
  - `colorHex` (String)
  - `type` (Enum: income/expense)
- **Budget**: 
  - `id` (String)
  - `categoryId` (String)
  - `limitAmount` (double)
  - `startDate` (DateTime)
  - `endDate` (DateTime)
- **Settings**: 
  - `id` (String)
  - `themeMode` (Enum: system/light/dark)
  - `currencyCode` (String)
  - `isBiometricEnabled` (bool)

---

## 4. Feature Breakdown
- **Auth**: Handles PIN setup or simple local profile creation (since offline-first) and local Biometric Auth sequence.
- **Dashboard**: Displays a summarized view of the current month's expenses, recent transactions, and quick-add action buttons.
- **Transactions**: CRUD operations for income and expenses. Includes logic for filtering by date or category.
- **Categories**: CRUD operations for managing transaction categories. Limits users from deleting categories with active transactions.
- **Reports**: Generates visual representations (Pie charts, Bar graphs) of spending habits grouped by category and time spans (Weekly, Monthly, Yearly).
- **Budget**: Allows setting spending limits per category. Tracks current spending vs. budget limitations.
- **Settings**: Modifies app appearance, clears local data, exports data to CSV, and sets currency format.

---

## 5. Navigation Flow (go_router Paths)
- `/auth` (PIN / Local Login Screen)
- `/dashboard` (Main layout with Bottom Navigation Bar)
  - `/dashboard/transactions` (Transactions Tab)
  - `/dashboard/reports` (Reports Tab)
  - `/dashboard/budget` (Budget Tab)
  - `/dashboard/settings` (Settings Tab)
- `/transaction/add` (Modal or full screen for creating an expense)
- `/transaction/edit/:id` (Modal or full screen for editing)
- `/categories` (Managed within settings or as a sub-route from `/transaction/add`)

---

## 6. State Management Flow
**Component**: `riverpod` (`AsyncNotifierProvider` / `NotifierProvider`)
1. **App Initialization**: Provider observers wait for SQLite initialization.
2. **State Housing**: Each feature has a specific Controller (Notifier) holding the current state (e.g., `AsyncValue<List<Transaction>>`).
3. **Trigger Action**: User taps "Add Expense".
4. **Emit Loading**: The Controller sets state to `AsyncLoading`.
5. **Execute Logic**: The Controller calls `repository.addTransaction()`.
6. **Emit Success/Error**: Controller awaits response and updates state to `AsyncData` or `AsyncError`, automatically causing the UI to rebuild.

---

## 7. Data Flow
Strict unidirectional flow:
**UI** (e.g., `ElevatedButton(onPressed)`) 
  → calls **Provider** (e.g., `ref.read(transactionProvider.notifier).save()`) 
  → calls **Repository** (e.g., `transactionRepository.save(transactionEntity)`) 
  → calls **DataSource** (e.g., `localDataSource.insert()`) 
  → executes on **SQLite DB** (e.g., `sqflite.insert()`).

---

## 8. Dependencies List
**Core Logic & State:**
- `flutter_riverpod` (State management)
- `riverpod_annotation` & `riverpod_generator` (Code generation for providers)
- `go_router` (Navigation)

**Database & Storage:**
- `sqflite` (SQLite local database)
- `path_provider` (Directory paths for DB storage)
- `shared_preferences` (Simple key-value pairs for quick settings)

**UI & Assets:**
- `fl_chart` (Concrete implementation for Reports graphs)
- `intl` (Date, time, and currency formatting)
- `google_fonts` (Typography configuration for Material 3)

**Development & Clean Code:**
- `equatable` (Value equality for Data Models)
- `uuid` (Generating unique IDs locally)

**Testing (Built-in Flutter but notable):**
- `mockito` (Mocking for Repositories and DataSources)
