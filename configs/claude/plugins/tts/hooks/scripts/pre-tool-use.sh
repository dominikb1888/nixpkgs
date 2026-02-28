#!/usr/bin/env bash
# PreToolUse hook: Show confirmation dialog for TTS
#
# Intercepts calls to speak.sh and shows native Claude Code permission dialog.
# Handles cases where Claude might add extra arguments to the command.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

# Build the expected speak script path
SPEAK_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/say/scripts/speak.sh"

# Match if command starts with the speak script path (handles extra args Claude might add)
if [[ "$TOOL_NAME" == "Bash" ]] && [[ "$COMMAND" == "$SPEAK_SCRIPT"* ]]; then
  # Extract rate argument if present (third word after script path and session_id)
  RATE=$(echo "$COMMAND" | awk '{print $3}')

  # Build command with session_id and optional rate
  if [[ -n "$RATE" ]]; then
    NEW_CMD="$SPEAK_SCRIPT $SESSION_ID $RATE"
  else
    NEW_CMD="$SPEAK_SCRIPT $SESSION_ID"
  fi

  # Check if auto-TTS is enabled (marker file exists)
  TTS_ENABLED_FILE="${TMPDIR:-/tmp}/tts-enabled-${SESSION_ID}"
  if [[ -f "$TTS_ENABLED_FILE" ]]; then
    # Auto-invocation: show confirmation
    jq -n --arg cmd "$NEW_CMD" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: "Play audio summary of last response?",
        updatedInput: {
          command: $cmd
        }
      }
    }'
  else
    # Manual invocation: allow through without confirmation
    jq -n --arg cmd "$NEW_CMD" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        updatedInput: {
          command: $cmd
        }
      }
    }'
  fi
  exit 0
fi

# Pass through other Bash commands unchanged
exit 0
