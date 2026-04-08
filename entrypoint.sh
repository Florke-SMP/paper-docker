#!/bin/bash

set -euo pipefail

# Defaults for optional environment variables
PAPER_RECOMMENDED_JVM_FLAGS=${PAPER_RECOMMENDED_JVM_FLAGS:-true}
PAPER_JVM_FLAGS=${PAPER_JVM_FLAGS:-}
PAPER_EULA=${PAPER_EULA:-false}

RECOMMENDED_JVM_FLAGS=""
JVM_FLAGS_FILE="/paper-jvm-flags.txt"

function print_welcome() {
    cat <<EOF
Starting dockerized Paper (unofficial image)
by Florke64 | https://github.com/Florke64/paper-docker
----------------------------------------------
Running in directory: $(pwd)
Current user: $(whoami) (uid=$(id -u), gid=$(id -g))
Current date/time: $(date --rfc-3339=seconds)
Hostname: $(hostname)
Uptime: $(uptime -p)
Kernel: $(uname -sr)
Disk usage (/paper):
$(df -h /paper)
Available memory:
$(free -h)
----------------------------------------------
EOF
}

function summarize_environment() {
    cat <<EOF
Environment summary:
- PAPER_EULA=${PAPER_EULA}
- PAPER_RECOMMENDED_JVM_FLAGS=${PAPER_RECOMMENDED_JVM_FLAGS}
- PAPER_JVM_FLAGS=${PAPER_JVM_FLAGS:-(none)}
- JVM flags file: ${JVM_FLAGS_FILE}
EOF
}

function ensure_directories() {
    for dir in /paper /plugins; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
        fi
    done
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
ensure_directories
summarize_environment

if [ "${PAPER_RECOMMENDED_JVM_FLAGS}" = false ]; then
    echo "The variable PAPER_RECOMMENDED_JVM_FLAGS is false."
    echo "Skipping loading recommended JVM flags."
    echo
    echo "You can set PAPER_JVM_FLAGS to use your own JVM flags."
else
    echo "Attempting to load recommended JVM flags."
    echo "Set PAPER_RECOMMENDED_JVM_FLAGS=false to skip."
    read_recommended_jvm_flags
fi

echo "eula=${PAPER_EULA}" > eula.txt

if [ "${PAPER_EULA}" != "true" ]; then
    echo "--------------------------------------"
    echo
    echo "You may need to set PAPER_EULA=true to accept the EULA."
    echo
    echo "--------------------------------------"
fi

# Ensure server.properties exists and is configured to bind to all interfaces
if [ ! -f server.properties ] || ! grep -q "server-ip=" server.properties; then
    echo "server-ip=" >> server.properties
fi

# Show network configuration for debugging
echo "Network interfaces:"
ip addr show 2>/dev/null || echo "ip command not available"
echo
echo "Listening ports:"
netstat -tlnp 2>/dev/null | grep LISTEN || echo "netstat not available or no listening ports"
echo

echo "Starting Paper server with command:"
echo "java ${RECOMMENDED_JVM_FLAGS} ${PAPER_JVM_FLAGS} -jar /paper.jar nogui --plugins /plugins"
echo

exec java ${RECOMMENDED_JVM_FLAGS} ${PAPER_JVM_FLAGS} -jar /paper.jar nogui --plugins /plugins
