# Qest — قِسط

**Arabic-first installment, subscription and bill manager for Flutter.**
Calm by design. Smart by behaviour. Offline-first.

> Qest is *not* a finance/accounting app. It is a quiet helper that nudges
> you only when it matters, learns when you say "later", and keeps your
> receipts filed for you.

---

## Highlights

- ⚡ **Add a payment in under 15 seconds** — title, amount, due date, recurring, payment app, notes.
- 🔔 **Smart notifications** — 3 days before due, 2–3 reminders/day, *only* between 10 AM and 10 PM. Due-day high-priority with action buttons (Paid · Not yet · Open app). "Not yet → no money" snoozes for 2 days.
- 🧾 **Receipt system** — image / PDF, with on-device OCR (Google ML Kit) extracting amount, date and merchant.
- 🚀 **Payment-app launcher** — valU, Fawry, InstaPay, Vodafone Cash, CIB or any custom deeplink.
- 🗓 **Calendar sync** — adds an event with reminders to the device calendar (Google on Android, Apple on iOS).
- 🏠 **Home-screen widget** — next payment + overdue/today counters.
- 🔒 **Biometric lock**, 🌗 **dark/light mode**, 🌍 **Arabic RTL + English**, 💾 **JSON backup / restore**.

---

## Requirements

- Flutter `>=3.22.0` (Dart `>=3.4.0`)
- Android SDK 23+, iOS 13+
- Java 17 toolchain for the Android build

---

## Quick start

```bash
flutter pub get

# Generate Isar collection schemas:
dart run build_runner build --delete-conflicting-outputs

# Provide font files (Cairo Regular/Medium/Bold) under assets/fonts/.
# Then:
flutter run
```

If you don't have the Cairo fonts handy, drop the `fonts:` block from
`pubspec.yaml` — `google_fonts` will fetch Cairo at runtime from the
network instead.

---

## Architecture

Clean architecture with strict layering, scoped per feature.

```
lib/
├── app/                       # Entry, providers, router, action wiring
├── core/
│   ├── constants/             # AppConstants
│   ├── theme/                 # Material 3 theme, Cairo typography
│   ├── extensions/            # Date helpers
│   ├── utils/                 # quiet hours, money formatting
│   └── services/              # Singletons: Isar, notifications, OCR,
│                              # calendar, launcher, biometric, backup,
│                              # home-widget
├── features/
│   ├── installments/          # data / domain / presentation
│   ├── receipts/              # data / domain / presentation
│   ├── dashboard/
│   ├── onboarding/
│   ├── search/
│   └── settings/
└── l10n/                      # ARB files (en, ar)
```

State management is **Riverpod**. Local persistence is **Isar**. Routing
is **go_router**. Background work is **workmanager** (periodic 6-hour
refresh of the notification ladder). Local notifications are
**flutter_local_notifications** with timezone-aware scheduling.

### Notification engine

`NotificationService.scheduleForInstallment(installment)`:

1. Cancels every previously-scheduled notification for the UUID.
2. Builds a 3-day pre-due ladder: 3 reminders/day, distributed evenly
   across the active window (10:00–22:00) via `spreadReminderSlots`.
3. Adds a single **high-priority** notification on the due day at 10:00,
   carrying three action buttons (`PAID`, `NOT_YET`, `OPEN_APP`).
4. Skips any slot earlier than `installment.snoozedUntil`.
5. Honours `installment.isPaid` (no scheduling).

`NotificationActionHandler` (in `lib/app/`) listens to the plugin's
event stream and applies the per-action behaviour.

### Background work

`BackgroundScheduler.init()` registers a Workmanager periodic task every
6 hours. The dispatcher re-opens Isar inside the background isolate,
re-derives the notification ladder for every unpaid installment, and
pushes a fresh summary to the home-screen widget.

---

## Tests

```bash
flutter test
```

Covers: quiet-hours math, installment domain logic (overdue / days
until / recurring rollover), notification payload encoding, OCR
extraction heuristics.

---

## Project status

This repository is the production-ready foundation: full Clean
Architecture, real notification engine, real OCR, real background
tasks, real local persistence, real RTL Arabic. After `flutter pub get`
and `dart run build_runner build`, it builds for Android. iOS and the
home-widget native side need the platform-specific scaffolding any
Flutter app does (run `flutter create . --platforms=ios` once to lay
down the Xcode project, then re-add the entitlements documented above).
