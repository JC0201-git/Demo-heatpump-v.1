#!/bin/bash
# sdd-run.sh — Spec Kit × Claude Code 自動執行器

PROMPT_FILE="PROMPT.txt"
MODEL="claude-sonnet-4-5"

# 判斷是否為第一次執行（有無 .claude_session）
if [ ! -f ".claude_session" ]; then
  echo "▶ 首次執行..."
  cat "$PROMPT_FILE" | claude --print \
    --dangerously-skip-permissions \
    --model "$MODEL"
else
  echo "▶ 繼續執行（--continue）..."
  cat "$PROMPT_FILE" | claude --print \
    --dangerously-skip-permissions \
    --model "$MODEL" \
    --continue
fi

# 自動 commit
echo ""
echo "📝 產生 commit 訊息並提交..."
SUMMARY=$(cat "$PROMPT_FILE" | head -3)
git add -A
git commit -m "chore(sdd): $(date '+%Y-%m-%d %H:%M') — ${SUMMARY:0:60}"

echo "✅ 完成本輪執行"