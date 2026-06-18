#!/usr/bin/env bash
# .claude/hooks/pre-tool-use.sh
# Bloqueia operações destrutivas antes de execução pelo Claude Code.
# Exit 0 = permitir | Exit 2 = bloquear (mensagem vai ao usuário)
set -euo pipefail

INPUT=$(cat)

TOOL=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', ''))
except Exception:
    print('')
" 2>/dev/null || true)

CMD=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null || true)

[ "$TOOL" != "Bash" ] && exit 0

# Padrões que requerem confirmação explícita do usuário
BLOCKED=(
  "eas submit"
  "supabase db reset"
  "git push --force"
  "git push -f "
  "git commit.*--no-verify"
  "git commit.*-n "
  "rm -rf /"
  "npx expo publish"
  "git rebase -i"
  "git reset --hard"
  "DROP TABLE"
  "truncate.*cascade"
)

for pattern in "${BLOCKED[@]}"; do
  if echo "$CMD" | grep -qiE "$pattern"; then
    echo "🚫 BLOQUEADO: '$pattern' requer confirmação explícita." >&2
    echo "   Execute manualmente no terminal se tiver certeza." >&2
    exit 2
  fi
done

exit 0
