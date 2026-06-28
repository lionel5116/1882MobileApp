# 1882Project.md

Developer notes for the **1882MobileApp** — a native SwiftUI iOS companion to the HISD 1882 Cost Tracking web app.

---

## What Was Built

A full SwiftUI app that mirrors the HISD 1882 Cost Tracking web interface (running at `localhost:3000`) as a native iOS experience. The app connects to the same Express/PostgreSQL backend (port `8090`) and provides two screens: a live dashboard and a time-entry form.

---

## File Structure Created

```
1882MobileApp/
├── Models/
│   ├── ServiceType.swift
│   ├── TimeEntry.swift
│   └── DashboardSummary.swift
├── Services/
│   └── APIService.swift
├── ViewModels/
│   ├── DashboardViewModel.swift
│   └── TimeEntryFormViewModel.swift
├── Views/
│   ├── RootTabView.swift
│   ├── DashboardView.swift
│   ├── MetricCardView.swift
│   ├── CampusBreakdownView.swift
│   ├── ServiceTypeBreakdownView.swift
│   ├── RecentEntriesListView.swift
│   └── TimeEntryFormView.swift
└── Resources/
    └── HISDTheme.swift
```

The original `ContentView.swift` was cleared (body replaced with a comment) and `_882MobileAppApp.swift` was updated to launch `RootTabView` instead.

Because the Xcode project uses `PBXFileSystemSynchronizedRootGroup`, every new `.swift` file dropped into the `1882MobileApp/` folder is automatically compiled — no changes to `project.pbxproj` were needed.

---

## Layer-by-Layer Explanation

### Models

**`ServiceType.swift`**
An enum with three cases matching the backend's closed set: `direct`, `indirect`, `onDemand` (raw values `"Direct"`, `"Indirect"`, `"On Demand"`). Each case carries its brand color so the dot/badge color is consistent everywhere the service type appears.

**`TimeEntry.swift`**
A `Codable` struct representing one row from the `time_entries` table. All snake_case API keys are mapped via `CodingKeys`. The fields `total_time` and `total_cost` are decoded as `String` rather than `Double` — this is intentional. PostgreSQL's `NUMERIC` type is returned as a quoted string by the `pg` library (e.g. `"19.50"` not `19.50`), so decoding as `Double` directly would throw. Convenience computed properties (`totalTimeDouble`, `totalCostDouble`) parse the string on demand and are forward-compatible if the backend is ever fixed to emit real numbers.

**`DashboardSummary.swift`**
A `Codable` struct matching the `/dashboard-summary` response shape, with three nested structs:
- `Totals` — `total_entries`, `total_hours`, `total_cost` (all string numerics)
- `CampusBreakdown` — one entry per distinct campus, sorted by cost descending
- `ServiceTypeBreakdown` — one entry per service type

Same string-numeric decoding pattern as `TimeEntry`. A computed `campusesServed` property returns `byCampus.count` (the count of distinct campus rows), and `maxCampusCost` returns the highest campus cost for scaling the progress bars.

---

### Services

**`APIService.swift`**
The entire network layer lives here. It defines:

1. `TimeEntryRequest` — the `Encodable` body sent on POST and PUT.
2. `APIError` — a simple `Error` struct that carries the server's error message string.
3. `APIServiceProtocol` — a Swift protocol declaring all six endpoint methods as `async throws`. Every screen depends on this protocol, not the concrete class, so swapping in a mock for testing or correcting a path is a one-file change.
4. `LiveAPIService` — the production implementation using `URLSession` with `async/await`. The base URL is a single `static let baseURL` constant — change it here (e.g. to a LAN IP for physical device testing) and everything updates.

All six endpoints are wired:
| Method | Path | Used for |
|---|---|---|
| `GET` | `/dashboard-summary` | Dashboard load / refresh |
| `GET` | `/time-entries` | (available, not directly called by UI yet) |
| `GET` | `/time-entries/:id` | Detail view (scaffolded) |
| `POST` | `/time-entries` | Create new entry |
| `PUT` | `/time-entries/:id` | Edit existing entry (scaffolded) |
| `DELETE` | `/time-entries/:id` | Delete from detail view |

Error responses are decoded as `{ "error": "..." }` and surfaced as `APIError` — the app shows the server's actual message in an alert rather than a generic failure.

**App Transport Security note:** `localhost` is automatically exempt from ATS in the iOS Simulator. For a physical device, go to the target's Info tab in Xcode and add `NSAppTransportSecurity → NSAllowsLocalNetworking = YES`.

---

### ViewModels

Both view models are `@MainActor ObservableObject` classes using `@Published` state and `async/await` for all API calls.

**`DashboardViewModel`**
Holds the `DashboardSummary?` state. `load()` fetches `/dashboard-summary` and sets `summary`. `deleteEntry(id:)` calls DELETE then re-calls `load()` so the dashboard reflects the deletion immediately. Errors are surfaced via `errorMessage: String?`.

**`TimeEntryFormViewModel`**
Holds all eight form field values as `@Published` properties. Key computed properties:
- `durationMinutes` — raw difference between end and start times in minutes
- `roundedHours` — rounds up to the nearest 30-minute block (`ceil(minutes / 30) * 0.5`)
- `estimatedCost` — `roundedHours * 50`
- `isValidDuration` — true when `durationMinutes >= 30`
- `canSave` — all fields non-empty AND `isValidDuration`

`save()` formats dates (ISO-8601 for timestamps, `yyyy-MM-dd` for date-only) and calls either POST or PUT depending on whether `entryId` is set (edit mode). On success it sets `didSave = true`, which the view watches to trigger cleanup and tab-switch.

---

### Views

**`HISDTheme.swift`** (in Resources/)
Single source of truth for all brand values:
- Navy `#1B3A5C` — navigation bar background
- Teal `#5BC8D6` — logo glyph, tab bar tint, accent text
- Page background `#EEF1F5` — behind all cards
- Primary blue `#1D5FBF` — buttons, links, active states
- KPI accent colors — blue, green, amber, red (one per metric card)
- Service type colors — blue (Direct), purple (Indirect), amber (On Demand)

Also defines:
- `HISDNavLogoView` — the bar-chart icon + "HISD" / "1882 Cost Tracking" wordmark shown in the nav bar
- `CardView` — a generic wrapper applying white background, 12pt rounded corners, and a subtle shadow
- `Color(hex:)` extension — initializes a `Color` from a hex string
- `Double.asCurrency` and `Double.asHours` — formatting helpers used throughout

**`RootTabView.swift`**
The app shell. A `TabView` with two tabs (Dashboard / Log Time Entry), each wrapped in a `NavigationStack`. The navy nav bar is applied uniformly via `.toolbarBackground` and `.toolbarColorScheme(.dark)`. The HISD wordmark and "Innovation & Development / TEC 328.0253" badge are injected as toolbar items.

Programmatic tab switching: `@State private var selectedTab = 0` is passed down so the Dashboard's "+ Log Time Entry" button can switch to tab 1, and the form's success callback can switch back to tab 0.

Auto-refresh after save: `@State private var dashboardRefreshID = UUID()`. When the form saves, this UUID is replaced with a new one. `DashboardView` uses `.task(id: refreshID) { await vm.load() }` which SwiftUI re-runs automatically whenever the id changes.

**`DashboardView.swift`**
Reproduces the web dashboard top-to-bottom:
1. Title and subtitle header (hardcoded text)
2. 2×2 `LazyVGrid` of `MetricCardView` tiles
3. `CampusBreakdownView` card
4. `ServiceTypeBreakdownView` card
5. `RecentEntriesListView` card

Pull-to-refresh is wired with `.refreshable { await vm.load() }`. A `ContentUnavailableView` with a Retry button is shown on initial-load failure. After data loads, a soft error (e.g. a failed refresh) shows as an alert overlay without clearing the existing data.

**`MetricCardView.swift`**
A reusable KPI tile. Takes a label string, a value string, a caption string, and an accent `Color`. Renders the value in a large bold rounded font, the label in uppercase small-cap tracking, and a thin colored capsule underline at the bottom — matching the web app's four metric cards.

**`CampusBreakdownView.swift`**
Renders one row per campus entry. Each row shows the campus name, right-aligned dollar amount, a `GeometryReader`-scaled progress bar (relative to `maxCampusCost`), and an `"X.X hrs · N entries"` caption. Progress bars use `HISDTheme.primaryBlue`.

**`ServiceTypeBreakdownView.swift`**
Renders one row per service type with a colored dot (matching the service type's brand color), name, hours/entries caption, and right-aligned cost.

**`RecentEntriesListView.swift`**
Shows the first 10 entries from `recentEntries`. Each row is a `NavigationLink` that pushes a `TimeEntryDetailView`. The row shows employee name, campus, date, a colored service-type badge, and the billed cost.

`TimeEntryDetailView` (defined in the same file) shows all fields in a `List` with sections. A destructive "Delete Entry" button triggers a `confirmationDialog`, then calls the async `onDelete` closure passed down from the Dashboard, then dismisses.

**`TimeEntryFormView.swift`**
A `ScrollView` containing:
1. **Billing rule banner** — light-blue info box with the exact copy from the web app
2. **Form card** — all eight fields stacked vertically inside a `CardView`, separated by dividers
3. **Duration preview pill** — appears when a valid duration is entered, shows `"X.X hrs billed · est. $XXX.XX"` in a teal capsule
4. **Inline error** — red warning shown between the End Time field and the Save button when duration is > 0 but < 30 minutes
5. **Save / Cancel buttons** — Save is disabled (grayed out) until `canSave` is true

The `TextEditor` for the description field has a manual placeholder overlay since SwiftUI's `TextEditor` doesn't support a native placeholder.

---

## Key Technical Decisions

**String-numeric decoding**
The single most important gotcha in this codebase. PostgreSQL `NUMERIC` columns are returned as quoted strings by the `pg` Node library. Decoding them as `Double` or `Int` directly causes a `DecodingError` at runtime. Every aggregate field (`total_hours`, `total_cost`, `entry_count`, etc.) is decoded as `String` and parsed via `Double()` / `Int()` in computed properties.

**Explicit `init` on views with `@StateObject`**
`DashboardView` and `TimeEntryFormView` both store a private `@StateObject` ViewModel and accept external closure parameters. Because the `@StateObject` backing storage is private, Swift's synthesized memberwise initializer is also private — making the view uncallable from outside. Explicit `init` methods using `_vm = StateObject(wrappedValue: ...)` are provided so the views can be initialized normally.

**`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**
The Xcode project has this build setting enabled, which makes all types implicitly `@MainActor` by default. This means `@Published` mutations and ViewModel methods are automatically on the main thread. `URLSession`'s `async/await` APIs are `nonisolated` — they run network I/O off the main thread and resume on the main actor, which is correct behavior.

**Dashboard auto-refresh via `UUID` + `.task(id:)`**
Rather than re-fetching on every tab switch (`.onAppear`) or requiring a manual pull-to-refresh, the root `TabView` holds a `dashboardRefreshID: UUID`. When the form saves successfully, the UUID is replaced, which triggers SwiftUI to cancel and re-run the `.task(id: refreshID)` attached to the Dashboard — giving automatic, targeted refresh without polling.

**Protocol-isolated networking**
All screens depend on `APIServiceProtocol`, not `LiveAPIService` directly. The three unverified endpoints (GET by id, PUT, DELETE) are scaffolded with standard REST paths. If the actual paths differ (e.g. `PATCH` instead of `PUT`), only `APIService.swift` needs to change.

---

## How to Run

1. Make sure the Docker backend is running on port `8090`.
2. Open `1882MobileApp.xcodeproj` in Xcode.
3. Select an iOS Simulator target and press Run (⌘R).
4. The app connects to `http://localhost:8090/api` — in the Simulator, `localhost` resolves to the Mac running Docker.

**Physical device:** Replace `localhost` with your Mac's LAN IP in the `baseURL` constant in `Services/APIService.swift`, and add `NSAppTransportSecurity → NSAllowsLocalNetworking = YES` in the target's Info tab.
