#!/bin/bash
# agent-skills session start hook
# Injects the using-agent-skills meta-skill into every new session

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"
META_SKILL="$SKILLS_DIR/using-agent-skills/SKILL.md"

PREFIX="agent-skills loaded. Use the skill discovery flowchart to find the right skill for your task."

if [ ! -f "$META_SKILL" ]; then
  echo '{"priority": "INFO", "message": "agent-skills: using-agent-skills meta-skill not found. Skills may still be available individually."}'
  exit 0
fi

CONTENT=$(cat "$META_SKILL")

if command -v jq >/dev/null 2>&1; then
  # Use jq to properly escape and construct valid JSON
  jq -cn \
    --arg message "$PREFIX

$CONTENT" \
    '{priority: "IMPORTANT", message: $message}'
elif command -v python3 >/dev/null 2>&1; then
  # Fallback: python3 json.dumps produces the same properly escaped JSON
  MESSAGE="$PREFIX

$CONTENT" python3 -c 'import json, os; print(json.dumps({"priority": "IMPORTANT", "message": os.environ["MESSAGE"]}))'
else
  echo '{"priority": "INFO", "message": "agent-skills: jq (or python3) is required for the session-start hook but was not found on PATH. Install jq (e.g. `brew install jq` or `apt-get install jq`) to enable meta-skill injection. Skills remain available individually."}'
fi
