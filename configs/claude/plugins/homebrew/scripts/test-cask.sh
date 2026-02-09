#!/usr/bin/env bash
# Run Homebrew cask validation checks (audit, style, livecheck)
#
# Usage: test-cask.sh <cask-name> [--skip-livecheck]
#
# Runs all checks and reports results. Does NOT stop on first failure -
# runs all checks so you can see all issues at once.
#
# Output format (structured for parsing):
#   === AUDIT ===
#   status: pass|fail
#   output: ...
#
#   === STYLE ===
#   status: pass|fail
#   output: ...
#
#   === LIVECHECK ===
#   status: pass|fail|skipped
#   output: ...
#
#   === SUMMARY ===
#   result: pass|fail
#   failed: audit,style  (comma-separated list of failed checks, or "none")
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed
#   2 - Invalid arguments

set -uo pipefail  # Note: not -e, we want to continue on failures

usage() {
  echo "Usage: test-cask.sh <cask-name> [--skip-livecheck]" >&2
  exit 2
}

[[ $# -lt 1 || $# -gt 2 ]] && usage

cask="$1"
skip_livecheck=false
[[ "${2:-}" == "--skip-livecheck" ]] && skip_livecheck=true

# Environment for local cask testing
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_FROM_API=1

failed_checks=()

run_check() {
  local name="$1"
  shift
  local cmd=("$@")

  echo "=== ${name^^} ==="

  local output
  local exit_code
  output=$("${cmd[@]}" 2>&1) && exit_code=0 || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo "status: pass"
  else
    echo "status: fail"
    failed_checks+=("$name")
  fi

  echo "output: |"
  while IFS= read -r line; do
    echo "  $line"
  done <<< "$output"
  echo ""
}

# Run audit (required for all cask changes)
run_check "audit" brew audit --cask --new --online "$cask"

# Run style check with auto-fix
run_check "style" brew style --fix "$cask"

# Run livecheck (can skip for unversioned URLs)
if $skip_livecheck; then
  echo "=== LIVECHECK ==="
  echo "status: skipped"
  echo "output: |"
  echo "  Skipped (--skip-livecheck flag)"
  echo ""
else
  run_check "livecheck" brew livecheck --cask "$cask"
fi

# Summary
echo "=== SUMMARY ==="
if [[ ${#failed_checks[@]} -eq 0 ]]; then
  echo "result: pass"
  echo "failed: none"
  exit 0
else
  echo "result: fail"
  echo "failed: $(IFS=,; echo "${failed_checks[*]}")"
  exit 1
fi
