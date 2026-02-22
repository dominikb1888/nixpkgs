#!/usr/bin/env bash
# Stop hook: Capture last response and optionally offer TTS
#
# Always writes last_assistant_message to a temp file so /tts:say can use it.
# If auto-TTS is enabled for this session, blocks and offers audio for long responses.

set -euo pipefail

# Skip if we're inside a TTS subprocess (prevents recursive hook triggering)
if [[ "${TTS_SUBPROCESS:-}" == "1" ]]; then
  exit 0
fi

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
LAST_MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

# Use session-specific file to avoid conflicts between concurrent sessions
TTS_RESPONSE_FILE="${TMPDIR:-/tmp}/tts-response-${SESSION_ID}.txt"

# Always write last response to temp file so /tts:say can use it
if [[ -n "$LAST_MESSAGE" ]]; then
  echo "$LAST_MESSAGE" > "$TTS_RESPONSE_FILE"
else
  rm -f "$TTS_RESPONSE_FILE"
fi

# Check if auto-TTS is enabled for this session
TTS_ENABLED_FILE="${TMPDIR:-/tmp}/tts-enabled-${SESSION_ID}"
if [[ ! -f "$TTS_ENABLED_FILE" ]]; then
  exit 0
fi

# Only block first stop attempt
if [[ "$STOP_HOOK_ACTIVE" == "false" && -n "$LAST_MESSAGE" ]]; then
  # Only offer TTS for substantial responses (>500 chars)
  if [[ "${#LAST_MESSAGE}" -lt 500 ]]; then
    exit 0
  fi

  # Block and instruct Claude to run TTS
  cat << 'EOF'
{
  "decision": "block",
  "reason": "Run /tts:say to speak this response aloud."
}
EOF
  exit 0
fi

# Allow subsequent stops (after user accepted/denied audio)
exit 0
