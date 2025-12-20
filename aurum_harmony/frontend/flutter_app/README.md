# AurumHarmony Frontend (Flutter) – v1.0 Beta

This is a minimal Flutter client for the AurumHarmony v1.0 Beta backend.

## Prerequisites

- Flutter SDK installed (`flutter doctor` passes).
- AurumHarmony backend running locally:
  - `http://localhost:5000/health`
  - `http://localhost:5001/admin`

## Getting Started

From this directory:

```bash
flutter pub get
flutter run
```

The app shows:

- **Dashboard tab** – calls `/health` on the backend and displays status.
- **Admin tab** – calls `/admin/users` on the admin backend and lists users.

For production you will:

- Replace `kBackendBaseUrl` and `kAdminBaseUrl` in `lib/main.dart` with your
  static ngrok or cloud URLs.
- Add additional screens (Trade, Reports, Notifications) using the existing
  API endpoints as they are built out.


