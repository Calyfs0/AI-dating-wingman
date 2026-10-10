# Wingman

Your next reply, figured out.

## First feature

**Screenshot → Reply**

1. Choose a chat screenshot  
2. AI reads the conversation  
3. Get three ready-to-send replies (Natural · Playful · Confident)  
4. Copy the one you like  

## Stack

- Flutter
- Supabase anonymous auth + Edge Functions
- OpenAI vision (`gpt-4o-mini`) via the Responses API (server-side only)

## Setup

See [docs/SETUP.md](docs/SETUP.md).

Public keys: [`lib/core/config/supabase_config.dart`](lib/core/config/supabase_config.dart).

```bash
flutter pub get
flutter run
```

Deploy the AI function:

```bash
npx supabase functions deploy generate-replies
```
