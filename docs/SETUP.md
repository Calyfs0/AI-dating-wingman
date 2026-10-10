# Wingman setup — Screenshot → Reply

This build has one feature: upload a chat screenshot, get three reply options.

## 1. Supabase

1. Open your project (or create one) at [supabase.com](https://supabase.com).
2. **Settings → API**: copy **Project URL** and **anon public** key into
   [`lib/core/config/supabase_config.dart`](../lib/core/config/supabase_config.dart).
3. **Authentication → Providers → Anonymous**: enable anonymous sign-ins.

No database tables are required for this feature. Screenshots are not stored.

## 2. OpenAI secret (server only)

1. Create an API key at [platform.openai.com](https://platform.openai.com) (billing enabled).
2. Set it as an Edge Function secret — never in Flutter:

```bash
npx supabase secrets set OPENAI_API_KEY=sk-...
```

## 3. Deploy the Edge Function

```bash
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase functions deploy generate-replies
```

## 4. Run the app

```bash
flutter pub get
flutter run
```

Optional overrides:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Manual test

1. App opens on the upload screen (no login).
2. **Choose screenshot** → pick a real chat screenshot from Photos.
3. **Generate replies** → loading copy appears, then three reply cards.
4. **Copy** → “Copied” confirmation; paste elsewhere to verify.
5. **Try again** regenerates; **Change screenshot** returns to upload.
6. Unreadable / non-chat images show a friendly error (no fake replies).
