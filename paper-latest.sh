#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

USER_AGENT=${USER_AGENT:-"paper-docker/1.0.0 (@florke64@mastodon.social)"}
API_BASE="https://fill.papermc.io/v3/projects/paper"

required_tools=(curl jq sha256sum)
for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: $tool is not installed" >&2
    exit 1
  fi
done

shell_quote() {
  printf '%q' "$1"
}

echo "Resolving latest PaperMC metadata..."
versions=$(curl -sSf -H "User-Agent: $USER_AGENT" "$API_BASE/versions")
latest_entry=$(jq -c '.versions[0]' <<<"$versions")
if [[ -z "$latest_entry" || "$latest_entry" == "null" ]]; then
  echo "error: unable to read latest version metadata" >&2
  exit 1
fi

latest_version=$(jq -r '.version.id' <<<"$latest_entry")
latest_build=$(jq -r '.builds[-1]' <<<"$latest_entry")
if [[ -z "$latest_build" || "$latest_build" == "null" ]]; then
  echo "error: no builds available for version $latest_version" >&2
  exit 1
fi

jvm_flags=$(jq -r '.version.java.flags.recommended // [] | join(" ")' <<<"$latest_entry")

echo "Fetching build details for $latest_version#$latest_build..."
build_details=$(curl -sSf -H "User-Agent: $USER_AGENT" "$API_BASE/versions/$latest_version/builds/$latest_build")
paper_url=$(jq -r '.downloads."server:default".url' <<<"$build_details")
if [[ -z "$paper_url" || "$paper_url" == "null" ]]; then
  echo "error: download URL missing for $latest_version#$latest_build" >&2
  exit 1
fi

sha256=$(curl -sL "$paper_url" | sha256sum | cut -d' ' -f1)

cat <<EOF >.buildargs
LATEST_VERSION=$(shell_quote "$latest_version")
LATEST_BUILD=$(shell_quote "$latest_build")
PAPER_URL=$(shell_quote "$paper_url")
SHA256=$(shell_quote "$sha256")
JVM_FLAGS=$(shell_quote "$jvm_flags")
EOF

echo "Metadata written to .buildargs"
echo "Paper URL: $paper_url"
echo "SHA256: $sha256"
