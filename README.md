# UNOclinic - PSU Quezon Campus Clinic Management System

UNOclinic is a Flutter Desktop clinic management system built for PSU Quezon Campus.  
It helps organize clinic operations by connecting a finalized desktop UI to Supabase for
authentication, real-time records, and persistent health data.

## Core Modules

- Dashboard (KPIs, recent activity, alerts)
- Patients management
- Visits management
- Health certificates
- Referrals
- Inventory (items, batches, transactions, alerts)
- Reports (with CSV/PDF export)
- Settings (user management, audit logs, clinic info)

## Tech Stack

- Flutter Desktop (Windows-first)
- Supabase (Auth + Postgres)
- Clean flow: UI -> Repository -> Supabase

## Current Status

- Frontend layout is finalized and responsive up to tablet size
- Modules are connected to real Supabase data
- Audit logging and report export are implemented

## Run Locally

```bash
flutter pub get
flutter run -d windows
```
