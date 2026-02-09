#!/usr/bin/env bash
# Download a file and calculate its SHA256 checksum
#
# Usage: download-checksum.sh <url> [filename]
#
# Arguments:
#   url       - Direct download URL
#   filename  - Optional output filename (default: extracted from URL or "download")
#
# Output (structured for parsing):
#   path: /tmp/filename.ext
#   sha256: abc123...
#   size: 12345678
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Download failed
#   3 - Checksum calculation failed

set -euo pipefail

usage() {
  echo "Usage: download-checksum.sh <url> [filename]" >&2
  exit 1
}

[[ $# -lt 1 || $# -gt 2 ]] && usage

url="$1"
filename="${2:-}"

# Extract filename from URL if not provided
if [[ -z "$filename" ]]; then
  # Try to get filename from URL path
  filename=$(basename "${url%%\?*}")  # Strip query params first
  # Fall back to generic name if empty or weird
  if [[ -z "$filename" || "$filename" == "/" ]]; then
    filename="download"
  fi
fi

output_path="/tmp/$filename"

echo "Downloading: $url" >&2
echo "Output: $output_path" >&2

# Download with progress to stderr
if ! curl -L --fail --progress-bar -o "$output_path" "$url"; then
  echo "error: Download failed" >&2
  exit 2
fi

# Calculate checksum
if ! checksum=$(shasum -a 256 "$output_path" | cut -d' ' -f1); then
  echo "error: Checksum calculation failed" >&2
  exit 3
fi

# Get file size
size=$(stat -f%z "$output_path" 2>/dev/null || stat --format=%s "$output_path" 2>/dev/null || echo "unknown")

# Output structured results (to stdout for parsing)
echo "path: $output_path"
echo "sha256: $checksum"
echo "size: $size"
