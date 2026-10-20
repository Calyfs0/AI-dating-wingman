# Kehlo Architecture

## Assessment (greenfield repo)

1. **Existing architecture** — empty README-only repository; Flutter app scaffolded as production foundation.
2. **Dependencies** — Flutter 3.35 / Dart 3.9, GoRouter, Provider, GetIt, Supabase, RevenueCat, image_picker, connectivity, secure storage.
3. **Screens** — full inventory implemented (onboarding → home → reply → people → practice → you → paywall + states).
4. **Design system** — `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppAnimations`, reusable Wingman components.
5. **Backend** — Supabase-ready auth/data boundaries + SQL/RLS foundation; mock AI services stand in for edge functions.
6. **Reuse** — N/A (greenfield).
7. **Refactor later** — swap mock AI for edge functions; wire real RevenueCat purchases; complete OAuth linking.
8. **Created** — domain entities, repositories, services, DI, routing, component library, all primary flows.

## Pipeline

```
Screenshot → preprocess → OCR/vision → normalize → speakers → context
→ signals → strategy → generate → humanize → validate → UI
```

Structured conversation JSON is preferred over re-sending raw screenshots.

## Entitlements

RevenueCat is the source of truth. Flutter never hard-codes `isPro = true`. Usage checks are designed for server-side enforcement.
