#!/usr/bin/env bash
# Auto-format and lint .nix files after edits
#
# This hook runs after Edit/Write tools on .nix files:
# 1. Formats with nixfmt
# 2. Checks for unused code with deadnix
# 3. Lints with statix

set -euo pipefail

file_path=$(jq -r '.tool_input.file_path')

if [[ "$file_path" == *.nix ]]; then
  nixfmt "$file_path" 2>/dev/null || true
  command -v deadnix &>/dev/null && deadnix "$file_path" 2>/dev/null || true
  command -v statix &>/dev/null && statix check "$file_path" 2>/dev/null || true
fi
