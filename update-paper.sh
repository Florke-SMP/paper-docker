#!/bin/bash

# This script will be later merged into the build script workflow action

set -e

USER_AGENT="paper-docker/1.0.0 (@florke64@mastodon.social)"

# Resolve latest Paper version and build
LATEST_VERSION=$(curl -s -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper | \
    jq -r '.versions | to_entries[0] | .value[0]')

LATEST_BUILD=$(curl -s -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper/versions/${LATEST_VERSION} | \
    jq -r '.builds[0]')

if [ "$LATEST_BUILD" != "null" ]; then
    echo "Found build $LATEST_BUILD for $LATEST_VERSION"
else
    echo "An unexpected error has occured. Please check the logs."
fi

# Fetch the download URL and SHA256 checksum for the latest build
PAPER_URL=$(curl -s -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper/versions/${LATEST_VERSION}/builds | \
    jq -r 'first(.[] | .downloads."server:default".url) // "null"')
SHA256=$(curl -sL "$PAPER_URL" | sha256sum | cut -d' ' -f1)

# Fetch recommended JVM flags for the latest version
echo "Fetching recommended JVM flags..."
JVM_FLAGS=$(curl -s -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper/versions/${LATEST_VERSION} | \
    jq -r '.version.java.flags.recommended | join(" ")')

# Check if flags were successfully retrieved
JVM_FLAGS_FILE="recommended-jvm-flags.txt"
if [ -n "$JVM_FLAGS" ]; then
    echo "Successfully retrieved flags. Saving to ${JVM_FLAGS_FILE} file."
    # Save the flags to the file, overwriting any previous content.
    echo "$JVM_FLAGS" > "${JVM_FLAGS_FILE}"
    echo "Flags saved successfully."
else
    echo "Error: Could not retrieve JVM flags for version $LATEST_VERSION."
    exit 1
fi

# Output the results
echo "Paper SHA256: $SHA256"
echo "Paper URL: $PAPER_URL"

echo "Building .buildargs file..."
echo "PAPER_URL=$PAPER_URL" > .buildargs
echo "SHA256=$SHA256" >> .buildargs
