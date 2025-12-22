#!/usr/bin/env bash
set -euo pipefail

SOURCES_FILE="sources.json"
GITHUB_API_URL="https://api.github.com/repos/siderolabs/talos/releases"

# Platform mapping: nix system -> talosctl binary name
declare -A PLATFORM_MAP=(
  ["x86_64-linux"]="talosctl-linux-amd64"
  ["aarch64-linux"]="talosctl-linux-arm64"
  ["x86_64-darwin"]="talosctl-darwin-amd64"
  ["aarch64-darwin"]="talosctl-darwin-arm64"
)

get_latest_stable_version() {
  local headers=(-H "Accept: application/vnd.github+json" -H "User-Agent: talosctl-flake-updater")

  # Use GITHUB_TOKEN if available
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi

  curl -sL "${headers[@]}" "$GITHUB_API_URL" | jq -r '
    [.[] | select(.prerelease == false and .draft == false)
         | select(.tag_name | test("-(alpha|beta|rc)") | not)]
    | first | .tag_name | sub("^v"; "")
  '
}

compute_sri_hash() {
  local url="$1"
  nix store prefetch-file "$url" --json 2>/dev/null | jq -r '.hash'
}

main() {
  echo "Checking for talosctl updates..."

  local current_version
  current_version=$(jq -r '.version' "$SOURCES_FILE")
  echo "Current version: $current_version"

  local latest_version
  latest_version=$(get_latest_stable_version)

  if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
    echo "Error: Failed to get latest version"
    exit 1
  fi

  echo "Latest stable version: $latest_version"

  if [[ "$current_version" == "$latest_version" ]]; then
    echo "Already at latest version, no update needed"
    exit 0
  fi

  echo "Updating from $current_version to $latest_version..."

  # Build new sources.json
  local platforms_json="{}"

  for nix_platform in "${!PLATFORM_MAP[@]}"; do
    local binary_name="${PLATFORM_MAP[$nix_platform]}"
    local url="https://github.com/siderolabs/talos/releases/download/v${latest_version}/${binary_name}"

    echo "Fetching hash for $nix_platform..."

    local hash
    hash=$(compute_sri_hash "$url")

    if [[ -z "$hash" || "$hash" == "null" ]]; then
      echo "Error: Failed to compute hash for $nix_platform"
      exit 1
    fi

    echo "  $nix_platform: $hash"

    platforms_json=$(echo "$platforms_json" | jq \
      --arg platform "$nix_platform" \
      --arg url "$url" \
      --arg hash "$hash" \
      '. + {($platform): {"url": $url, "hash": $hash}}')
  done

  # Write new sources.json
  jq -n \
    --arg version "$latest_version" \
    --argjson platforms "$platforms_json" \
    '{"version": $version, "platforms": $platforms}' > "$SOURCES_FILE"

  echo "Successfully updated sources.json to version $latest_version"
}

main "$@"
