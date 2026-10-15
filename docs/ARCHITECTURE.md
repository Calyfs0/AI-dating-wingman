# Wingman Architecture

## Assessment (greenfield repo)

1. **Existing architecture** — empty README-only repository; Flutter app scaffolded as production foundation.
2. **Dependencies** — Flutter 3.35 / Dart 3.9, GoRouter, Provider, GetIt, Supabase, RevenueCat, image_picker, connectivity, secure storage.
3. **Screens** — full inventory implemented (onboarding → home → reply → people → practice → you → paywall + states).
4. **Design system** — `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppAnimations`, reusable Wingman components.
5. **Backend** — Supabase auth/data + `generate-replies` edge function for the core flow; mock AI for openers, practice, profile audit until wired.
6. **Core flow isolation** — `lib/features/screenshot_reply/` is the mockup-accurate reply UI; the shell navigates to it via `ScreenshotReplyScreen` without modifying those widgets.
7. **Refactor later** — RevenueCat purchases, OAuth linking, persist “save to person” from reply results into Supabase conversations.
8. **Created** — full shell (onboarding, home, people, practice, you), reply history, usage surfaces, quick-actions FAB.

## Pipeline

```
Screenshot → preprocess → OCR/vision → normalize → speakers → context
→ signals → strategy → generate → humanize → validate → UI
```

Structured conversation JSON is preferred over re-sending raw screenshots.

## Entitlements

RevenueCat is the source of truth. Flutter never hard-codes `isPro = true`. Usage checks are designed for server-side enforcement.
