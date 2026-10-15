# Wingman

Your private AI dating coach — know what to say, remember who you're talking to, and get better over time.

## Core flow (screenshot → reply)

The polished upload → generate → three-reply experience lives under `lib/features/screenshot_reply/`. The rest of the app routes into it from Home, People, and the quick-actions sheet without changing those screens.

1. Choose a chat screenshot (or type the message)
2. AI reads the conversation
3. Get three ready-to-send replies (Natural · Playful · Confident)
4. Copy the one you like

## Full app

- **Onboarding** — goals, style, privacy, notifications
- **Home** — quick actions, people preview, usage, coaching insight
- **People** — CRM-style context, date prep & debrief
- **Practice** — guided scenarios with feedback
- **You** — style, goals, subscription, privacy, recent replies
- **Plus** — openers, profile audit, paywall, offline & error states

## Stack

- Flutter · GoRouter · Provider · GetIt
- Supabase (auth, data, usage, edge functions)
- OpenAI via Edge Functions (server-side only)
- RevenueCat-ready subscription boundaries

## Setup

See [docs/SETUP.md](docs/SETUP.md).

```bash
flutter pub get
flutter run
```

Deploy AI functions:

```bash
npx supabase db push   # profiles, people, usage (first time)
npx supabase functions deploy generate-replies
```
