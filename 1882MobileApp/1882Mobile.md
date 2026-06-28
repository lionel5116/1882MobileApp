# 1882Mobile.md

Build prompt / engineering spec for **1882MobileApp** — a native SwiftUI companion app to the
HISD 1882 Cost Tracking web app. Use this file the same way `CLAUDE.md` is used for the
web repo: as the standing context for whoever (human or Claude Code) implements the app.

The Xcode project already exists (`1882MobileApp`, default SwiftUI template, single
`ContentView.swift`). This document is the spec for replacing that scaffold with the real app.

---

## 1. Source of Truth — Read This First

Two sources describe this backend and they **disagree**. Treat the live service as authoritative:

| | `CLAUDE.md` (web repo docs) | Live service (Postman + DB screenshot) |
|---|---|---|
| Port | `4000` | **`8090`** ✅ use this |
| DB engine | SQL Server (`mssql`) | **PostgreSQL** ✅ use this |
| Table | implied `time_entries` | confirmed `time_entries` (see DDL below) |

The backend is running in **Docker** at:

```
http://localhost:8090/api/
```

(In the iOS Simulator, `localhost` resolves to the Mac running Docker, so this works
unmodified. For a physical device, swap in the Mac's LAN IP — see §8.)

---

## 2. Confirmed Database Schema

From the live Postgres DDL (`1882CostTrackingDB`):

```sql
CREATE TABLE IF NOT EXISTS time_entries (
    id              SERIAL PRIMARY KEY,
    employee_name   VARCHAR(255)  NOT NULL,
    employee_id     VARCHAR(100)  NOT NULL,
    campus_name     VARCHAR(255)  NOT NULL,
    date_of_service DATE          NOT NULL,
    service_type    VARCHAR(20)   NOT NULL CHECK (service_type IN ('Direct', 'Indirect', 'On Demand')),
    service_desc    TEXT          NOT NULL,
    start_time      TIMESTAMPTZ   NOT NULL,
    end_time        TIMESTAMPTZ   NOT NULL,
    total_time      NUMERIC(10,2) NOT NULL,        -- server-calculated, hours
    total_cost      NUMERIC(10,2) NOT NULL,        -- server-calculated, USD
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_end_after_start CHECK (end_time > start_time),
    CONSTRAINT chk_min_time        CHECK (total_time >= 0.5)
);
```

**Business rule (mirrors the web app, do not re-derive differently):**
Minimum billable duration is 30 minutes. Anything under 30 minutes is rejected by the server
(400). Anything over 30 minutes that isn't an exact 30-minute multiple is rounded **up** to the
next 30-minute block. Rate is a flat **$50.00/hr**. `total_time` and `total_cost` are always
computed server-side — the app never sends or edits them directly.

---

## 3. Confirmed API Contract

Base URL: `http://localhost:8090/api`

### Verified endpoints (seen directly in the Express routes + Postman)

| Method | Path | Notes |
|---|---|---|
| `POST` | `/time-entries` | Create. Validates 30-min rule, calculates `total_time`/`total_cost`, inserts. |
| `GET` | `/time-entries` | All entries, newest first. |
| `GET` | `/dashboard-summary` | Aggregates for the dashboard (shape below). |

### Endpoints needed for full CRUD (not yet screenshotted — assume standard REST, confirm against the backend before relying on them)

| Method | Path | Notes |
|---|---|---|
| `GET` | `/time-entries/:id` | Single entry, for an edit/detail screen. |
| `PUT` | `/time-entries/:id` | Update. Same validation as create. |
| `DELETE` | `/time-entries/:id` | Delete. |

⚠️ Build the networking layer to isolate these three behind one `APIService` protocol so that if
the real paths differ (e.g. `PATCH` instead of `PUT`), only one file changes.

### `POST /time-entries` request body

```json
{
  "employee_name": "Jane Doe",
  "employee_id": "EMP-12345",
  "campus_name": "Reagan High School",
  "date_of_service": "2026-06-27",
  "service_type": "Direct",
  "service_desc": "Description of services provided",
  "start_time": "2026-06-27T14:00:00Z",
  "end_time": "2026-06-27T15:30:00Z"
}
```

`service_type` is a closed enum: `"Direct"`, `"Indirect"`, `"On Demand"` — use a Swift `enum`,
not a free-text field, and drive the picker from it.

### `GET /dashboard-summary` response (confirmed via Postman, real payload)

```json
{
  "totals": {
    "total_entries": "11",
    "total_hours": "19.50",
    "total_cost": "975.00"
  },
  "by_campus": [
    { "campus_name": "Westside High School", "entry_count": "2", "total_hours": "6.50", "total_cost": "325.00" },
    { "campus_name": "Bellaire High School",  "entry_count": "3", "total_hours": "4.50", "total_cost": "225.00" }
  ],
  "by_service_type": [
    { "service_type": "Direct",    "entry_count": "5", "total_hours": "11.00", "total_cost": "550.00" },
    { "service_type": "Indirect",  "entry_count": "4", "total_hours": "7.00",  "total_cost": "350.00" },
    { "service_type": "On Demand", "entry_count": "2", "total_hours": "1.50",  "total_cost": "75.00" }
  ],
  "recent_entries": [ /* last 10 time_entries rows, same shape as GET /time-entries */ ]
}
```

`by_service_type` and `recent_entries` are inferred from the dashboard UI (the web dashboard
shows both a service-type breakdown and a "Recent Time Entries" list, "Showing 10 of 11") — the
exact key names weren't visible in the Postman capture, so **verify these two keys against a
live response** before finalizing the Codable model; everything else above is captured verbatim.

### 🚨 Critical decoding gotcha

Postgres `NUMERIC` columns come back from `pg` as **strings**, and this API does not appear to
convert them — note `"total_hours": "19.50"` and `"total_cost": "975.00"` are quoted in the raw
JSON, not bare numbers. Likewise `entry_count` and `total_entries` are quoted integers.

Do **not** decode these as `Double`/`Int` directly — it will throw. Either:
- decode every numeric aggregate field as `String` and parse with `Double()`/`Int()` in the view
  model, or
- write a custom `init(from decoder:)` / `LossyNumber` wrapper that tries `Double` then falls
  back to `String → Double`, so the model survives if the backend is later fixed to emit real
  numbers.

`total_time` and `total_cost` on a raw time-entry row (from `POST`/`GET /time-entries`) should be
treated the same way until confirmed otherwise.

---

## 4. Tech Stack

- **SwiftUI**, no UIKit unless unavoidable.
- **Swift Concurrency** (`async/await`) for networking — no Combine, no third-party HTTP library.
  Plain `URLSession`.
- **MVVM**: one `ObservableObject` view model per screen, `@Published` state, views stay dumb.
- No persistence layer needed (no Core Data / SwiftData) — this is a thin client over the API.
  Pull-to-refresh and explicit refresh on save/delete is sufficient.
- Minimum deployment target: whatever the existing Xcode project is already set to — don't lower
  it. Use `NavigationStack` (not the legacy `NavigationView`).

---

## 5. App Structure (target)

```
1882MobileApp/
├── 1882MobileAppApp.swift
├── Models/
│   ├── TimeEntry.swift          # Codable struct matching time_entries
│   ├── ServiceType.swift        # enum: direct, indirect, onDemand
│   └── DashboardSummary.swift   # Codable struct matching /dashboard-summary
├── Services/
│   └── APIService.swift         # protocol + live implementation, async funcs for all 6 endpoints
├── ViewModels/
│   ├── DashboardViewModel.swift
│   └── TimeEntryFormViewModel.swift
├── Views/
│   ├── DashboardView.swift
│   ├── MetricCardView.swift          # reusable KPI tile
│   ├── CampusBreakdownView.swift     # "Hours & Cost by Campus" list + progress bars
│   ├── ServiceTypeBreakdownView.swift # "Breakdown by Service Type" colored-dot list
│   ├── RecentEntriesListView.swift
│   ├── TimeEntryFormView.swift        # create/edit form
│   └── RootTabView.swift              # TabView: Dashboard / Log Time Entry
└── Resources/
    └── HISDTheme.swift          # Color + Font constants (see §6)
```

---

## 6. Branding — HISD Visual Identity

Reference: the existing web app screens (navy header bar, white "HISD" wordmark next to a small
ascending bar-chart glyph, "1882 Cost Tracking" as a light-blue subtitle directly under it) and
the broader HISD brand language seen in other internal tools (same navy header, white card
surfaces on a pale gray-blue page background, colored accent bars/dots for categorization).

Reproduce as a native iOS layout, not a literal web port:

- **Navy** primary brand color for the nav/header surface — approx `#1B3A5C` (verify against
  `frontend/tailwind.config.js`'s `hisd.*` tokens in the web repo if you have access to it; treat
  the hex above as a placeholder, not gospel).
- **Light teal/cyan** accent for the logo glyph and the subtitle text on navy — approx `#5BC8D6`.
- **Page background**: very light gray-blue, approx `#EEF1F5`. **Cards**: white, subtle shadow or
  1px border, rounded corners (~12pt radius).
- **Primary action color** (buttons like "Save Time Entry", "+ Log Time Entry"): medium blue,
  approx `#1D5FBF`.
- **Metric card accent underlines**: each KPI tile has a thin colored bar under the number —
  blue / green / amber / red, one per card, purely decorative (matches the web dashboard's 4
  metric cards).
- **Service type indicator dots**: blue = Direct, purple = Indirect, amber/orange = On Demand.
  Keep these consistent everywhere the service type appears (form picker, breakdown list, recent
  entries list).
- **Typography**: bold, slightly tight headlines for big numbers (KPI values), regular weight for
  labels, uppercase tracked-out small caps for section headers ("TOTAL HOURS LOGGED",
  "HOURS & COST BY CAMPUS") — mirror the web app's all-caps section labels.
- Put all of this in `HISDTheme.swift` as `Color` and `Font` statics so nothing is hand-typed
  hex/size in the views.

---

## 7. Screens

### 7.1 Root navigation

`TabView` with two tabs, replacing the web app's top nav ("Dashboard" / "Log Time Entry"):
- Tab 1: **Dashboard** (`square.grid.2x2` or `chart.bar` icon)
- Tab 2: **Log Time Entry** (`plus.circle` icon)

Each tab's root view gets a navy `NavigationStack` toolbar background with the HISD wordmark,
mirroring the web header. A `+ Log Time Entry` button on the Dashboard screen should jump to the
second tab (or push the form modally) rather than duplicate the form.

### 7.2 Dashboard

Reproduce, top to bottom:

1. Header: "Time Tracking Dashboard" title + "Innovation & Development · 1882 Schools" subtitle
   (subtitle can be hardcoded or pulled from a config — it isn't in the API payload).
2. A 2×2 (on phone) grid of KPI cards, pulled from `totals`:
   - Total Hours Logged → `totals.total_hours`
   - Total Amount to Bill HISD → `totals.total_cost`, formatted as currency
   - Total Entries → `totals.total_entries`
   - Campuses Served → `count(distinct campus_name)` from `by_campus.count`
3. **Hours & Cost by Campus** card: one row per `by_campus` entry — campus name, dollar amount
   right-aligned, a horizontal progress bar sized relative to the highest campus total, and a
   caption line "`X.X hrs · N entries`" underneath. Sort descending by cost, matching the web app.
4. **Breakdown by Service Type** card: one row per `by_service_type` entry — colored dot +
   service type name on the left, "`X.X hrs · N entries`" caption underneath, dollar amount
   right-aligned.
5. **Recent Time Entries**: a scrollable list (`recent_entries`, capped at 10) showing employee
   name, campus, date, service type badge, and total cost per row. Tapping a row can open a
   read-only detail view (and, if you've wired up PUT/DELETE, edit/delete actions from there or
   via swipe).
6. Pull-to-refresh re-fetches `/dashboard-summary`.

### 7.3 Log Time Entry (create / edit form)

Reproduce the web form fields, in this order, as a single scrollable form (no need to preserve
the web app's 2-column grid on a phone-width screen — stack vertically):

1. **Employee Name** — text field, placeholder "Jane Doe", required.
2. **Employee ID** — text field, placeholder "EMP-12345", required.
3. **Campus Name** — text field, placeholder "Reagan High School", required. (Consider a picker
   backed by the distinct campus names already seen in `by_campus` as a convenience, but plain
   text entry is acceptable and matches the web app.)
4. **Date of Service** — date picker, required.
5. **Service Type** — segmented control or menu picker over the 3 enum values, required,
   defaults to no selection (placeholder "Select type...").
6. **Start Time** — date+time picker, required.
7. **End Time** — date+time picker, required.
8. **Service Description** — multi-line text editor, placeholder "Describe the services
   provided...", required.
9. A billing-rule info banner above the form fields, light-blue background, exact copy from the
   web app: *"Billing Rule: Time is recorded in 30-minute increments. Durations under 30 minutes
   are not allowed; durations are rounded up to the nearest 30-minute block. Rate: $50.00/hr"*
10. **Save Time Entry** (primary, navy/blue filled) and **Cancel** (secondary, outlined) buttons.

**Client-side validation** (mirror, don't replace, server validation):
- All fields required before Save is enabled.
- Compute `end_time - start_time`; disable Save and show an inline message if under 30 minutes.
- Show the live rounded duration / estimated cost as the user fills in start/end time, the same
  way the web form implies (optional nice-to-have, not in the screenshots, but consistent with
  the billing-rule banner being front and center).
- On submit, POST to `/time-entries`; on success, clear the form and navigate to/refresh the
  Dashboard tab; on a 400 (e.g. server-side 30-min rejection slipped past client validation),
  surface the server's error message rather than a generic failure.

For **editing** an existing entry (if you wire up the assumed `PUT /time-entries/:id`), reuse this
same view pre-populated, with the button label changed to "Update Time Entry".

---

## 8. Networking Notes (don't skip these)

- **App Transport Security**: iOS blocks plain `http://` by default. `localhost` in the
  Simulator is generally exempted automatically, but if you see ATS errors, add an
  `NSAppTransportSecurity` → `NSAllowsLocalNetworking: true` (or a scoped
  `NSExceptionDomains` entry for `localhost`) to `Info.plist`. Do **not** blanket-disable ATS
  (`NSAllowsArbitraryLoads: true`) for the whole app.
- **Simulator vs. device**: `http://localhost:8090` only resolves correctly inside the iOS
  Simulator (it shares the Mac's network namespace). Testing on a physical device requires
  replacing `localhost` with the Mac's LAN IP (e.g. `http://192.168.x.x:8090`) and adding that
  host to the ATS local-networking exception too. Make the base URL a single constant in
  `APIService.swift` so this is a one-line change.
- **Date formats**: send `date_of_service` as `yyyy-MM-dd` (no time component) and
  `start_time`/`end_time` as full ISO-8601 with timezone (`yyyy-MM-dd'T'HH:mm:ssXXXXX` or via
  `ISO8601DateFormatter`). Decode incoming timestamps the same way.
- **Error surface**: the backend returns 400s with validation messages (per `CLAUDE.md`'s
  description of the 30-minute rule) — decode a generic `{ "error": "..." }` (or whatever shape
  the real error body turns out to be; confirm with a deliberately-bad Postman request) and show
  it in an alert rather than swallowing it.

---

## 9. Out of Scope (for this pass)

- Authentication/login — none of the screenshots show an auth gate for this app (unlike the
  separate "IGC Case Management" tool, which does have a user badge in its header — that's a
  different product and only relevant here as a branding reference, not a feature to copy).
- Offline mode / local caching.
- Push notifications.

---

## 10. Definition of Done

- [ ] `TimeEntry`, `ServiceType`, `DashboardSummary` models compile and decode a real captured
      `/dashboard-summary` response without crashing on the stringified numerics.
- [ ] Dashboard tab renders all 4 KPI cards, campus breakdown, service-type breakdown, and recent
      entries from a live `GET /dashboard-summary` call against `http://localhost:8090/api`.
- [ ] Log Time Entry tab renders the full form, enforces the 30-minute client-side rule, and
      successfully `POST`s a new entry that then shows up after refreshing the Dashboard.
- [ ] Visual style (navy header, card layout, accent colors, billing-rule banner) reads as the
      same product family as the web app screenshots, adapted to native iOS conventions.
- [ ] Base URL and HTTP verb for each of the 6 endpoints lives in exactly one place
      (`APIService.swift`), so confirming/correcting the unverified PUT/DELETE/GET-by-id paths
      later is a one-file change.
