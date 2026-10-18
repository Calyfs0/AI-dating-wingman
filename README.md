# Gotchu

Stuck on a reply? Gotchu.

Late-night dating companion — turn chat tension into a sendable text.

## What’s in the app

Bottom tabs: **Reply** · **Openers** · **People** · **You**

| Tab | What it does |
| --- | --- |
| **Reply** | Chat screenshot or typed message → Natural / Playful replies |
| **Openers** | Profile screenshot → two first-message options |
| **People** | Light local list (your move / waiting / quiet) |
| **You** | Default vibe, casual + language prefs, privacy note |

Screenshots are processed in memory and never stored.

## Stack

- Flutter
- Supabase anonymous auth + Edge Functions
- OpenAI vision (`gpt-4o-mini`) via the Responses API (server-side only)

## Setup

See [docs/SETUP.md](docs/SETUP.md).

```bash
flutter pub get
flutter run
```

## Web (GitHub Pages)

Live at: https://calyfs0.github.io/AI-dating-wingman/

Pushes to `main` build Flutter web and deploy via `.github/workflows/deploy-pages.yml`.

Deploy the AI function (replies + openers):

```bash
npx supabase functions deploy generate-replies
```
