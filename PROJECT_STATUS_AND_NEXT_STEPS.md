# UNOclinic — Project Status & Next Steps

**Quezon Campus Clinic Management System** — Flutter desktop app. Current codebase is **UI-only** with in-memory mock data; no backend or Supabase yet.

---

## What’s finished (UI, shell, panels)

### Shell & layout
- **App shell** (`lib/shell/app_shell.dart`): Left sidebar + top bar + main content + optional right details drawer. Uses `IndexedStack` for navigation (no `go_router`).
- **Sidebar** (`lib/shell/sidebar.dart`): Collapsible (icon-only / expanded). Nav items: Dashboard, Patients, Visits, Health Certificates, Referrals, Inventory, Reports, Settings.
- **Topbar** (`lib/shell/topbar.dart`): App title, global search (UI only), sync status chip (Online / Syncing / Offline — mock toggle), user chip (e.g. “Admin”).

### Pages (all static UI + mock data)
- **Login** (`lib/pages/login_page.dart`): Username/password fields, “Forgot password” (no action). Any input + Login → navigates to `AppShell` (no real auth).
- **Dashboard** (`lib/pages/dashboard_page.dart`): KPI cards, quick actions, recent activity, alerts. Uses `Breakpoints` for responsive layout.
- **Patients** (`lib/pages/patients_page.dart`): Filters (type, department), search, table, “New Patient” → row click opens `PatientDrawer`.
- **Visits** (`lib/pages/visits_page.dart`): Table + `VisitDrawer` on row click.
- **Certificates** (`lib/pages/certificates_page.dart`): Table + `CertificateDrawer`.
- **Referrals** (`lib/pages/referrals_page.dart`): Table + `ReferralDrawer`.
- **Inventory** (`lib/pages/inventory_page.dart`): Table + inventory drawers.
- **Reports** (`lib/pages/reports_page.dart`): Reports UI.
- **Settings** (`lib/pages/settings/settings_page.dart`): Settings UI.

### Shared UI
- **Details drawer** (`lib/widgets/details_drawer.dart`): Right-side panel (~400px), optional tabs, close. Used by patient/visit/certificate/referral/inventory drawers.
- **App table** (`lib/widgets/app_table.dart`): Reusable data table.
- **Section card** (`lib/widgets/section_card.dart`), **KPI card** (`lib/widgets/kpi_card.dart`).
- **Theme** (`lib/theme/app_theme.dart`), **Breakpoints** (`lib/utils/breakpoints.dart`), **Formatters** (`lib/utils/formatters.dart`).

### Data
- **Mock only** (`lib/mock/mock_data.dart`): In-memory `MockPatient`, `MockVisit`, `MockCertificate`, `MockReferral`, `MockInventory*` with static lists. No persistence, no API.

---

## What to do next

### 1. Adding more static UI (new screens / panels)
- Add new **page** under `lib/pages/` (or a subfolder like `lib/pages/patients/`).
- In `lib/shell/app_shell.dart`: add a new `_NavItem` in `sidebar.dart` and a new case in `_buildActivePage()` that returns your page.
- If the page shows a list and detail: use `onOpenDrawer` with a drawer widget (reuse `DetailsDrawer` or follow `PatientDrawer` / `VisitDrawer` pattern).
- Use existing `SectionCard`, `AppTable`, `Breakpoints`, `AppTheme` for consistency.

### 2. Connecting to Supabase (realtime + database)
- **Add dependency**: In `pubspec.yaml`, add `supabase_flutter` (and run `flutter pub get`).
- **Init Supabase**: In `main.dart`, call `await Supabase.initialize(url: ..., anonKey: ...)` before `runApp(...)` (e.g. in `main()` with async).
- **Auth**: Replace `LoginPage` logic with `Supabase.auth.signInWithPassword()` (or OTP/SSO if needed). Use `Supabase.auth.onAuthStateChange` to switch between `LoginPage` and `AppShell`.
- **Database**:  
  - Define tables in Supabase (patients, visits, certificates, referrals, inventory, etc.) to mirror current mock models.  
  - Create a **service/repository layer** (e.g. `lib/services/` or `lib/repositories/`) that uses `Supabase.client.from('table').select()/insert()/update()/delete()` and maps rows to Dart classes (replace `MockPatient` etc. with real models).
- **Realtime**: Where needed, subscribe with `Supabase.client.from('table').stream(primaryKey: ['id'])` and feed streams into your UI (e.g. `StreamBuilder` or a state-management solution).
- **Sync status**: Wire the topbar sync chip to real state: e.g. “Online” when Supabase is connected, “Offline” when not, “Syncing” during push/pull if you add offline support later.
- **Remove or gate mock data**: Switch pages to use the new Supabase services instead of `mock_data.dart`; keep mocks only for tests or offline demos if desired.

### 3. Optional improvements
- **Routing**: Consider `go_router` for deep links and a clear URL structure (e.g. `/patients`, `/visits/:id`).
- **State management**: If the app grows, add a simple state solution (Provider, Riverpod, Bloc) so pages and drawers get data from a single source (e.g. Supabase streams).
- **Global search**: Implement the topbar search to query Supabase (e.g. patients by name/ID) and navigate to the right page/drawer.

---

## Quick reference

| Area           | Location / pattern |
|----------------|---------------------|
| Shell + nav    | `lib/shell/app_shell.dart`, `sidebar.dart` |
| New page       | `lib/pages/...`, register in `_buildActivePage()` and sidebar |
| Right drawer   | `DetailsDrawer`, `onOpenDrawer` from shell |
| Mock data      | `lib/mock/mock_data.dart` — replace with Supabase services |
| Theme / layout | `lib/theme/app_theme.dart`, `lib/utils/breakpoints.dart` |
| Supabase       | Not yet added — add package, init in `main.dart`, then auth + DB + optional realtime |
