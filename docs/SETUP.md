# Wingman setup

## 1. Supabase project

1. Create or open a project at [supabase.com](https://supabase.com).
2. Copy **Project URL** and **anon public** key into
   [`lib/core/config/supabase_config.dart`](../lib/core/config/supabase_config.dart)
   (or pass `--dart-define=SUPABASE_URL=...` and `SUPABASE_ANON_KEY=...`).
3. **Authentication → Providers → Anonymous**: enable anonymous sign-ins.
4. Apply the app schema (profiles, people, conversations, usage):

```bash
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```

## 2. OpenAI (server only)

1. Create an API key at [platform.openai.com](https://platform.openai.com).
2. Set it as an Edge Function secret — never in Flutter:

```bash
npx supabase secrets set OPENAI_API_KEY=sk-...
```

## 3. Deploy Edge Functions

```bash
npx supabase functions deploy generate-replies
# Optional (legacy / extended flows):
npx supabase functions deploy analyze-conversation generate-response
```

## 4. Run the app

```bash
flutter pub get
flutter run
```

Without Supabase keys, the app boots in **local/mock mode** (demo people, mock AI for secondary flows). Screenshot replies still need Supabase + `generate-replies` for production.

## Manual test — core reply flow

1. Complete onboarding (or skip through) → land on **Home**.
2. Tap **Reply** or the center **+** quick action → **Reply**.
3. Upload a chat screenshot → **Generate replies** → three cards → **Copy**.
4. Back to Home → **Recent replies** shows the session on this device.

## Manual test — shell

1. **People** — open a person → **Date prep** / **Debrief**.
2. **Practice** — start a topic → submit → feedback.
3. **You** — style, privacy, subscription screens load without errors.
