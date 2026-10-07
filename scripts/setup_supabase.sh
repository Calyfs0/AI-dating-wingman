#!/usr/bin/env bash
# One-shot Wingman Supabase setup for project qrdmxegakpupereelpms
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_REF="qrdmxegakpupereelpms"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "Set OPENAI_API_KEY first, e.g.:"
  echo "  export OPENAI_API_KEY=sk-..."
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "Install Supabase CLI: brew install supabase"
  exit 1
fi

echo "==> Ensure you are logged into the account that owns project $PROJECT_REF"
echo "    Run: supabase login"
echo "    (browser will open — use the same account as the dashboard)"
read -r -p "Press Enter after supabase login succeeds..."

echo "==> Link project"
supabase link --project-ref "$PROJECT_REF"

echo "==> Push migrations"
supabase db push

echo "==> Set OpenAI secret"
supabase secrets set "OPENAI_API_KEY=$OPENAI_API_KEY" --project-ref "$PROJECT_REF"

echo "==> Deploy Edge Functions"
supabase functions deploy analyze-conversation --project-ref "$PROJECT_REF"
supabase functions deploy generate-response --project-ref "$PROJECT_REF"
supabase functions deploy delete-account --project-ref "$PROJECT_REF"

echo ""
echo "Manual (dashboard) if not already done:"
echo "  Auth → Providers → Anonymous → Enable"
echo "  https://supabase.com/dashboard/project/$PROJECT_REF/auth/providers"
echo ""
echo "Done. Run the app with: flutter run"
