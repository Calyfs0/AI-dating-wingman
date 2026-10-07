# Wingman setup (Supabase + OpenAI)

Real Reply (paste) flow needs a Supabase project and an OpenAI API key. Secrets never go in the Flutter client.

## 1. Supabase project

1. Create a project at [supabase.com](https://supabase.com).
2. **Settings → API**: copy **Project URL** and **anon public** key.
3. **Authentication → Providers → Anonymous**: enable anonymous sign-ins.
4. **SQL Editor**: run, in order:
   - [`supabase/migrations/001_wingman_foundation.sql`](../supabase/migrations/001_wingman_foundation.sql)
   - [`supabase/migrations/002_auth_helpers.sql`](../supabase/migrations/002_auth_helpers.sql)

Or with CLI:

```bash
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```

## 2. OpenAI

1. Create an API key at [platform.openai.com](https://platform.openai.com) (billing enabled).
2. In Supabase: **Project Settings → Edge Functions → Secrets**:

```bash
npx supabase secrets set OPENAI_API_KEY=sk-...
```

`SUPABASE_SERVICE_ROLE_KEY` is available automatically to Edge Functions; do not put it in Flutter.

## 3. Deploy Edge Functions

```bash
npx supabase functions deploy analyze-conversation
npx supabase functions deploy generate-response
npx supabase functions deploy delete-account
```

## 4. Run the Flutter app

Keys live in [`lib/core/config/supabase_config.dart`](../lib/core/config/supabase_config.dart). Then:

```bash
flutter pub get
flutter run
```

Optional override without editing the file:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Manual test checklist (paste Reply slice)

1. Cold start → anonymous session → row in `profiles`.
2. Complete onboarding → fields persist on `profiles` after restart.
3. Home → Reply → paste a real chat (no images) → Analyze.
4. Analysis metrics/strategy reflect that paste (not Emma demo copy).
5. Next move → pick tone → replies match the conversation.
6. Humanize / regenerate change the text.
7. Save → creates/updates a person; People tab shows them after restart.
8. After 3 free analyses (non-Pro), 4th analysis is blocked with usage message.
9. You → Delete my data → profile/people/conversations cleared; app returns to splash.

## Screenshots

`analyze-conversation` accepts screenshot images (base64 data URLs) and uses **gpt-4o-mini** vision. Paste text remains an optional fallback.
