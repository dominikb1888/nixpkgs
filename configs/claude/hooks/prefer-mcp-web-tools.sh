#!/usr/bin/env bash
# Block WebSearch/WebFetch and redirect to the search-tips skill.
#
# PreToolUse hook — prevents the tool call from executing and tells Claude
# to load the search-tips skill for guidance on using Exa/Firecrawl instead.

set -euo pipefail

tool_name=$(jq -r '.tool_name')

if [[ "$tool_name" == "WebSearch" || "$tool_name" == "WebFetch" ]]; then
  cat << 'EOF'
{
  "decision": "block",
  "reason": "WebSearch and WebFetch are disabled. Use the search-tips skill (`/search-tips`) for guidance on using Exa and Firecrawl instead."
}
EOF
fi

exit 0
