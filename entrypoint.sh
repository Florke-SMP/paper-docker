#!/bin/bash

set -e

# Supported environment variables:
# PAPER_RECOMMENDED_JVM_FLAGS: If set to false, skips fetching recommended JVM flags
# Default: true

# PAPER_JVM_FLAGS: Additional JVM flags to add to the recommended flags
# Default: (empty)

# PAPER_EULA: Must be set to "true" to accept the Minecraft EULA
# Default: false

# Default JVM options variable
RECOMMENDED_JVM_FLAGS=""
# File to read JVM flags from
JVM_FLAGS_FILE="/paper-jvm-flags.txt"

function print_welcome() {
    echo "Starting dockerized Paper (unofficial image)"
    echo "by Florke64 | https://github.com/Florke64/paper-docker"
    echo "----------------------------------------------"
    echo "Running in directory: $(pwd)"
    echo "Current user: $(whoami)"
    echo "Current date and time: $(date)"
}

function read_recommended_jvm_flags() {
    if [ -s "${JVM_FLAGS_FILE}" ]; then
        echo "Found ${JVM_FLAGS_FILE} file, loading flags..."
        RECOMMENDED_JVM_FLAGS=$(cat "${JVM_FLAGS_FILE}")
    else
        echo "No ${JVM_FLAGS_FILE} file found, proceeding without specific JVM flags."
        RECOMMENDED_JVM_FLAGS=""
    fi
}

print_welcome

if [ "$PAPER_RECOMMENDED_JVM_FLAGS" = false ]; then
    echo "The variable PAPER_RECOMMENDED_JVM_FLAGS is false."
    echo "Skipping loading recommended JVM flags."
    echo .
    echo "You can set the PAPER_JVM_FLAGS to use your own JVM flags."
else
    echo "Attempting to load recommended JVM flags."
    echo "Set the environment variable PAPER_RECOMMENDED_JVM_FLAGS to false to skip this step."

    read_recommended_jvm_flags
fi

PAPER_EULA=${PAPER_EULA:-false}
echo "eula=${PAPER_EULA}" > eula.txt

if [ "${PAPER_EULA}" != "true" ]; then
    echo "--------------------------------------"
    echo .
    echo "You may need to set PAPER_EULA=true to accept the EULA."
    echo .
    echo "--------------------------------------"
fi

java ${RECOMMENDED_JVM_FLAGS} ${PAPER_JVM_FLAGS} -jar /paper.jar nogui --plugins /plugins
