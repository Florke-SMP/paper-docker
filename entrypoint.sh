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
    local file="${SERVER_PROPERTIES_FILE}"
    local temp
    temp=$(mktemp)
    local added=false

    if [ -f "$file" ]; then
        while IFS= read -r line || [ -n "${line}" ]; do
            if [[ "${line}" == "${key}"=* ]]; then
                if [ "$added" = false ]; then
                    printf '%s\n' "${key}=${value}" >> "$temp"
                    added=true
                fi
                continue
            fi
            printf '%s\n' "$line" >> "$temp"
        done <"$file"
    fi

    if [ "$added" = false ]; then
        printf '%s\n' "${key}=${value}" >> "$temp"
    fi

    mv "$temp" "$file"
}

function configure_rcon() {
    if [ -z "${PAPER_RCON_PASSWORD}" ]; then
        echo "RCON not enabled (set PAPER_RCON_PASSWORD to enable remote console access)."
        return
    fi

    echo "Enabling RCON access on port ${RCON_PORT}."
    touch "${SERVER_PROPERTIES_FILE}"
    write_server_property enable-rcon true
    write_server_property rcon.password "${PAPER_RCON_PASSWORD}"
    write_server_property rcon.port "${RCON_PORT}"
    write_server_property broadcast-rcon-to-ops "${PAPER_RCON_BROADCAST}"
    echo "PAPER_RCON_BROADCAST=${PAPER_RCON_BROADCAST}"
    echo "--- RCON is not encrypted; ensure only trusted clients can reach port ${RCON_PORT}."
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

  echo "Starting Paper server with command:"
  echo "java ${RECOMMENDED_JVM_FLAGS} ${PAPER_JVM_FLAGS} -jar /paper.jar nogui --plugins /plugins"
  echo

  echo "========= >"
  echo "Server process started."
  echo "============= >"

  JAVA_CMD=(java)
  if [ -n "${RECOMMENDED_JVM_FLAGS}" ]; then
      read -r -a RECOMMENDED_ARRAY <<<"${RECOMMENDED_JVM_FLAGS}"
      JAVA_CMD+=("${RECOMMENDED_ARRAY[@]}")
  fi
  JAVA_CMD+=(-jar /paper.jar nogui --plugins /plugins)

  if command -v runuser >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
      exec runuser -u ${PAPER_USER} -- "${JAVA_CMD[@]}"
  else
      exec "${JAVA_CMD[@]}"
  fi
fi
