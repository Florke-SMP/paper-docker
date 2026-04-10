#!/bin/bash

set -euo pipefail

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    PAPER_RECOMMENDED_JVM_FLAGS=${PAPER_RECOMMENDED_JVM_FLAGS:-true}
    PAPER_JVM_FLAGS=${PAPER_JVM_FLAGS:-}
    PAPER_EULA=${PAPER_EULA:-false}
    PAPER_RCON_PASSWORD=${PAPER_RCON_PASSWORD:-}
    PAPER_RCON_BROADCAST=${PAPER_RCON_BROADCAST:-true}

    RECOMMENDED_JVM_FLAGS=""
    JVM_FLAGS_FILE="/paper-jvm-flags.txt"
    PAPER_USER="paper"
    PAPER_UID=1500
    PAPER_GID=1500
    SERVER_PROPERTIES_FILE="server.properties"
    RCON_PORT=25575
fi

function print_welcome() {
    cat <<EOF
Starting dockerized Paper (unofficial image)
by Florke64 | https://github.com/Florke64/paper-docker
----------------------------------------------
Running in directory: $(pwd)
Current user: $(whoami) (uid=$(id -u), gid=$(id -g))
Current date/time: $(date --rfc-3339=seconds)
Hostname: $(hostname), $(uptime -p)
$(df -h /paper 2>/dev/null || echo "/paper not mounted yet")
----------------------------------------------
EOF
}

function ensure_directories() {
    for dir in /paper /plugins; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
        fi
    done
}

function write_server_property() {
    local key="$1"
    local value="$2"
    local prop_file="${SERVER_PROPERTIES_FILE:-server.properties}"
    local tmp_file
    
    touch "$prop_file"
    tmp_file=$(mktemp)
    
    # awk is preferred here over sed because sed is highly susceptible to delimiter 
    # collision and regex injection if the injected value contains special characters 
    # (like '&', '/', or '\'). awk safely treats passed variables as literal strings.
    # Use ENVIRON to fetch values so awk does not interpret escape sequences.
    AWK_KEY="$key" AWK_VAL="$value" awk '
        BEGIN { 
            # Split by the first equals sign
            FS="=" 
            # Fetch raw strings directly from the environment
            k = ENVIRON["AWK_KEY"]
            v = ENVIRON["AWK_VAL"]
        }
        $1 == k {
            if (!found) {
                # First time we see the key, print the updated key=value pair
                print k "=" v
                found = 1
            }
            # Skip the line so we strip out any subsequent duplicate keys
            next
        }
        { 
            # Print all other lines untouched
            print 
        }
        END {
            # If the entire file was read and the key was never found, append it
            if (!found) {
                print k "=" v
            }
        }
    ' "$prop_file" > "$tmp_file"
    
    # Overwrite using cat instead of mv to preserve original file permissions and inodes
    cat "$tmp_file" > "$prop_file"
    rm -f "$tmp_file"
}

function configure_rcon() {
    if [ -z "${PAPER_RCON_PASSWORD}" ]; then
        echo "RCON not enabled. To enable, set PAPER_RCON_PASSWORD environment variable."
        return
    fi

    echo "Enabling RCON (port: ${RCON_PORT}), PAPER_RCON_BROADCAST=${PAPER_RCON_BROADCAST}"
    
    touch "${SERVER_PROPERTIES_FILE}"
    write_server_property enable-rcon true
    write_server_property rcon.password "${PAPER_RCON_PASSWORD}"
    write_server_property rcon.port "${RCON_PORT}"
    write_server_property broadcast-rcon-to-ops "${PAPER_RCON_BROADCAST}"
}

function adjust_mount_permissions() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Skipping ownership adjustment (not running as root)."
        return
    fi

    echo "Ensuring ${PAPER_USER}:${PAPER_USER} owns /paper and /plugins."
    for dir in /paper /plugins; do
        if [ -d "$dir" ]; then
            chown -R ${PAPER_UID}:${PAPER_GID} "$dir" || true
            chmod 750 "$dir" || true
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

function handle_shutdown() {
    trap - TERM INT
    echo "Received SIGTERM, initiating graceful shutdown..." >&2

    if [ -n "${SERVER_PID}" ]; then
        # Send stop command directly to the coprocess stdin pipe
        echo "stop" >&"${SERVER_PROC[1]}" || true

        local timeout
        timeout=60
        while kill -0 "${SERVER_PID}" 2>/dev/null && [ "${timeout}" -gt 0 ]; do
            sleep 1
            timeout=$((timeout - 1))
        done

        if kill -0 "${SERVER_PID}" 2>/dev/null; then
            echo "Timeout reached (60s). Force killing server process (${SERVER_PID})..." >&2
            kill -9 "${SERVER_PID}" 2>/dev/null || true
        else
            echo "Server stopped gracefully." >&2
        fi
    fi

    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_welcome
    ensure_directories
    adjust_mount_permissions
    configure_rcon

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
        echo "######################################"
        echo "--------------------------------------"
        echo
        echo "You may need to set PAPER_EULA=true to accept the EULA."
        echo
        echo "--------------------------------------"
        echo "######################################"
    fi

    # bind to all interfaces
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

    JAVA_CMD=(java)
    if [ -n "${RECOMMENDED_JVM_FLAGS}" ]; then
        read -r -a RECOMMENDED_ARRAY <<<"${RECOMMENDED_JVM_FLAGS}"
        JAVA_CMD+=("${RECOMMENDED_ARRAY[@]}")
    fi
    JAVA_CMD+=(-jar /paper.jar nogui --plugins /plugins)

    # Install trap for Docker termination signals
    trap 'handle_shutdown' TERM INT

    echo "Starting Paper server with command:"
    echo "java ${RECOMMENDED_JVM_FLAGS} ${PAPER_JVM_FLAGS} -jar /paper.jar nogui --plugins /plugins"
    echo

    echo "========= >"
    echo "Server process started."
    echo "============= >"

    if [ "$(id -u)" -eq 0 ]; then
        # We are root. We MUST have runuser to drop privileges.
        if ! command -v runuser >/dev/null 2>&1; then
            echo "FATAL: Container started as root, but 'runuser' is missing. Aborting to prevent running server as root." >&2
            exit 1
        fi

        echo "User context about to switch to '${PAPER_USER}' for the server process."
        coproc SERVER_PROC {
            runuser -u "${PAPER_USER}" -- bash -c "exec ${JAVA_CMD[*]}" >&1 2>&2
        }
    else
        echo "Running natively as non-root user (uid=$(id -u))."
        coproc SERVER_PROC {
            exec "${JAVA_CMD[@]}" >&1 2>&2
        }
    fi

    SERVER_PID=$SERVER_PROC_PID

    # Wait on the background process
    # 'wait' will be interrupted by the trap when a signal is received
    wait $SERVER_PID
    exit $?
fi
