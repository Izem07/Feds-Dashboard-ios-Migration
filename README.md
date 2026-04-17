# Scout-Ops Dashboard
### FRC Team 201 – The Feds

A Flutter-based scouting dashboard that aggregates match data from **Neon**, **The Blue Alliance**, and **Statbotics** into a single comparison view for any FRC competition event.

---

## What It Does

- Pulls scouting rows from a **Neon PostgreSQL** database (serverless SQL-over-HTTP)
- Fetches **OPR** (Offensive Power Rating) from TBA
- Fetches **EPA** (Expected Points Added) from Statbotics
- Displays side-by-side team comparisons with auto path visualization
- Caches data locally so the app loads instantly on repeat visits

---

## Project Structure

```
dash/               # Flutter app
├── lib/
│   ├── main.dart
│   ├── theme.dart
│   ├── models/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── assets/
└── web/
ios/                # iOS platform files
.github/workflows/  # iOS IPA build workflow
```

---

## Prerequisites

- Flutter SDK ≥ 3.2
- A Neon PostgreSQL database with your scouting table
- A TBA API key from https://www.thebluealliance.com/account

---

## Running Locally

```bash
cd dash
flutter pub get
flutter run -d chrome
```

---

## iOS Build

The GitHub Actions workflow (`.github/workflows/dart.yml`) builds an unsigned IPA and publishes it as a release on this repo.

To trigger it:
1. Go to the **Actions** tab on GitHub
2. Select **iOS-ipa-build**
3. Click **Run workflow**

> The `ios/` folder lives at the repo root and is symlinked into `dash/` during the build step.

---

## Neon Connection

Flutter web can't open raw TCP sockets, so this app uses Neon's serverless SQL-over-HTTP endpoint. On the entry screen, paste a standard Postgres URI:

```
postgresql://user:password@ep-xxx-123.us-east-2.aws.neon.tech/mydb?sslmode=require
```

---

## Data Sources

| Source | Data | Auth |
|---|---|---|
| Neon | Scouting rows (one per match) | PostgreSQL connection string |
| TBA | OPR per team | `X-TBA-Auth-Key` header |
| Statbotics | EPA per team | None (public API) |

---

## License

Internal tool — FRC Team 201.
