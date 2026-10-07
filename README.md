# Wingman

Premium private AI dating coach.

**Know what to say. Know what to do. Become better at dating.**

## Product

Wingman is not a pickup-line generator. It helps users understand conversations, choose a next move, generate responses in their own voice, remember people with consent, practice dating skills, and improve over time.

## Stack

- Flutter / Dart (null-safe)
- GoRouter navigation
- Provider + GetIt
- Supabase-ready auth/data boundaries
- RevenueCat-ready subscription boundaries
- Abstracted AI services (swap mock → edge functions)

## Architecture

```
UI → Controller → Repository → AI / Auth / Subscription services → Backend
```

Secrets never live in the Flutter client. Entitlements come from RevenueCat. Usage checks are designed for server-side enforcement.

## Run

```bash
flutter pub get
flutter run
```

Optional runtime config (public keys only):

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=REVENUECAT_API_KEY=...
```

## Privacy

- Anonymous-first auth (no login during onboarding)
- Screenshots treated as sensitive, temporary by default
- No automatic sending to dating apps or messengers
- Save-to-person requires explicit consent
- Delete-my-data flow included

## Navigation

Home · People · Practice · You, plus a central **+** quick-action sheet for Reply / Opener / Profile / Practice.
