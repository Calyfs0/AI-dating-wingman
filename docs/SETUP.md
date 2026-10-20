# Kehlo setup — Dating companion

Tabs: **Reply** · **Openers** · **People** · **You**

## 1. Supabase

1. Open your project (or create one) at [supabase.com](https://supabase.com).
2. **Settings → API**: copy **Project URL** and **anon public** key into
   [`lib/core/config/supabase_config.dart`](../lib/core/config/supabase_config.dart).
3. **Authentication → Providers · Anonymous**: enable anonymous sign-ins.

No database tables are required. Screenshots are not stored. People / You prefs use on-device SharedPreferences only.

## 2. OpenAI secret (server only)

1. Create an API key at [platform.openai.com](https://platform.openai.com) (billing enabled).
2. Set it as an Edge Function secret — never in Flutter:

```bash
npx supabase secrets set OPENAI_API_KEY=sk-...
```

## 3. Deploy the Edge Function

`generate-replies` handles both chat replies and profile openers (`mode: "openers"`).

```bash
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase functions deploy generate-replies
```

## 4. Run the app

```bash
flutter pub get
flutter run
```

## Manual test

1. App opens on **Reply** as **Kehlo** with bottom tabs.
2. **Reply**: screenshot or type message → two reply cards (Natural / Playful).
3. **Openers**: profile screenshot → two first-message cards.
4. **People**: add someone with status; long-press to remove.
5. **You**: vibe prefs + Kehlo Pro card.
